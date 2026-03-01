import Foundation

public struct HomeFeedCapabilities: Equatable, Sendable {
    public let supportedContentTypes: Set<ContentType>
    public let supportedCardTypes: Set<CardType>
    public let supportedLayouts: Set<LayoutType>
    public let supportedScrollDirections: Set<ScrollDirection>
    public let supportedSectionParameters: Set<String>

    public init(
        supportedContentTypes: Set<ContentType>,
        supportedCardTypes: Set<CardType>,
        supportedLayouts: Set<LayoutType>,
        supportedScrollDirections: Set<ScrollDirection>,
        supportedSectionParameters: Set<String>
    ) {
        self.supportedContentTypes = supportedContentTypes
        self.supportedCardTypes = supportedCardTypes
        self.supportedLayouts = supportedLayouts
        self.supportedScrollDirections = supportedScrollDirections
        self.supportedSectionParameters = supportedSectionParameters
    }

    public static var `default`: HomeFeedCapabilities {
        HomeFeedCapabilities(
            supportedContentTypes: [
                .document,
                .onDemandWebinar,
                .upcomingWebinar,
                .video,
                .podcast,
                .inquiry,
                .conference
            ],
            supportedCardTypes: [.compactHeight, .compactWidth, .topThumbnail, .insight],
            supportedLayouts: [.horizontalList, .verticalList, .grid],
            supportedScrollDirections: [.horizontal, .vertical],
            supportedSectionParameters: [
                "rank",
                "section_type",
                "endpoint",
                "header",
                "supportedContents",
                "theme",
                "analytics",
                "showSection",
                "groupCount",
                "cardCount",
                "sectionHeaderCta",
                "sectionFooterCta",
                "footerCta",
                "contentHeaderCta",
                "contentFooterCta",
                "sectionStyle",
                "placement",
                "containers",
                "behaviour"
            ]
        )
    }
}
