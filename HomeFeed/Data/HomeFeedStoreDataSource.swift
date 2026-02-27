import Combine
import Foundation

public protocol HomeFeedStoreDataSource {
    var sectionsPublisher: AnyPublisher<[FeedSectionState], Never> { get }
    var skippedSectionsPublisher: AnyPublisher<[FeedSectionState], Never> { get }

    func currentSections() -> [FeedSectionState]
    func currentSkippedSections() -> [FeedSectionState]
    func replace(sections: [FeedSectionState], skippedSections: [FeedSectionState])
    func replaceSections(_ sections: [FeedSectionState])
}

public final class InMemoryHomeFeedStoreDataSource: HomeFeedStoreDataSource {
    private let sectionsSubject: CurrentValueSubject<[FeedSectionState], Never>
    private let skippedSectionsSubject: CurrentValueSubject<[FeedSectionState], Never>

    public init(
        initialSections: [FeedSectionState] = [],
        initialSkippedSections: [FeedSectionState] = []
    ) {
        self.sectionsSubject = CurrentValueSubject(initialSections)
        self.skippedSectionsSubject = CurrentValueSubject(initialSkippedSections)
    }

    public var sectionsPublisher: AnyPublisher<[FeedSectionState], Never> {
        sectionsSubject.eraseToAnyPublisher()
    }

    public var skippedSectionsPublisher: AnyPublisher<[FeedSectionState], Never> {
        skippedSectionsSubject.eraseToAnyPublisher()
    }

    public func currentSections() -> [FeedSectionState] {
        sectionsSubject.value
    }

    public func currentSkippedSections() -> [FeedSectionState] {
        skippedSectionsSubject.value
    }

    public func replace(sections: [FeedSectionState], skippedSections: [FeedSectionState]) {
        sectionsSubject.send(sections)
        skippedSectionsSubject.send(skippedSections)
    }

    public func replaceSections(_ sections: [FeedSectionState]) {
        sectionsSubject.send(sections)
    }
}
