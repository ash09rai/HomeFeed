import Foundation

public enum HomeFeedSnapshotBuilder {
    public static func snapshot(
        sections: [FeedSectionState],
        skippedSections: [FeedSectionState],
        isLoading: Bool
    ) -> String {
        var lines: [String] = ["isLoading=\(isLoading)"]

        for section in sections {
            lines.append("section:\(section.meta.sectionType):rank=\(section.meta.rank):state=\(stateDescription(section.state))")

            if case let .loaded(data) = section.state {
                let cards = data.items.map { "\($0.id):\($0.contentType.rawValue)" }.joined(separator: ",")
                lines.append("cards:\(cards)")
            }
        }

        for section in skippedSections {
            lines.append("skipped:\(section.meta.sectionType):\(stateDescription(section.state))")
        }

        return lines.joined(separator: "\n")
    }

    private static func stateDescription(_ state: SectionState) -> String {
        switch state {
        case .idle:
            return "idle"
        case .loading:
            return "loading"
        case .loaded:
            return "loaded"
        case let .failed(message):
            return "failed(\(message))"
        case let .skipped(reason):
            return "skipped(\(reason.rawValue))"
        }
    }
}
