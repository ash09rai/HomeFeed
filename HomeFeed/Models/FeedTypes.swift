import Foundation

private enum type_normalizer {
    static func token(_ value: String) -> String {
        value
            .uppercased()
            .replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)
    }
}

public struct ContentType: RawRepresentable, Hashable, Codable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = Self.canonicalRawValue(for: rawValue)
    }

    public init(_ value: String) {
        self.init(rawValue: value)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(rawValue: try container.decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    private static func canonicalRawValue(for value: String) -> String {
        switch type_normalizer.token(value) {
        case "DOCUMENT":
            return "DOCUMENT"
        case "ONDEMANDWEBINAR", "WEBINAR":
            return "WEBINAR"
        case "UPCOMINGWEBINAR", "UPCOMING":
            return "UPCOMING_WEBINAR"
        case "VIDEO":
            return "VIDEO"
        case "PODCAST", "AUDIO":
            return "PODCAST"
        case "INQUIRY", "ENQUIRY":
            return "INQUIRY"
        case "CONFERENCE":
            return "CONFERENCE"
        default:
            return value.uppercased()
        }
    }

    public static let document = ContentType(rawValue: "DOCUMENT")
    public static let onDemandWebinar = ContentType(rawValue: "WEBINAR")
    public static let upcomingWebinar = ContentType(rawValue: "UPCOMING_WEBINAR")
    public static let video = ContentType(rawValue: "VIDEO")
    public static let podcast = ContentType(rawValue: "PODCAST")
    public static let inquiry = ContentType(rawValue: "INQUIRY")
    public static let conference = ContentType(rawValue: "CONFERENCE")

    public static let webinar = onDemandWebinar
    public static let audio = podcast
}

public struct CardType: RawRepresentable, Hashable, Codable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = Self.canonicalRawValue(for: rawValue)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(rawValue: try container.decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    private static func canonicalRawValue(for value: String) -> String {
        switch type_normalizer.token(value) {
        case "COMPACTHEIGHT", "COMPACTHEIGHTCARD":
            return "COMPACT_HEIGHT"
        case "COMPACTWIDTH", "COMPACTWIDTHCARD":
            return "COMPACT_WIDTH"
        case "TOPTHUMBNAIL", "TOPTHUMBNAILCARD", "BIGCARD":
            return "TOP_THUMBNAIL"
        case "INSIGHT", "INSIGHTCARD", "STANDARDCARD":
            return "INSIGHT"
        default:
            return value.uppercased()
        }
    }

    public static let compactHeight = CardType(rawValue: "COMPACT_HEIGHT")
    public static let compactWidth = CardType(rawValue: "COMPACT_WIDTH")
    public static let topThumbnail = CardType(rawValue: "TOP_THUMBNAIL")
    public static let insight = CardType(rawValue: "INSIGHT")

    public static let compactHeightCard = compactHeight
    public static let compactWidthCard = compactWidth
    public static let bigCard = topThumbnail
    public static let standardCard = insight
}

public struct LayoutType: RawRepresentable, Hashable, Codable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue.uppercased()
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(rawValue: try container.decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public static let horizontalList = LayoutType(rawValue: "HORIZONTAL_LIST")
    public static let verticalList = LayoutType(rawValue: "VERTICAL_LIST")
    public static let grid = LayoutType(rawValue: "GRID")
}

public struct ScrollDirection: RawRepresentable, Hashable, Codable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue.uppercased()
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(rawValue: try container.decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public static let horizontal = ScrollDirection(rawValue: "HORIZONTAL")
    public static let vertical = ScrollDirection(rawValue: "VERTICAL")
}

public struct BehaviourAction: RawRepresentable, Hashable, Codable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue.uppercased()
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(rawValue: try container.decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public static let viewed = BehaviourAction(rawValue: "VIEWED")
    public static let tapped = BehaviourAction(rawValue: "TAPPED")
}
