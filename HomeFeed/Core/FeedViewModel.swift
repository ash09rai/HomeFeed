import Combine
import Foundation

public struct HomeFeedCallbacks {
    public var onConfigurationValidationFailed: ((ConfigurationValidationError) -> Void)?
    public var onSectionSkipped: ((SectionMeta, SectionSkipReason) -> Void)?
    public var onSectionPartiallySupported: ((SectionMeta, [ContentType]) -> Void)?
    public var onBehaviourTriggered: ((SectionMeta, BehaviourRule) -> Void)?
    public var onHomeFeedFailed: ((HomeFeedError) -> Void)?

    public init(
        onConfigurationValidationFailed: ((ConfigurationValidationError) -> Void)? = nil,
        onSectionSkipped: ((SectionMeta, SectionSkipReason) -> Void)? = nil,
        onSectionPartiallySupported: ((SectionMeta, [ContentType]) -> Void)? = nil,
        onBehaviourTriggered: ((SectionMeta, BehaviourRule) -> Void)? = nil,
        onHomeFeedFailed: ((HomeFeedError) -> Void)? = nil
    ) {
        self.onConfigurationValidationFailed = onConfigurationValidationFailed
        self.onSectionSkipped = onSectionSkipped
        self.onSectionPartiallySupported = onSectionPartiallySupported
        self.onBehaviourTriggered = onBehaviourTriggered
        self.onHomeFeedFailed = onHomeFeedFailed
    }
}

public final class FeedViewModel: ObservableObject {
    @Published public private(set) var sections: [FeedSectionState] = []
    @Published public private(set) var skippedSections: [FeedSectionState] = []
    @Published public private(set) var isLoading: Bool = false

    private let observeSectionsUseCase: ObserveHomeFeedSectionsUseCaseProtocol
    private let observeSkippedSectionsUseCase: ObserveHomeFeedSkippedSectionsUseCaseProtocol
    private let observeEventsUseCase: ObserveHomeFeedEventsUseCaseProtocol
    private let refreshHomeFeedUseCase: RefreshHomeFeedUseCaseProtocol
    private let triggerSectionBehaviourUseCase: TriggerSectionBehaviourUseCaseProtocol

    private var callbacks: HomeFeedCallbacks
    private var hasLoaded = false
    private var cancellables: Set<AnyCancellable> = []
    private var refreshCancellable: AnyCancellable?

    public init(
        observeSectionsUseCase: ObserveHomeFeedSectionsUseCaseProtocol,
        observeSkippedSectionsUseCase: ObserveHomeFeedSkippedSectionsUseCaseProtocol,
        observeEventsUseCase: ObserveHomeFeedEventsUseCaseProtocol,
        refreshHomeFeedUseCase: RefreshHomeFeedUseCaseProtocol,
        triggerSectionBehaviourUseCase: TriggerSectionBehaviourUseCaseProtocol,
        callbacks: HomeFeedCallbacks = HomeFeedCallbacks()
    ) {
        self.observeSectionsUseCase = observeSectionsUseCase
        self.observeSkippedSectionsUseCase = observeSkippedSectionsUseCase
        self.observeEventsUseCase = observeEventsUseCase
        self.refreshHomeFeedUseCase = refreshHomeFeedUseCase
        self.triggerSectionBehaviourUseCase = triggerSectionBehaviourUseCase
        self.callbacks = callbacks

        bindUseCases()
    }

    public convenience init(
        networkingProvider: HomeFeedNetworkingProvider,
        capabilities: HomeFeedCapabilities,
        chunkSize: Int = 2,
        validator: HomeFeedCapabilityValidator = HomeFeedCapabilityValidator(),
        callbacks: HomeFeedCallbacks = HomeFeedCallbacks(),
        persistenceMode: HomeFeedPersistenceMode = .automatic,
        runtime: HomeFeedRuntime = LiveHomeFeedRuntime()
    ) {
        let remoteDataSource = NetworkingHomeFeedRemoteDataSource(provider: networkingProvider)
        let storeDataSource = HomeFeedRepositoryFactory.makeStoreDataSource(
            persistenceMode: persistenceMode,
            runtime: runtime
        )
        let repository = HomeFeedRepositoryImpl(
            remoteDataSource: remoteDataSource,
            storeDataSource: storeDataSource,
            capabilities: capabilities,
            validator: validator,
            chunkSize: chunkSize
        )

        self.init(
            observeSectionsUseCase: ObserveHomeFeedSectionsUseCase(repository: repository),
            observeSkippedSectionsUseCase: ObserveHomeFeedSkippedSectionsUseCase(repository: repository),
            observeEventsUseCase: ObserveHomeFeedEventsUseCase(repository: repository),
            refreshHomeFeedUseCase: RefreshHomeFeedUseCase(repository: repository),
            triggerSectionBehaviourUseCase: TriggerSectionBehaviourUseCase(repository: repository),
            callbacks: callbacks
        )
    }

    public func updateCallbacks(_ callbacks: HomeFeedCallbacks) {
        self.callbacks = callbacks
    }

    public func loadIfNeeded() {
        guard !hasLoaded else {
            return
        }
        load()
    }

    public func load() {
        hasLoaded = true
        isLoading = true

        refreshCancellable?.cancel()
        refreshCancellable = refreshHomeFeedUseCase
            .execute()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isLoading = false
            }
    }

    public func triggerBehaviour(for sectionID: String, action: BehaviourAction) {
        guard let result = triggerSectionBehaviourUseCase.execute(sectionID: sectionID, action: action) else {
            return
        }

        callbacks.onBehaviourTriggered?(result.0, result.1)
    }

    private func bindUseCases() {
        observeSectionsUseCase
            .execute()
            .sink { [weak self] sections in
                guard let self else {
                    return
                }
                if Thread.isMainThread {
                    self.sections = sections
                } else {
                    DispatchQueue.main.async { [weak self] in
                        self?.sections = sections
                    }
                }
            }
            .store(in: &cancellables)

        observeSkippedSectionsUseCase
            .execute()
            .sink { [weak self] sections in
                guard let self else {
                    return
                }
                if Thread.isMainThread {
                    self.skippedSections = sections
                } else {
                    DispatchQueue.main.async { [weak self] in
                        self?.skippedSections = sections
                    }
                }
            }
            .store(in: &cancellables)

        observeEventsUseCase
            .execute()
            .sink { [weak self] event in
                guard let self else {
                    return
                }
                if Thread.isMainThread {
                    self.handle(event: event)
                } else {
                    DispatchQueue.main.async { [weak self] in
                        self?.handle(event: event)
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func handle(event: HomeFeedRepositoryEvent) {
        switch event {
        case let .configurationValidationFailed(error):
            callbacks.onConfigurationValidationFailed?(error)
        case let .sectionSkipped(section, reason):
            callbacks.onSectionSkipped?(section, reason)
        case let .sectionPartiallySupported(section, unsupported):
            callbacks.onSectionPartiallySupported?(section, unsupported)
        case let .homeFeedFailed(error):
            callbacks.onHomeFeedFailed?(error)
        }
    }
}
