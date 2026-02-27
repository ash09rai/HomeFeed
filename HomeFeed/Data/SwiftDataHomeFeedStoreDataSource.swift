import Combine
import Foundation
#if canImport(SwiftData)
import SwiftData
#endif

#if canImport(SwiftData)
@available(iOS 17.0, *)
@Model
final class HomeFeedStateRecord {
    @Attribute(.unique) var key: String
    var sectionsBlob: Data
    var skippedSectionsBlob: Data
    var updatedAt: Date

    init(key: String, sectionsBlob: Data, skippedSectionsBlob: Data, updatedAt: Date = Date()) {
        self.key = key
        self.sectionsBlob = sectionsBlob
        self.skippedSectionsBlob = skippedSectionsBlob
        self.updatedAt = updatedAt
    }
}

@available(iOS 17.0, *)
public final class SwiftDataHomeFeedStoreDataSource: HomeFeedStoreDataSource {
    private static let recordKey = "home_feed_state"

    private let container: ModelContainer
    private let writeQueue = DispatchQueue(label: "homefeed.swiftdata.write")
    private let sectionsSubject: CurrentValueSubject<[FeedSectionState], Never>
    private let skippedSectionsSubject: CurrentValueSubject<[FeedSectionState], Never>

    public init(container: ModelContainer? = nil) throws {
        let resolvedContainer = try container ?? ModelContainer(for: HomeFeedStateRecord.self)
        self.container = resolvedContainer

        let snapshot = Self.loadSnapshot(from: resolvedContainer)
        self.sectionsSubject = CurrentValueSubject(snapshot.sections)
        self.skippedSectionsSubject = CurrentValueSubject(snapshot.skipped)
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
        persist(sections: sections, skippedSections: skippedSections)
    }

    public func replaceSections(_ sections: [FeedSectionState]) {
        sectionsSubject.send(sections)
        persist(sections: sections, skippedSections: skippedSectionsSubject.value)
    }

    private func persist(sections: [FeedSectionState], skippedSections: [FeedSectionState]) {
        guard
            let sectionsData = try? JSONEncoder().encode(sections),
            let skippedData = try? JSONEncoder().encode(skippedSections)
        else {
            return
        }

        let container = self.container
        writeQueue.async {
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<HomeFeedStateRecord>()
            let existing = (try? context.fetch(descriptor))?.first(where: { $0.key == Self.recordKey })

            if let existing {
                existing.sectionsBlob = sectionsData
                existing.skippedSectionsBlob = skippedData
                existing.updatedAt = Date()
            } else {
                let record = HomeFeedStateRecord(
                    key: Self.recordKey,
                    sectionsBlob: sectionsData,
                    skippedSectionsBlob: skippedData
                )
                context.insert(record)
            }

            try? context.save()
        }
    }

    private static func loadSnapshot(from container: ModelContainer) -> (sections: [FeedSectionState], skipped: [FeedSectionState]) {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<HomeFeedStateRecord>()
        guard
            let record = (try? context.fetch(descriptor))?.first(where: { $0.key == recordKey }),
            let sections = try? JSONDecoder().decode([FeedSectionState].self, from: record.sectionsBlob),
            let skipped = try? JSONDecoder().decode([FeedSectionState].self, from: record.skippedSectionsBlob)
        else {
            return ([], [])
        }

        return (sections, skipped)
    }
}
#endif
