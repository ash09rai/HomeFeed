import Combine
import Foundation

public protocol ObserveHomeFeedSectionsUseCaseProtocol {
    func execute() -> AnyPublisher<[FeedSectionState], Never>
}

public protocol ObserveHomeFeedSkippedSectionsUseCaseProtocol {
    func execute() -> AnyPublisher<[FeedSectionState], Never>
}

public protocol ObserveHomeFeedEventsUseCaseProtocol {
    func execute() -> AnyPublisher<HomeFeedRepositoryEvent, Never>
}

public protocol RefreshHomeFeedUseCaseProtocol {
    func execute() -> AnyPublisher<Void, Never>
}

public protocol TriggerSectionBehaviourUseCaseProtocol {
    func execute(sectionID: String, action: BehaviourAction) -> (SectionMeta, BehaviourRule)?
}

public struct ObserveHomeFeedSectionsUseCase: ObserveHomeFeedSectionsUseCaseProtocol {
    private let repository: HomeFeedRepository

    public init(repository: HomeFeedRepository) {
        self.repository = repository
    }

    public func execute() -> AnyPublisher<[FeedSectionState], Never> {
        repository.sectionsPublisher
    }
}

public struct ObserveHomeFeedSkippedSectionsUseCase: ObserveHomeFeedSkippedSectionsUseCaseProtocol {
    private let repository: HomeFeedRepository

    public init(repository: HomeFeedRepository) {
        self.repository = repository
    }

    public func execute() -> AnyPublisher<[FeedSectionState], Never> {
        repository.skippedSectionsPublisher
    }
}

public struct ObserveHomeFeedEventsUseCase: ObserveHomeFeedEventsUseCaseProtocol {
    private let repository: HomeFeedRepository

    public init(repository: HomeFeedRepository) {
        self.repository = repository
    }

    public func execute() -> AnyPublisher<HomeFeedRepositoryEvent, Never> {
        repository.eventsPublisher
    }
}

public struct RefreshHomeFeedUseCase: RefreshHomeFeedUseCaseProtocol {
    private let repository: HomeFeedRepository

    public init(repository: HomeFeedRepository) {
        self.repository = repository
    }

    public func execute() -> AnyPublisher<Void, Never> {
        repository.refresh()
    }
}

public struct TriggerSectionBehaviourUseCase: TriggerSectionBehaviourUseCaseProtocol {
    private let repository: HomeFeedRepository

    public init(repository: HomeFeedRepository) {
        self.repository = repository
    }

    public func execute(sectionID: String, action: BehaviourAction) -> (SectionMeta, BehaviourRule)? {
        repository.triggerBehaviour(for: sectionID, action: action)
    }
}
