import SwiftUI

struct card_type_content_type_view: View {
    let cardType: CardType
    let item: FeedItem
    let container: ContainerMeta?

    init(cardType: CardType, item: FeedItem, container: ContainerMeta? = nil) {
        self.cardType = cardType
        self.item = item
        self.container = container
    }

    var body: some View {
        switch (cardType.rawValue, item.contentType.rawValue) {
        case (CardType.compactHeight.rawValue, ContentType.document.rawValue):
            compact_height_document_view(item: item, container: container)
        case (CardType.compactHeight.rawValue, ContentType.onDemandWebinar.rawValue):
            compact_height_on_demand_webinar_view(item: item, container: container)
        case (CardType.compactHeight.rawValue, ContentType.upcomingWebinar.rawValue):
            compact_height_upcoming_webinar_view(item: item, container: container)
        case (CardType.compactHeight.rawValue, ContentType.video.rawValue):
            compact_height_video_view(item: item, container: container)
        case (CardType.compactHeight.rawValue, ContentType.podcast.rawValue):
            compact_height_podcast_view(item: item, container: container)
        case (CardType.compactHeight.rawValue, ContentType.inquiry.rawValue):
            compact_height_inquiry_view(item: item, container: container)
        case (CardType.compactHeight.rawValue, ContentType.conference.rawValue):
            compact_height_conference_view(item: item, container: container)

        case (CardType.compactWidth.rawValue, ContentType.document.rawValue):
            compact_width_document_view(item: item, container: container)
        case (CardType.compactWidth.rawValue, ContentType.onDemandWebinar.rawValue):
            compact_width_on_demand_webinar_view(item: item, container: container)
        case (CardType.compactWidth.rawValue, ContentType.upcomingWebinar.rawValue):
            compact_width_upcoming_webinar_view(item: item, container: container)
        case (CardType.compactWidth.rawValue, ContentType.video.rawValue):
            compact_width_video_view(item: item, container: container)
        case (CardType.compactWidth.rawValue, ContentType.podcast.rawValue):
            compact_width_podcast_view(item: item, container: container)
        case (CardType.compactWidth.rawValue, ContentType.inquiry.rawValue):
            compact_width_inquiry_view(item: item, container: container)
        case (CardType.compactWidth.rawValue, ContentType.conference.rawValue):
            compact_width_conference_view(item: item, container: container)

        case (CardType.topThumbnail.rawValue, ContentType.document.rawValue):
            top_thumbnail_document_view(item: item, container: container)
        case (CardType.topThumbnail.rawValue, ContentType.onDemandWebinar.rawValue):
            top_thumbnail_on_demand_webinar_view(item: item, container: container)
        case (CardType.topThumbnail.rawValue, ContentType.upcomingWebinar.rawValue):
            top_thumbnail_upcoming_webinar_view(item: item, container: container)
        case (CardType.topThumbnail.rawValue, ContentType.video.rawValue):
            top_thumbnail_video_view(item: item, container: container)
        case (CardType.topThumbnail.rawValue, ContentType.podcast.rawValue):
            top_thumbnail_podcast_view(item: item, container: container)
        case (CardType.topThumbnail.rawValue, ContentType.inquiry.rawValue):
            top_thumbnail_inquiry_view(item: item, container: container)
        case (CardType.topThumbnail.rawValue, ContentType.conference.rawValue):
            top_thumbnail_conference_view(item: item, container: container)

        case (CardType.insight.rawValue, ContentType.document.rawValue):
            insight_document_view(item: item, container: container)
        case (CardType.insight.rawValue, ContentType.onDemandWebinar.rawValue):
            insight_on_demand_webinar_view(item: item, container: container)
        case (CardType.insight.rawValue, ContentType.upcomingWebinar.rawValue):
            insight_upcoming_webinar_view(item: item, container: container)
        case (CardType.insight.rawValue, ContentType.video.rawValue):
            insight_video_view(item: item, container: container)
        case (CardType.insight.rawValue, ContentType.podcast.rawValue):
            insight_podcast_view(item: item, container: container)
        case (CardType.insight.rawValue, ContentType.inquiry.rawValue):
            insight_inquiry_view(item: item, container: container)
        case (CardType.insight.rawValue, ContentType.conference.rawValue):
            insight_conference_view(item: item, container: container)

        default:
            fallback_card_content_view(item: item, cardType: cardType, container: container)
        }
    }
}

private struct combo_card_view: View {
    let item: FeedItem
    let cardType: CardType
    let minHeight: CGFloat
    let width: CGFloat?
    let container: ContainerMeta?

    var body: some View {
        content_card_shell_view(
            item: item,
            cardType: cardType,
            minHeight: minHeight,
            width: width,
            container: container
        )
    }
}

private struct content_card_shell_view: View {
    let item: FeedItem
    let cardType: CardType
    let minHeight: CGFloat
    let width: CGFloat?
    let container: ContainerMeta?

    private var accent: Color {
        SystemDesign.accent(for: item.contentType)
    }

    private var shouldShowImage: Bool {
        container?.showImage ?? item.showImage
    }

    private var showsImagePagination: Bool {
        container?.imagePaginationEnabled ?? item.multipleImageSupport
    }

    private var usesTopImage: Bool {
        cardType == .topThumbnail
    }

    private var sideImageWidth: CGFloat {
        switch cardType {
        case .compactWidth:
            return 52
        default:
            return 76
        }
    }

    private var sideImageHeight: CGFloat {
        switch cardType {
        case .compactWidth:
            return 52
        default:
            return 76
        }
    }

    private var topImageHeight: CGFloat {
        switch cardType {
        case .topThumbnail:
            return 112
        case .insight:
            return 88
        default:
            return 96
        }
    }

    private var metaLines: [String] {
        [item.primaryMetaLine, item.eventLocation].compactMap { normalizedText($0) }
    }

    private var actions: [FeedItemAction] {
        [item.primaryAction, item.secondaryAction].compactMap { $0 }
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: SystemDesign.CornerRadius.card, style: .continuous)

        VStack(alignment: .leading, spacing: SystemDesign.Spacing.sm) {
            if usesTopImage, shouldShowImage, let imageURL = item.imageURL {
                content_card_image_view(
                    imageURL: imageURL,
                    accent: accent,
                    height: topImageHeight,
                    width: nil
                )
            }

            if shouldShowImage, !usesTopImage, let imageURL = item.imageURL {
                HStack(alignment: .top, spacing: SystemDesign.Spacing.md) {
                    content_card_copy_view(
                        item: item,
                        accent: accent,
                        showsImagePagination: showsImagePagination,
                        showsExtendedSummary: cardType != .compactWidth
                    )
                    content_card_image_view(
                        imageURL: imageURL,
                        accent: accent,
                        height: sideImageHeight,
                        width: sideImageWidth
                    )
                }
            } else {
                content_card_copy_view(
                    item: item,
                    accent: accent,
                    showsImagePagination: showsImagePagination,
                    showsExtendedSummary: cardType != .compactWidth
                )
            }

            if !actions.isEmpty {
                content_card_actions_view(actions: actions, accent: accent)
            }
        }
        .padding(SystemDesign.Spacing.xl)
        .frame(maxWidth: width == nil ? .infinity : nil, minHeight: minHeight, alignment: .topLeading)
        .frame(width: width)
        .background(SystemDesign.color(.surface), in: shape)
        .overlay(
            shape.stroke(accent.opacity(0.18), lineWidth: SystemDesign.Border.thin)
        )
        .accessibilityIdentifier("\(cardType.rawValue)_\(item.contentType.rawValue)")
    }

    private func normalizedText(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return value
    }
}

private struct content_card_copy_view: View {
    let item: FeedItem
    let accent: Color
    let showsImagePagination: Bool
    let showsExtendedSummary: Bool

    private var summaryText: String? {
        guard let summary = item.summary?.trimmingCharacters(in: .whitespacesAndNewlines), !summary.isEmpty else {
            return nil
        }
        return summary
    }

    private var chipText: String {
        item.statusText ?? displayName(for: item.contentType)
    }

    private var secondaryMetaText: String? {
        if item.contentType == .conference, let eventTime = item.eventTime {
            return eventTime
        }
        if item.contentType == .inquiry, let timeZone = item.displayTimeZone {
            return timeZone
        }
        return nil
    }

    private var detailLineLimit: Int {
        showsExtendedSummary ? 3 : 2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SystemDesign.Spacing.sm) {
            HStack(spacing: SystemDesign.Spacing.xs) {
                content_card_chip_view(title: chipText, accent: accent)
                if showsImagePagination {
                    content_card_chip_view(title: "Gallery", accent: accent.opacity(0.7))
                }
            }

            Text(item.title)
                .font(SystemDesign.font(.cardTitle))
                .lineSpacing(SystemDesign.lineSpacing(.cardTitle))
                .foregroundStyle(SystemDesign.color(.cardTitle))
                .lineLimit(3)

            if let meta = item.primaryMetaLine {
                Text(meta)
                    .font(SystemDesign.font(.caption))
                    .lineSpacing(SystemDesign.lineSpacing(.caption))
                    .foregroundStyle(SystemDesign.color(.caption))
                    .lineLimit(2)
            }

            if let location = item.eventLocation, item.contentType != .conference {
                Text(location)
                    .font(SystemDesign.font(.caption))
                    .foregroundStyle(SystemDesign.color(.caption))
                    .lineLimit(1)
            }

            if let secondaryMetaText {
                Text(secondaryMetaText)
                    .font(SystemDesign.font(.caption))
                    .foregroundStyle(SystemDesign.color(.caption))
                    .lineLimit(1)
            }

            if let summaryText {
                Text(summaryText)
                    .font(SystemDesign.font(.cardDescription))
                    .lineSpacing(SystemDesign.lineSpacing(.cardDescription))
                    .foregroundStyle(SystemDesign.Typography.cardDescription.foregroundColor)
                    .lineLimit(detailLineLimit)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func displayName(for contentType: ContentType) -> String {
        switch contentType {
        case .document:
            return "Document"
        case .onDemandWebinar:
            return "On-Demand Webinar"
        case .upcomingWebinar:
            return "Upcoming Webinar"
        case .video:
            return "Video"
        case .podcast:
            return "Podcast"
        case .inquiry:
            return "Inquiry"
        case .conference:
            return "Conference"
        default:
            return contentType.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

private struct content_card_chip_view: View {
    let title: String
    let accent: Color

    var body: some View {
        Text(title)
            .font(SystemDesign.font(.cardContentType))
            .foregroundStyle(accent)
            .padding(.horizontal, SystemDesign.Spacing.sm)
            .padding(.vertical, SystemDesign.Spacing.xxs)
            .background(accent.opacity(0.1), in: Capsule())
    }
}

private struct content_card_image_view: View {
    let imageURL: String
    let accent: Color
    let height: CGFloat
    let width: CGFloat?

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: SystemDesign.CornerRadius.card, style: .continuous)

        AsyncImage(url: URL(string: imageURL)) { phase in
            switch phase {
            case let .success(image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                Rectangle()
                    .fill(accent.opacity(0.12))
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(accent)
                    )
            }
        }
        .frame(maxWidth: width == nil ? .infinity : nil)
        .frame(width: width, height: height)
        .clipShape(shape)
        .overlay(
            shape.stroke(SystemDesign.color(.border), lineWidth: SystemDesign.Border.thin)
        )
    }
}

private struct content_card_actions_view: View {
    let actions: [FeedItemAction]
    let accent: Color

    var body: some View {
        HStack(spacing: SystemDesign.Spacing.xs) {
            ForEach(Array(actions.enumerated()), id: \.offset) { _, action in
                Text(action.title)
                    .font(SystemDesign.font(.caption))
                    .foregroundStyle(action.url == nil ? accent : SystemDesign.buttonForegroundColor)
                    .padding(.horizontal, SystemDesign.Spacing.sm)
                    .padding(.vertical, SystemDesign.Spacing.xxs)
                    .background(SystemDesign.color(.statusBackground), in: Capsule())
            }
        }
    }
}

struct compact_height_document_view: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View { combo_card_view(item: item, cardType: .compactHeight, minHeight: SystemDesign.CardMetrics.compactHeightMinHeight, width: SystemDesign.CardMetrics.compactHeightWidth, container: container) }
}

struct compact_height_on_demand_webinar_view: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View { combo_card_view(item: item, cardType: .compactHeight, minHeight: SystemDesign.CardMetrics.compactHeightMinHeight, width: SystemDesign.CardMetrics.compactHeightWidth, container: container) }
}

struct compact_height_upcoming_webinar_view: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View { combo_card_view(item: item, cardType: .compactHeight, minHeight: SystemDesign.CardMetrics.compactHeightMinHeight, width: SystemDesign.CardMetrics.compactHeightWidth, container: container) }
}

struct compact_height_video_view: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View { combo_card_view(item: item, cardType: .compactHeight, minHeight: SystemDesign.CardMetrics.compactHeightMinHeight, width: SystemDesign.CardMetrics.compactHeightWidth, container: container) }
}

struct compact_height_podcast_view: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View { combo_card_view(item: item, cardType: .compactHeight, minHeight: SystemDesign.CardMetrics.compactHeightMinHeight, width: SystemDesign.CardMetrics.compactHeightWidth, container: container) }
}

struct compact_height_inquiry_view: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View { combo_card_view(item: item, cardType: .compactHeight, minHeight: SystemDesign.CardMetrics.compactHeightMinHeight, width: SystemDesign.CardMetrics.compactHeightWidth, container: container) }
}

struct compact_height_conference_view: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View { combo_card_view(item: item, cardType: .compactHeight, minHeight: SystemDesign.CardMetrics.compactHeightMinHeight, width: SystemDesign.CardMetrics.compactHeightWidth, container: container) }
}

struct compact_width_document_view: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View { combo_card_view(item: item, cardType: .compactWidth, minHeight: SystemDesign.CardMetrics.compactWidthMinHeight, width: SystemDesign.CardMetrics.compactWidthWidth, container: container) }
}

struct compact_width_on_demand_webinar_view: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View { combo_card_view(item: item, cardType: .compactWidth, minHeight: SystemDesign.CardMetrics.compactWidthMinHeight, width: SystemDesign.CardMetrics.compactWidthWidth, container: container) }
}

struct compact_width_upcoming_webinar_view: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View { combo_card_view(item: item, cardType: .compactWidth, minHeight: SystemDesign.CardMetrics.compactWidthMinHeight, width: SystemDesign.CardMetrics.compactWidthWidth, container: container) }
}

struct compact_width_video_view: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View { combo_card_view(item: item, cardType: .compactWidth, minHeight: SystemDesign.CardMetrics.compactWidthMinHeight, width: SystemDesign.CardMetrics.compactWidthWidth, container: container) }
}

struct compact_width_podcast_view: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View { combo_card_view(item: item, cardType: .compactWidth, minHeight: SystemDesign.CardMetrics.compactWidthMinHeight, width: SystemDesign.CardMetrics.compactWidthWidth, container: container) }
}

struct compact_width_inquiry_view: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View { combo_card_view(item: item, cardType: .compactWidth, minHeight: SystemDesign.CardMetrics.compactWidthMinHeight, width: SystemDesign.CardMetrics.compactWidthWidth, container: container) }
}

struct compact_width_conference_view: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View { combo_card_view(item: item, cardType: .compactWidth, minHeight: SystemDesign.CardMetrics.compactWidthMinHeight, width: SystemDesign.CardMetrics.compactWidthWidth, container: container) }
}

struct top_thumbnail_document_view: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View { combo_card_view(item: item, cardType: .topThumbnail, minHeight: SystemDesign.CardMetrics.topThumbnailMinHeight, width: nil, container: container) }
}

struct top_thumbnail_on_demand_webinar_view: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View { combo_card_view(item: item, cardType: .topThumbnail, minHeight: SystemDesign.CardMetrics.topThumbnailMinHeight, width: nil, container: container) }
}

struct top_thumbnail_upcoming_webinar_view: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View { combo_card_view(item: item, cardType: .topThumbnail, minHeight: SystemDesign.CardMetrics.topThumbnailMinHeight, width: nil, container: container) }
}

struct top_thumbnail_video_view: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View { combo_card_view(item: item, cardType: .topThumbnail, minHeight: SystemDesign.CardMetrics.topThumbnailMinHeight, width: nil, container: container) }
}

struct top_thumbnail_podcast_view: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View { combo_card_view(item: item, cardType: .topThumbnail, minHeight: SystemDesign.CardMetrics.topThumbnailMinHeight, width: nil, container: container) }
}

struct top_thumbnail_inquiry_view: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View { combo_card_view(item: item, cardType: .topThumbnail, minHeight: SystemDesign.CardMetrics.topThumbnailMinHeight, width: nil, container: container) }
}

struct top_thumbnail_conference_view: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View { combo_card_view(item: item, cardType: .topThumbnail, minHeight: SystemDesign.CardMetrics.topThumbnailMinHeight, width: nil, container: container) }
}

struct insight_document_view: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View { combo_card_view(item: item, cardType: .insight, minHeight: SystemDesign.CardMetrics.insightMinHeight, width: nil, container: container) }
}

struct insight_on_demand_webinar_view: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View { combo_card_view(item: item, cardType: .insight, minHeight: SystemDesign.CardMetrics.insightMinHeight, width: nil, container: container) }
}

struct insight_upcoming_webinar_view: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View { combo_card_view(item: item, cardType: .insight, minHeight: SystemDesign.CardMetrics.insightMinHeight, width: nil, container: container) }
}

struct insight_video_view: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View { combo_card_view(item: item, cardType: .insight, minHeight: SystemDesign.CardMetrics.insightMinHeight, width: nil, container: container) }
}

struct insight_podcast_view: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View { combo_card_view(item: item, cardType: .insight, minHeight: SystemDesign.CardMetrics.insightMinHeight, width: nil, container: container) }
}

struct insight_inquiry_view: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View { combo_card_view(item: item, cardType: .insight, minHeight: SystemDesign.CardMetrics.insightMinHeight, width: nil, container: container) }
}

struct insight_conference_view: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View { combo_card_view(item: item, cardType: .insight, minHeight: SystemDesign.CardMetrics.insightMinHeight, width: nil, container: container) }
}

private struct fallback_card_content_view: View {
    let item: FeedItem
    let cardType: CardType
    let container: ContainerMeta?

    var body: some View {
        combo_card_view(
            item: item,
            cardType: cardType,
            minHeight: SystemDesign.CardMetrics.fallbackMinHeight,
            width: nil,
            container: container
        )
    }
}

#Preview {
    card_type_content_type_view(
        cardType: .compactHeight,
        item: FeedItem(
            id: "preview",
            contentType: .document,
            title: "How To Calculate Business Value and Cost for Generative AI Use Case",
            behaviour: FeedItemBehaviour(
                summary: "A sample card wired through the reusable FeedItem bridge.",
                media: FeedItemMedia(imageURL: "https://www.gartner.com/resources/836200/836261/Figure_1_CIO_Leadership_of_People_Culture_and_Change_Overview.png"),
                schedule: FeedItemSchedule(publishedDate: "2 Dec 2025"),
                primaryAction: FeedItemAction(title: "Save")
            )
        )
    )
    .padding()
}
