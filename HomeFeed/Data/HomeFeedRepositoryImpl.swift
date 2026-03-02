import Combine
import Foundation

public final class HomeFeedRepositoryImpl: HomeFeedRepository {
    public var sectionsPublisher: AnyPublisher<[FeedSectionState], Never> {
        storeDataSource.sectionsPublisher
    }

    public var skippedSectionsPublisher: AnyPublisher<[FeedSectionState], Never> {
        storeDataSource.skippedSectionsPublisher
    }

    public var eventsPublisher: AnyPublisher<HomeFeedRepositoryEvent, Never> {
        eventsSubject.eraseToAnyPublisher()
    }

    private let remoteDataSource: HomeFeedRemoteDataSource
    private let storeDataSource: HomeFeedStoreDataSource
    private let capabilities: HomeFeedCapabilities
    private let validator: HomeFeedCapabilityValidator
    private let chunkSize: Int

    private let eventsSubject = PassthroughSubject<HomeFeedRepositoryEvent, Never>()
    private var refreshCancellables: Set<AnyCancellable> = []
    private var workingSections: [FeedSectionState] = []

    public init(
        remoteDataSource: HomeFeedRemoteDataSource,
        storeDataSource: HomeFeedStoreDataSource,
        capabilities: HomeFeedCapabilities,
        validator: HomeFeedCapabilityValidator = HomeFeedCapabilityValidator(),
        chunkSize: Int = 2
    ) {
        self.remoteDataSource = remoteDataSource
        self.storeDataSource = storeDataSource
        self.capabilities = capabilities
        self.validator = validator
        self.chunkSize = max(1, chunkSize)
    }

    public func refresh() -> AnyPublisher<Void, Never> {
        Future { [weak self] promise in
            guard let self else {
                promise(.success(()))
                return
            }

            self.refreshInternal {
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }

    @discardableResult
    public func triggerBehaviour(for sectionID: String, action: BehaviourAction) -> (SectionMeta, BehaviourRule)? {
        var sections = storeDataSource.currentSections()
        guard let index = sections.firstIndex(where: { $0.id == sectionID }) else {
            return nil
        }

        guard let behaviour = sections[index].meta.behaviour, behaviour.action == action else {
            return nil
        }

        var meta = sections[index].meta
        if behaviour.parameter.lowercased() == "rank", let rank = Int(behaviour.updatedValue) {
            meta.rank = rank
        }

        sections[index].meta = meta
        sections.sort { lhs, rhs in
            if lhs.meta.rank == rhs.meta.rank {
                return lhs.meta.originalOrder < rhs.meta.originalOrder
            }
            return lhs.meta.rank < rhs.meta.rank
        }

        storeDataSource.replaceSections(sections)
        return (meta, behaviour)
    }

    private func refreshInternal(completion: @escaping () -> Void) {
        refreshCancellables.removeAll()

        remoteDataSource
            .fetchConfiguration()
            .tryMap { [validator, capabilities] config in
                try validator.validate(config: config, capabilities: capabilities)
            }
            .sink { [weak self] result in
                guard let self else {
                    return
                }

                if case let .failure(error) = result {
                    if let validationError = error as? ConfigurationValidationError {
                        self.eventsSubject.send(.configurationValidationFailed(validationError))
                        self.eventsSubject.send(.homeFeedFailed(.configurationValidationFailed(validationError)))
                    } else {
                        self.eventsSubject.send(.homeFeedFailed(.networking(error.localizedDescription)))
                    }
                    completion()
                }
            } receiveValue: { [weak self] validationResult in
                self?.handleValidatedConfiguration(validationResult, completion: completion)
            }
            .store(in: &refreshCancellables)
    }

    private func handleValidatedConfiguration(
        _ result: HomeFeedValidationResult,
        completion: @escaping () -> Void
    ) {
        let existingStatesByID = Dictionary(
            uniqueKeysWithValues: storeDataSource.currentSections().map { ($0.id, $0.state) }
        )

        for partial in result.partiallySupportedSections {
            eventsSubject.send(.sectionPartiallySupported(partial.0, partial.1))
        }

        let skippedStates = result.skippedSections.map { section, reason -> FeedSectionState in
            eventsSubject.send(.sectionSkipped(section, reason))
            return FeedSectionState(meta: section, state: .skipped(reason))
        }

        if result.validSections.isEmpty {
            storeDataSource.replace(sections: [], skippedSections: skippedStates)
            eventsSubject.send(.homeFeedFailed(.noRenderableSections))
            completion()
            return
        }

        workingSections = result.validSections.map { section in
            FeedSectionState(
                meta: section,
                state: resolvedInitialState(for: section.id, existingStatesByID: existingStatesByID)
            )
        }
        storeDataSource.replace(sections: workingSections, skippedSections: skippedStates)
        executeChunk(from: 0, completion: completion)
    }

    private func executeChunk(from startIndex: Int, completion: @escaping () -> Void) {
        guard startIndex < workingSections.count else {
            let allFailed = !workingSections.isEmpty && workingSections.allSatisfy {
                if case .failed = $0.state {
                    return true
                }
                return false
            }
            if allFailed {
                eventsSubject.send(.homeFeedFailed(.allSectionsFailed))
            }
            completion()
            return
        }

        let endIndex = min(startIndex + chunkSize, workingSections.count)
        let chunk = Array(workingSections[startIndex..<endIndex])
        for section in chunk {
            setLoadingStateIfNeeded(for: section.id)
        }
        storeDataSource.replaceSections(workingSections)

        let publishers = chunk.map { fetchSection($0.meta) }

        Publishers.MergeMany(publishers)
            .collect()
            .sink { [weak self] results in
                guard let self else {
                    return
                }

                for result in results {
                    self.applyFetchedState(result.state, for: result.sectionID)
                    if case let .skipped(reason) = result.state,
                       let section = self.workingSections.first(where: { $0.id == result.sectionID })?.meta {
                        self.eventsSubject.send(.sectionSkipped(section, reason))
                    }
                }

                self.storeDataSource.replaceSections(self.workingSections)
                self.executeChunk(from: endIndex, completion: completion)
            }
            .store(in: &refreshCancellables)
    }

    private func fetchSection(_ section: SectionMeta) -> AnyPublisher<SectionFetchResult, Never> {
        remoteDataSource
            .fetchSectionData(for: section)
            .map { [weak self] data -> SectionFetchResult in
                guard let self else {
                    return SectionFetchResult(sectionID: section.id, state: .loaded(data))
                }

                let filteredItems = data.items.filter {
                    self.capabilities.supportedContentTypes.contains($0.contentType)
                }

                if filteredItems.count < data.items.count {
                    let unsupported = data.items
                        .map(\.contentType)
                        .filter { !self.capabilities.supportedContentTypes.contains($0) }
                    self.eventsSubject.send(.sectionPartiallySupported(section, unsupported))
                }

                if filteredItems.isEmpty {
                    return SectionFetchResult(sectionID: section.id, state: .skipped(.unsupportedContentType))
                }

                return SectionFetchResult(
                    sectionID: section.id,
                    state: .loaded(SectionData(items: filteredItems))
                )
            }
            .catch { error in
                Just(SectionFetchResult(sectionID: section.id, state: .failed(error.localizedDescription)))
            }
            .eraseToAnyPublisher()
    }

    private func setState(for sectionID: String, state: SectionState) {
        guard let index = workingSections.firstIndex(where: { $0.id == sectionID }) else {
            return
        }
        workingSections[index].state = state
    }

    private func resolvedInitialState(
        for sectionID: String,
        existingStatesByID: [String: SectionState]
    ) -> SectionState {
        guard let existingState = existingStatesByID[sectionID] else {
            return .idle
        }

        switch existingState {
        case .idle, .loading:
            return .idle
        case .loaded, .failed, .skipped:
            return existingState
        }
    }

    private func setLoadingStateIfNeeded(for sectionID: String) {
        guard let index = workingSections.firstIndex(where: { $0.id == sectionID }) else {
            return
        }

        switch workingSections[index].state {
        case .loaded, .failed:
            return
        case .idle, .loading, .skipped:
            workingSections[index].state = .loading
        }
    }

    private func applyFetchedState(_ fetchedState: SectionState, for sectionID: String) {
        guard let index = workingSections.firstIndex(where: { $0.id == sectionID }) else {
            return
        }

        if case .loaded = workingSections[index].state,
           case .failed = fetchedState {
            return
        }

        workingSections[index].state = fetchedState
    }
}

private struct SectionFetchResult {
    let sectionID: String
    let state: SectionState
}
