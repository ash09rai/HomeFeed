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
            CompactHeightDocumentView(item: item, container: container)
        case (CardType.compactHeight.rawValue, ContentType.onDemandWebinar.rawValue):
            CompactHeightOnDemandWebinarView(item: item, container: container)
        case (CardType.compactHeight.rawValue, ContentType.upcomingWebinar.rawValue):
            CompactHeightUpcomingWebinarView(item: item, container: container)
        case (CardType.compactHeight.rawValue, ContentType.video.rawValue):
            CompactHeightVideoView(item: item, container: container)
        case (CardType.compactHeight.rawValue, ContentType.podcast.rawValue):
            CompactHeightPodcastView(item: item, container: container)
        case (CardType.compactHeight.rawValue, ContentType.inquiry.rawValue):
            CompactHeightInquiryView(item: item, container: container)
        case (CardType.compactHeight.rawValue, ContentType.conference.rawValue):
            CompactHeightConferenceView(item: item, container: container)

        case (CardType.compactWidth.rawValue, ContentType.document.rawValue):
            CompactWidthDocumentView(item: item, container: container)
        case (CardType.compactWidth.rawValue, ContentType.onDemandWebinar.rawValue):
            CompactWidthOnDemandWebinarView(item: item, container: container)
        case (CardType.compactWidth.rawValue, ContentType.upcomingWebinar.rawValue):
            CompactWidthUpcomingWebinarView(item: item, container: container)
        case (CardType.compactWidth.rawValue, ContentType.video.rawValue):
            CompactWidthVideoView(item: item, container: container)
        case (CardType.compactWidth.rawValue, ContentType.podcast.rawValue):
            CompactWidthPodcastView(item: item, container: container)
        case (CardType.compactWidth.rawValue, ContentType.inquiry.rawValue):
            CompactWidthInquiryView(item: item, container: container)
        case (CardType.compactWidth.rawValue, ContentType.conference.rawValue):
            CompactWidthConferenceView(item: item, container: container)

        case (CardType.topThumbnail.rawValue, ContentType.document.rawValue):
            TopThumbnailDocumentView(item: item, container: container)
        case (CardType.topThumbnail.rawValue, ContentType.onDemandWebinar.rawValue):
            TopThumbnailOnDemandWebinarView(item: item, container: container)
        case (CardType.topThumbnail.rawValue, ContentType.upcomingWebinar.rawValue):
            TopThumbnailUpcomingWebinarView(item: item, container: container)
        case (CardType.topThumbnail.rawValue, ContentType.video.rawValue):
            TopThumbnailVideoView(item: item, container: container)
        case (CardType.topThumbnail.rawValue, ContentType.podcast.rawValue):
            TopThumbnailPodcastView(item: item, container: container)
        case (CardType.topThumbnail.rawValue, ContentType.inquiry.rawValue):
            TopThumbnailInquiryView(item: item, container: container)
        case (CardType.topThumbnail.rawValue, ContentType.conference.rawValue):
            TopThumbnailConferenceView(item: item, container: container)

        case (CardType.insight.rawValue, ContentType.document.rawValue):
            InsightDocumentView(item: item, container: container)
        case (CardType.insight.rawValue, ContentType.onDemandWebinar.rawValue):
            InsightOnDemandWebinarView(item: item, container: container)
        case (CardType.insight.rawValue, ContentType.upcomingWebinar.rawValue):
            InsightUpcomingWebinarView(item: item, container: container)
        case (CardType.insight.rawValue, ContentType.video.rawValue):
            InsightVideoView(item: item, container: container)
        case (CardType.insight.rawValue, ContentType.podcast.rawValue):
            InsightPodcastView(item: item, container: container)
        case (CardType.insight.rawValue, ContentType.inquiry.rawValue):
            InsightInquiryView(item: item, container: container)
        case (CardType.insight.rawValue, ContentType.conference.rawValue):
            InsightConferenceView(item: item, container: container)

        default:
            EmptyView()
        }
    }
}

struct home_feed_media_card_view: View {
    let item: FeedItem
    let cardType: CardType
    let container: ContainerMeta?

    private var context: home_feed_card_context {
        home_feed_card_context(item: item, cardType: cardType, container: container)
    }

    private var minHeight: CGFloat {
        switch cardType {
        case .compactHeight:
            return 136
        case .compactWidth:
            return 278
        case .topThumbnail:
            return 302
        case .insight:
            return 315
        default:
            return 136
        }
    }

    var body: some View {
        home_feed_card_chrome(
            accent: context.accent,
            minHeight: minHeight,
            preferredWidth: context.preferredWidth,
            accessibilityID: context.accessibilityID
        ) {
            switch cardType {
            case .compactHeight:
                compactHeightBody
            case .compactWidth:
                compactWidthBody
            case .topThumbnail:
                topThumbnailBody
            case .insight:
                insightBody
            default:
                compactHeightBody
            }
        }
    }

    private var compactHeightBody: some View {
        VStack(alignment: .leading, spacing: SystemDesign.Spacing.sm) {
            HStack(alignment: .top, spacing: SystemDesign.Spacing.sm) {
                home_feed_media_copy_block_view(
                    item: item,
                    showsSummary: false,
                    titleLineLimit: 3,
                    summaryLineLimit: 0
                )

                if context.hasImage {
                    home_feed_media_image_container_view(
                        item: item,
                        container: container,
                        height: 67,
                        width: 116,
                        showRadius: true
                    )
                }
            }

            Spacer(minLength: 0)

            HStack(spacing: SystemDesign.Spacing.sm) {
                if let metaText = context.primaryMetaText {
                    PublishedDateLabelView(dateText: metaText)
                }
                Spacer(minLength: 0)
                home_feed_media_action_bar_view(item: item)
            }
            .frame(height: 44)
        }
        .padding(.top, 16)
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .padding(.bottom, 12)
    }

    private var compactWidthBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            if context.hasImage {
                home_feed_media_image_container_view(
                    item: item,
                    container: container,
                    height: 94,
                    width: nil,
                    showRadius: false
                )
            }

            home_feed_media_copy_block_view(
                item: item,
                showsSummary: !context.hasImage,
                titleLineLimit: 3,
                summaryLineLimit: 2
            )
            .padding(.horizontal, 12)

            Spacer(minLength: 0)

            HStack(spacing: SystemDesign.Spacing.sm) {
                home_feed_media_action_bar_view(item: item)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }

    private var topThumbnailBody: some View {
        mediaLargeBody(imageHeight: 180, showsSummary: !context.hasImage)
    }

    private var insightBody: some View {
        mediaLargeBody(imageHeight: 136, showsSummary: true)
    }

    private func mediaLargeBody(imageHeight: CGFloat, showsSummary: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if context.hasImage {
                home_feed_media_image_container_view(
                    item: item,
                    container: container,
                    height: imageHeight,
                    width: nil,
                    showRadius: false
                )
            }

            home_feed_media_copy_block_view(
                item: item,
                showsSummary: showsSummary,
                titleLineLimit: 3,
                summaryLineLimit: 4
            )
            .padding(.horizontal, 16)

            Spacer(minLength: 0)

            HStack(spacing: SystemDesign.Spacing.sm) {
                if let metaText = context.primaryMetaText {
                    PublishedDateLabelView(dateText: metaText)
                }
                Spacer(minLength: 0)
                home_feed_media_action_bar_view(item: item)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
}

struct home_feed_event_card_view: View {
    let item: FeedItem
    let cardType: CardType
    let container: ContainerMeta?

    private var context: home_feed_card_context {
        home_feed_card_context(item: item, cardType: cardType, container: container)
    }

    private var minHeight: CGFloat {
        switch cardType {
        case .compactHeight:
            return 128
        case .compactWidth:
            return 278
        case .topThumbnail:
            return 241
        case .insight:
            return 315
        default:
            return 128
        }
    }

    var body: some View {
        home_feed_card_chrome(
            accent: context.accent,
            minHeight: minHeight,
            preferredWidth: context.preferredWidth,
            accessibilityID: context.accessibilityID
        ) {
            switch cardType {
            case .compactHeight:
                compactHeightBody
            case .compactWidth:
                compactWidthBody
            case .topThumbnail:
                largeBody(padding: 16)
            case .insight:
                largeBody(padding: 16)
            default:
                compactHeightBody
            }
        }
    }

    private var compactHeightBody: some View {
        HStack(alignment: .top, spacing: 12) {
            home_feed_calendar_badge_view(item: item, size: 70)

            VStack(alignment: .leading, spacing: 4) {
                home_feed_event_copy_block_view(
                    item: item,
                    showsSummary: false,
                    titleLineLimit: 3,
                    metaLineLimit: 2
                )

                Spacer(minLength: 0)

                home_feed_event_action_bar_view(item: item, vertical: false)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding(.all, 12)
    }

    private var compactWidthBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            home_feed_calendar_badge_view(item: item, size: 58)
                .padding(.bottom, 8)

            home_feed_event_copy_block_view(
                item: item,
                showsSummary: false,
                titleLineLimit: 3,
                metaLineLimit: 2
            )

            Spacer(minLength: 0)

            home_feed_event_action_bar_view(item: item, vertical: true)
        }
        .padding(.all, 12)
    }

    private func largeBody(padding: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 8) {
            home_feed_calendar_badge_view(item: item, size: 70)

            VStack(alignment: .leading, spacing: 8) {
                home_feed_event_copy_block_view(
                    item: item,
                    showsSummary: true,
                    titleLineLimit: 3,
                    metaLineLimit: 2
                )

                Spacer(minLength: 0)

                home_feed_event_action_bar_view(item: item, vertical: false)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding(.all, padding)
    }
}

private struct home_feed_card_context {
    let item: FeedItem
    let cardType: CardType
    let container: ContainerMeta?

    var accent: Color {
        SystemDesign.accent(for: item.contentType)
    }

    var shouldShowImage: Bool {
        container?.showImage ?? item.showImage
    }

    var hasImage: Bool {
        shouldShowImage && !item.imageURLs.isEmpty
    }

    var primaryMetaText: String? {
        normalized(item.primaryMetaLine)
    }

    var preferredWidth: CGFloat? {
        guard container?.layout == .horizontalList else {
            return nil
        }

        switch cardType {
        case .compactHeight:
            return 343
        case .compactWidth:
            return 166
        case .topThumbnail:
            return 343
        case .insight:
            return 315
        default:
            return nil
        }
    }

    var accessibilityID: String {
        "\(cardType.rawValue)_\(item.contentType.rawValue)"
    }

    private func normalized(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return value
    }
}

private struct home_feed_card_chrome<Content: View>: View {
    let accent: Color
    let minHeight: CGFloat
    let preferredWidth: CGFloat?
    let accessibilityID: String
    let content: () -> Content

    init(
        accent: Color,
        minHeight: CGFloat,
        preferredWidth: CGFloat?,
        accessibilityID: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.accent = accent
        self.minHeight = minHeight
        self.preferredWidth = preferredWidth
        self.accessibilityID = accessibilityID
        self.content = content
    }

    var body: some View {
        let cardShape = RoundedRectangle(cornerRadius: SystemDesign.CornerRadius.card, style: .continuous)

        content()
            .frame(maxWidth: preferredWidth == nil ? .infinity : nil, minHeight: minHeight, alignment: .topLeading)
            .frame(width: preferredWidth)
            .background(SystemDesign.color(.surface), in: cardShape)
            .overlay(
                cardShape.stroke(accent.opacity(0.2), lineWidth: SystemDesign.Border.thin)
            )
            .accessibilityIdentifier(accessibilityID)
    }
}

private struct home_feed_media_copy_block_view: View {
    let item: FeedItem
    let showsSummary: Bool
    let titleLineLimit: Int
    let summaryLineLimit: Int

    private var summaryText: String? {
        guard showsSummary else {
            return nil
        }
        return normalized(item.summary)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardTitleLabelView(cardTitle: item.title)
                .lineLimit(titleLineLimit)

            if let summaryText {
                Text(summaryText)
                    .font(SystemDesign.font(.cardDescription))
                    .foregroundStyle(SystemDesign.color(.cardDescription))
                    .lineSpacing(SystemDesign.lineSpacing(.cardDescription))
                    .lineLimit(summaryLineLimit)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func normalized(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return value
    }
}

private struct home_feed_media_image_container_view: View {
    let item: FeedItem
    let container: ContainerMeta?
    let height: CGFloat
    let width: CGFloat?
    let showRadius: Bool

    private var showsImagePagination: Bool {
        (container?.imagePaginationEnabled ?? item.multipleImageSupport) && item.imageURLs.count > 1
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            CompactHeightDocumentImageView(item: item, showRadius: showRadius)
                .frame(maxWidth: width == nil ? .infinity : nil)
                .frame(width: width, height: height)
                .clipped()

            if showsImagePagination {
                home_feed_gallery_indicator_view()
                    .padding(8)
            }
        }
    }
}

private struct home_feed_gallery_indicator_view: View {
    var body: some View {
        Text("Gallery")
            .font(SystemDesign.font(.cardContentType))
            .foregroundStyle(SystemDesign.color(.surface))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.55), in: Capsule())
    }
}

private struct home_feed_media_action_bar_view: View {
    let item: FeedItem

    var body: some View {
        HStack(spacing: SystemDesign.Spacing.sm) {
            SaveButton(handler: SaveHandler())

            switch secondaryAction {
            case .listen:
                ListenButtonView(handler: ListenHandler())
            case .play:
                PlayButtonView(handler: PlayHandler())
            }
        }
    }

    private var secondaryAction: home_feed_media_secondary_action {
        switch item.contentType {
        case .document, .podcast:
            return .listen
        case .onDemandWebinar, .video:
            return .play
        default:
            return .play
        }
    }
}

private enum home_feed_media_secondary_action {
    case listen
    case play
}

private struct home_feed_calendar_badge_view: View {
    let item: FeedItem
    let size: CGFloat

    var body: some View {
        CalendarView(
            startDate: home_feed_parse_date(item.eventDate) ?? home_feed_parse_date(item.eventStartDate),
            endDate: home_feed_parse_date(item.eventEndDate)
        )
        .frame(width: size, height: size)
    }
}

private struct home_feed_event_copy_block_view: View {
    let item: FeedItem
    let showsSummary: Bool
    let titleLineLimit: Int
    let metaLineLimit: Int

    private var metaText: String? {
        normalized(item.primaryMetaLine)
    }

    private var locationText: String? {
        normalized(item.eventLocation)
    }

    private var supplementalMetaText: String? {
        guard let eventTime = normalized(item.eventTime) else {
            return nil
        }
        guard metaText?.contains(eventTime) != true else {
            return nil
        }
        return eventTime
    }

    private var summaryText: String? {
        guard showsSummary else {
            return nil
        }
        return normalized(item.summary)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ContentLabel(contentType: item.contentType)
                .frame(height: 16)

            CardTitleLabelView(cardTitle: item.title)
                .lineLimit(titleLineLimit)

            if let metaText {
                home_feed_meta_text_view(text: metaText, lineLimit: metaLineLimit)
            }

            if let locationText {
                home_feed_meta_text_view(text: locationText, lineLimit: 2)
            }

            if let supplementalMetaText {
                home_feed_meta_text_view(text: supplementalMetaText, lineLimit: 2)
            }

            if let summaryText {
                Text(summaryText)
                    .font(SystemDesign.font(.cardDescription))
                    .foregroundStyle(SystemDesign.color(.cardDescription))
                    .lineSpacing(SystemDesign.lineSpacing(.cardDescription))
                    .lineLimit(3)
                    .padding(.top, 4)
            }
        }
    }

    private func normalized(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return value
    }
}

private struct home_feed_meta_text_view: View {
    let text: String
    let lineLimit: Int

    var body: some View {
        Text(text)
            .font(SystemDesign.font(.location))
            .foregroundStyle(SystemDesign.color(.location))
            .lineLimit(lineLimit)
    }
}

private struct home_feed_event_action_bar_view: View {
    let item: FeedItem
    let vertical: Bool

    private var actions: [FeedItemAction] {
        [item.primaryAction, item.secondaryAction].compactMap { action in
            guard let action, !action.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }
            return action
        }
    }

    var body: some View {
        Group {
            if actions.isEmpty {
                EmptyView()
            } else if vertical {
                VStack(alignment: .leading, spacing: 6) {
                    actionList
                }
            } else {
                HStack(spacing: 20) {
                    actionList
                }
                .frame(height: 22)
            }
        }
    }

    @ViewBuilder
    private var actionList: some View {
        ForEach(Array(actions.enumerated()), id: \.offset) { index, action in
            if index == 0, usesStatusStyle(action.title) {
                RegisteredButtonView(buttonText: action.title)
            } else {
                FullTextButtonView(buttonText: action.title)
            }
        }
    }

    private func usesStatusStyle(_ title: String) -> Bool {
        let normalized = title.lowercased()
        return normalized.contains("registered") || normalized.contains("scheduled")
    }
}

private func home_feed_parse_date(_ value: String?) -> Date? {
    guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
        return nil
    }

    let formatters = home_feed_supported_date_formatters
    for formatter in formatters {
        if let date = formatter.date(from: value) {
            return date
        }
    }
    return nil
}

private let home_feed_supported_date_formatters: [DateFormatter] = {
    let formats = [
        "d MMMM yyyy",
        "dd MMMM yyyy",
        "yyyy-MM-dd",
        "MMM d, yyyy"
    ]

    return formats.map { format in
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = format
        return formatter
    }
}()
