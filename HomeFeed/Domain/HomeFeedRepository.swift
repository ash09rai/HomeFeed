import Combine
import Foundation

public enum HomeFeedRepositoryEvent {
    case configurationValidationFailed(ConfigurationValidationError)
    case sectionSkipped(SectionMeta, SectionSkipReason)
    case sectionPartiallySupported(SectionMeta, [ContentType])
    case homeFeedFailed(HomeFeedError)
}

public protocol HomeFeedRepository {
    var sectionsPublisher: AnyPublisher<[FeedSectionState], Never> { get }
    var skippedSectionsPublisher: AnyPublisher<[FeedSectionState], Never> { get }
    var eventsPublisher: AnyPublisher<HomeFeedRepositoryEvent, Never> { get }

    func refresh() -> AnyPublisher<Void, Never>
    func triggerBehaviour(for sectionID: String, action: BehaviourAction) -> (SectionMeta, BehaviourRule)?
}
