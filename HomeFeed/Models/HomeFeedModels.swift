import Foundation

public struct HomeConfig: Equatable, Sendable, Codable {
    public var sections: [SectionMeta]

    public init(sections: [SectionMeta]) {
        self.sections = sections
    }
}

public struct SectionHeaderMeta: Equatable, Sendable, Codable {
    public var title: String?
    public var subtitle: String?
    public var titleColorHex: String?
    public var subtitleColorHex: String?

    public init(
        title: String? = nil,
        subtitle: String? = nil,
        titleColorHex: String? = nil,
        subtitleColorHex: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.titleColorHex = titleColorHex
        self.subtitleColorHex = subtitleColorHex
    }
}

public struct SectionThemeMeta: Equatable, Sendable, Codable {
    public var backgroundImageURL: String?
    public var primaryColorHex: String?
    public var secondaryColorHex: String?

    public init(
        backgroundImageURL: String? = nil,
        primaryColorHex: String? = nil,
        secondaryColorHex: String? = nil
    ) {
        self.backgroundImageURL = backgroundImageURL
        self.primaryColorHex = primaryColorHex
        self.secondaryColorHex = secondaryColorHex
    }
}

public struct SectionCtaMeta: Equatable, Sendable, Codable {
    public var actionType: String?
    public var actionName: String?
    public var text: String?
    public var position: String?

    public init(
        actionType: String? = nil,
        actionName: String? = nil,
        text: String? = nil,
        position: String? = nil
    ) {
        self.actionType = actionType
        self.actionName = actionName
        self.text = text
        self.position = position
    }

    public var trimmedText: String? {
        guard let text = text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return nil
        }
        return text
    }
}

public struct SectionMeta: Identifiable, Equatable, Sendable, Codable {
    public let id: String
    public let originalOrder: Int
    public var rank: Int
    public var sectionType: String
    public var endpoint: String?
    public var header: SectionHeaderMeta?
    public var supportedContents: [ContentType]
    public var theme: SectionThemeMeta?
    public var analytics: String?
    public var showSection: Bool
    public var groupCount: Int?
    public var cardCount: Int?
    public var sectionHeaderCta: SectionCtaMeta?
    public var footerCta: SectionCtaMeta?
    public var contentHeaderCta: SectionCtaMeta?
    public var contentFooterCta: SectionCtaMeta?
    public var sectionStyle: String?
    public var placement: String?
    public var containers: [ContainerMeta]
    public var behaviour: BehaviourRule?
    public var declaredParameters: Set<String>
    public var unknownParameters: Set<String>

    public init(
        id: String,
        originalOrder: Int,
        rank: Int,
        sectionType: String,
        endpoint: String?,
        header: SectionHeaderMeta? = nil,
        supportedContents: [ContentType],
        theme: SectionThemeMeta? = nil,
        analytics: String? = nil,
        showSection: Bool,
        groupCount: Int?,
        cardCount: Int?,
        sectionHeaderCta: SectionCtaMeta? = nil,
        footerCta: SectionCtaMeta? = nil,
        contentHeaderCta: SectionCtaMeta? = nil,
        contentFooterCta: SectionCtaMeta? = nil,
        sectionStyle: String? = nil,
        placement: String? = nil,
        containers: [ContainerMeta],
        behaviour: BehaviourRule?,
        declaredParameters: Set<String>,
        unknownParameters: Set<String>
    ) {
        self.id = id
        self.originalOrder = originalOrder
        self.rank = rank
        self.sectionType = sectionType
        self.endpoint = endpoint
        self.header = header
        self.supportedContents = supportedContents
        self.theme = theme
        self.analytics = analytics
        self.showSection = showSection
        self.groupCount = groupCount
        self.cardCount = cardCount
        self.sectionHeaderCta = sectionHeaderCta
        self.footerCta = footerCta
        self.contentHeaderCta = contentHeaderCta
        self.contentFooterCta = contentFooterCta
        self.sectionStyle = sectionStyle
        self.placement = placement
        self.containers = containers
        self.behaviour = behaviour
        self.declaredParameters = declaredParameters
        self.unknownParameters = unknownParameters
    }

    public var displayTitle: String {
        if let title = header?.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
            return title
        }
        return sectionType.replacingOccurrences(of: "_", with: " ").capitalized
    }

    public var displaySubtitle: String? {
        guard let subtitle = header?.subtitle?.trimmingCharacters(in: .whitespacesAndNewlines), !subtitle.isEmpty else {
            return nil
        }
        return subtitle
    }

    public var preferredFooterCta: SectionCtaMeta? {
        if footerCta?.trimmedText != nil {
            return footerCta
        }
        if contentFooterCta?.trimmedText != nil {
            return contentFooterCta
        }
        return nil
    }
}

public struct ContainerMeta: Equatable, Sendable, Codable {
    public var layout: LayoutType
    public var cardType: CardType
    public var scrollDirection: ScrollDirection
    public var showImage: Bool
    public var cardCount: Int?
    public var imagePaginationEnabled: Bool

    public init(
        layout: LayoutType,
        cardType: CardType,
        scrollDirection: ScrollDirection,
        showImage: Bool,
        cardCount: Int?,
        imagePaginationEnabled: Bool
    ) {
        self.layout = layout
        self.cardType = cardType
        self.scrollDirection = scrollDirection
        self.showImage = showImage
        self.cardCount = cardCount
        self.imagePaginationEnabled = imagePaginationEnabled
    }
}

public struct BehaviourRule: Equatable, Sendable, Codable {
    public let parameter: String
    public let updatedValue: String
    public let action: BehaviourAction

    public init(parameter: String, updatedValue: String, action: BehaviourAction) {
        self.parameter = parameter
        self.updatedValue = updatedValue
        self.action = action
    }
}

public struct FeedItemAction: Equatable, Sendable, Codable {
    public var title: String
    public var url: String?

    public init(title: String, url: String? = nil) {
        self.title = title
        self.url = url
    }
}

public struct FeedItemMedia: Equatable, Sendable, Codable {
    public var imageURL: String?
    public var imageURLs: [String]?
    public var showImage: Bool?
    public var multipleImageSupport: Bool?

    public init(
        imageURL: String? = nil,
        imageURLs: [String]? = nil,
        showImage: Bool? = nil,
        multipleImageSupport: Bool? = nil
    ) {
        self.imageURL = imageURL
        self.imageURLs = imageURLs
        self.showImage = showImage
        self.multipleImageSupport = multipleImageSupport
    }
}

public struct FeedItemSchedule: Equatable, Sendable, Codable {
    public var publishedDate: String?
    public var eventDate: String?
    public var eventStartDate: String?
    public var eventEndDate: String?
    public var eventTime: String?
    public var eventLocation: String?
    public var displayTimeZone: String?

    public init(
        publishedDate: String? = nil,
        eventDate: String? = nil,
        eventStartDate: String? = nil,
        eventEndDate: String? = nil,
        eventTime: String? = nil,
        eventLocation: String? = nil,
        displayTimeZone: String? = nil
    ) {
        self.publishedDate = publishedDate
        self.eventDate = eventDate
        self.eventStartDate = eventStartDate
        self.eventEndDate = eventEndDate
        self.eventTime = eventTime
        self.eventLocation = eventLocation
        self.displayTimeZone = displayTimeZone
    }
}

public struct FeedItemBehaviour: Equatable, Sendable, Codable {
    public var summary: String?
    public var media: FeedItemMedia
    public var schedule: FeedItemSchedule
    public var statusText: String?
    public var isRegistered: Bool?
    public var primaryAction: FeedItemAction?
    public var secondaryAction: FeedItemAction?

    public init(
        summary: String? = nil,
        media: FeedItemMedia = FeedItemMedia(),
        schedule: FeedItemSchedule = FeedItemSchedule(),
        statusText: String? = nil,
        isRegistered: Bool? = nil,
        primaryAction: FeedItemAction? = nil,
        secondaryAction: FeedItemAction? = nil
    ) {
        self.summary = summary
        self.media = media
        self.schedule = schedule
        self.statusText = statusText
        self.isRegistered = isRegistered
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
    }
}

public struct FeedItem: Identifiable, Equatable, Sendable, Codable {
    public let id: String
    public let contentType: ContentType
    public let title: String
    public var skimmed: Bool
    public var listened: Bool
    public var saved: Bool
    public var behaviour: FeedItemBehaviour

    public init(
        id: String,
        contentType: ContentType,
        title: String,
        skimmed: Bool = false,
        listened: Bool = false,
        saved: Bool = false,
        behaviour: FeedItemBehaviour = FeedItemBehaviour()
    ) {
        self.id = id
        self.contentType = contentType
        self.title = title
        self.skimmed = skimmed
        self.listened = listened
        self.saved = saved
        self.behaviour = behaviour
    }
    
    public var shouldShowImage: Bool {
        showImage && !imageURLs.isEmpty
    }

    public var summary: String? {
        behaviour.summary
    }

    public var imageURL: String? {
        behaviour.media.imageURL
    }

    public var imageURLs: [String] {
        let candidates = (behaviour.media.imageURLs ?? []).compactMap { value -> String? in
            let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return normalized.isEmpty ? nil : normalized
        }

        if !candidates.isEmpty {
            return candidates
        }

        guard let imageURL else {
            return []
        }

        let normalized = imageURL.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? [] : [normalized]
    }

    public var showImage: Bool {
        behaviour.media.showImage ?? (imageURL != nil)
    }

    public var multipleImageSupport: Bool {
        behaviour.media.multipleImageSupport ?? false
    }

    public var publishedDate: String? {
        behaviour.schedule.publishedDate
    }

    public var eventDate: String? {
        behaviour.schedule.eventDate
    }

    public var eventStartDate: String? {
        behaviour.schedule.eventStartDate
    }

    public var eventEndDate: String? {
        behaviour.schedule.eventEndDate
    }

    public var eventTime: String? {
        behaviour.schedule.eventTime
    }

    public var eventLocation: String? {
        behaviour.schedule.eventLocation
    }

    public var displayTimeZone: String? {
        behaviour.schedule.displayTimeZone
    }

    public var statusText: String? {
        behaviour.statusText
    }

    public var isRegistered: Bool {
        behaviour.isRegistered ?? false
    }

    public var primaryAction: FeedItemAction? {
        behaviour.primaryAction
    }

    public var secondaryAction: FeedItemAction? {
        behaviour.secondaryAction
    }

    public var primaryMetaLine: String? {
        if let publishedDate, !publishedDate.isEmpty {
            return publishedDate
        }
        if let eventDate, !eventDate.isEmpty, let eventTime, !eventTime.isEmpty {
            return "\(eventDate) | \(eventTime)"
        }
        if let eventDate, !eventDate.isEmpty {
            return eventDate
        }
        if let eventStartDate, !eventStartDate.isEmpty, let eventEndDate, !eventEndDate.isEmpty, eventEndDate != eventStartDate {
            return "\(eventStartDate) - \(eventEndDate)"
        }
        if let eventStartDate, !eventStartDate.isEmpty {
            return eventStartDate
        }
        return nil
    }
}

public struct SectionData: Equatable, Sendable, Codable {
    public var items: [FeedItem]

    public init(items: [FeedItem]) {
        self.items = items
    }
}

public enum SectionSkipReason: String, Equatable, Sendable, Codable {
    case unsupportedContentType
    case unsupportedLayout
    case unsupportedCardType
    case unsupportedScrollDirection
    case hiddenByConfiguration
    case invalidEndpoint
}

public enum ConfigurationValidationError: Error, Equatable, Sendable {
    case malformedConfiguration(String)
    case unknownParameters([String])
    case unsupportedParameters([String])
}

public enum HomeFeedError: Error, Equatable, Sendable {
    case noRenderableSections
    case allSectionsFailed
    case configurationValidationFailed(ConfigurationValidationError)
    case networking(String)

    public static func == (lhs: HomeFeedError, rhs: HomeFeedError) -> Bool {
        switch (lhs, rhs) {
        case (.noRenderableSections, .noRenderableSections):
            return true
        case (.allSectionsFailed, .allSectionsFailed):
            return true
        case let (.configurationValidationFailed(left), .configurationValidationFailed(right)):
            return left == right
        case let (.networking(left), .networking(right)):
            return left == right
        default:
            return false
        }
    }
}

public enum SectionState: Equatable, Sendable, Codable {
    case idle
    case loading
    case loaded(SectionData)
    case failed(String)
    case skipped(SectionSkipReason)
}

public struct FeedSectionState: Identifiable, Equatable, Sendable, Codable {
    public let id: String
    public var meta: SectionMeta
    public var state: SectionState

    public init(meta: SectionMeta, state: SectionState) {
        self.id = meta.id
        self.meta = meta
        self.state = state
    }
}

extension SectionState {
    private enum CodingKeys: String, CodingKey {
        case kind
        case data
        case message
        case reason
    }

    private enum Kind: String, Codable {
        case idle
        case loading
        case loaded
        case failed
        case skipped
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        switch kind {
        case .idle:
            self = .idle
        case .loading:
            self = .loading
        case .loaded:
            self = .loaded(try container.decode(SectionData.self, forKey: .data))
        case .failed:
            self = .failed(try container.decode(String.self, forKey: .message))
        case .skipped:
            self = .skipped(try container.decode(SectionSkipReason.self, forKey: .reason))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .idle:
            try container.encode(Kind.idle, forKey: .kind)
        case .loading:
            try container.encode(Kind.loading, forKey: .kind)
        case let .loaded(data):
            try container.encode(Kind.loaded, forKey: .kind)
            try container.encode(data, forKey: .data)
        case let .failed(message):
            try container.encode(Kind.failed, forKey: .kind)
            try container.encode(message, forKey: .message)
        case let .skipped(reason):
            try container.encode(Kind.skipped, forKey: .kind)
            try container.encode(reason, forKey: .reason)
        }
    }
}
