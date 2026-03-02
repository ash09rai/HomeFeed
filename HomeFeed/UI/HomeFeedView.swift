import SwiftUI

public struct HomeFeedView: View {
    @ObservedObject private var viewModel: FeedViewModel
    private let showsSkippedDebug: Bool
    private let imageIntegration: HomeFeedImageIntegration?

    public init(
        viewModel: FeedViewModel,
        showsSkippedDebug: Bool = false,
        imageIntegration: HomeFeedImageIntegration? = nil
    ) {
        self.viewModel = viewModel
        self.showsSkippedDebug = showsSkippedDebug
        self.imageIntegration = imageIntegration
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: SystemDesign.Spacing.xl) {
                if viewModel.sections.isEmpty && viewModel.isLoading {
                    Text("Loading")
                        .font(SystemDesign.font(.cardContentType))
                        .foregroundStyle(SystemDesign.color(.cardContentType))
                        .redacted(reason: .placeholder)
                }

                ForEach(viewModel.sections) { section in
                    section_view(section: section)
                }

                if showsSkippedDebug {
                    ForEach(viewModel.skippedSections) { skipped in
                        if case let .skipped(reason) = skipped.state {
                            Text("Skipped \(skipped.meta.sectionType): \(reason.rawValue)")
                                .font(SystemDesign.font(.caption))
                                .foregroundStyle(SystemDesign.color(.cardContentType))
                        }
                    }
                }
            }
            .padding(SystemDesign.Spacing.xl)
        }
        .homeFeedImageIntegration(imageIntegration)
        .onAppear { viewModel.loadIfNeeded() }
    }
}

private struct section_view: View {
    let section: FeedSectionState

    var body: some View {
        switch section.state {
        case .skipped:
            EmptyView()
        default:
            section_chrome_view(meta: section.meta) {
                switch section.state {
                case .idle, .loading:
                    loading_section_content_view(meta: section.meta)
                case let .failed(message):
                    failed_section_content_view(message: message)
                case let .loaded(data):
                    loaded_section_content_view(meta: section.meta, data: data)
                case .skipped:
                    EmptyView()
                }
            }
        }
    }
}

private struct loading_section_content_view: View {
    let meta: SectionMeta

    var body: some View {
        VStack(alignment: .leading, spacing: SystemDesign.Spacing.md) {
            ForEach(Array(meta.containers.enumerated()), id: \.offset) { _, container in
                loading_container_list_view(
                    container: container,
                    placeholderCount: placeholderCount(for: container)
                )
            }
        }
        .accessibilityHidden(true)
    }

    private func placeholderCount(for container: ContainerMeta) -> Int {
        let requestedCount = container.cardCount ?? meta.cardCount ?? 2
        return min(max(requestedCount, 1), 3)
    }
}

private struct failed_section_content_view: View {
    let message: String

    var body: some View {
        Text(message)
            .font(SystemDesign.font(.caption))
            .foregroundStyle(SystemDesign.color(.caption))
    }
}

private struct loaded_section_content_view: View {
    let meta: SectionMeta
    let data: SectionData

    var body: some View {
        VStack(alignment: .leading, spacing: SystemDesign.Spacing.md) {
            ForEach(Array(meta.containers.enumerated()), id: \.offset) { _, container in
                container_list_view(container: container, items: data.items)
            }
        }
    }
}

private struct section_chrome_view<Content: View>: View {
    let meta: SectionMeta
    let content: () -> Content

    init(meta: SectionMeta, @ViewBuilder content: @escaping () -> Content) {
        self.meta = meta
        self.content = content
    }

    private var footerAlignment: Alignment {
        guard let position = meta.preferredFooterCta?.position?.lowercased() else {
            return .trailing
        }
        return position == "left" ? .leading : .trailing
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: SystemDesign.CornerRadius.card, style: .continuous)

        VStack(alignment: .leading, spacing: SystemDesign.Spacing.md) {
            section_header_row_view(meta: meta)
            content()
            if let footerCta = meta.preferredFooterCta {
                section_cta_label_view(cta: footerCta)
                    .frame(maxWidth: .infinity, alignment: footerAlignment)
            }
        }
        .padding(SystemDesign.Spacing.xl)
        .background(
            section_background_fill_view(meta: meta)
                .clipShape(shape)
        )
        .overlay(
            shape.stroke(SystemDesign.color(.border), lineWidth: SystemDesign.Border.thin)
        )
    }
}

private struct section_header_row_view: View {
    let meta: SectionMeta

    private var headerCta: SectionCtaMeta? {
        meta.sectionHeaderCta?.trimmedText == nil ? nil : meta.sectionHeaderCta
    }

    private var titleColor: Color {
        SystemDesign.color(hex: meta.header?.titleColorHex, fallback: SystemDesign.color(.sectionTitle))
    }

    private var subtitleColor: Color {
        SystemDesign.color(hex: meta.header?.subtitleColorHex, fallback: SystemDesign.color(.caption))
    }

    private var ctaOnLeft: Bool {
        headerCta?.position?.lowercased() == "left"
    }

    var body: some View {
        HStack(alignment: .top, spacing: SystemDesign.Spacing.md) {
            if ctaOnLeft, let headerCta {
                section_cta_label_view(cta: headerCta)
            }

            VStack(alignment: .leading, spacing: SystemDesign.Spacing.xxs) {
                Text(meta.displayTitle)
                    .font(SystemDesign.font(.sectionTitle))
                    .foregroundStyle(titleColor)

                if let subtitle = meta.displaySubtitle {
                    Text(subtitle)
                        .font(SystemDesign.font(.caption))
                        .foregroundStyle(subtitleColor)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)

            if !ctaOnLeft, let headerCta {
                section_cta_label_view(cta: headerCta)
            }
        }
    }
}

private struct section_cta_label_view: View {
    let cta: SectionCtaMeta

    var body: some View {
        if let text = cta.trimmedText {
            Text(text)
                .font(SystemDesign.font(.secondaryButton))
                .foregroundStyle(SystemDesign.color(.secondaryButton))
                .lineLimit(1)
        }
    }
}

private struct section_background_fill_view: View {
    let meta: SectionMeta

    private var backgroundURL: URL? {
        guard let rawValue = meta.theme?.backgroundImageURL?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawValue.isEmpty else {
            return nil
        }
        return URL(string: rawValue)
    }

    private var primaryColor: Color {
        SystemDesign.color(hex: meta.theme?.primaryColorHex, fallback: SystemDesign.color(.surface))
    }

    private var secondaryColor: Color {
        SystemDesign.color(hex: meta.theme?.secondaryColorHex, fallback: primaryColor)
    }

    private var backgroundColors: [Color] {
        if meta.theme == nil {
            return [SystemDesign.color(.surface)]
        }

        if usesGradient {
            return [primaryColor.opacity(0.16), secondaryColor.opacity(0.16)]
        }

        return [primaryColor.opacity(0.12)]
    }

    private var usesGradient: Bool {
        normalizedHex(meta.theme?.primaryColorHex) != normalizedHex(meta.theme?.secondaryColorHex)
    }

    var body: some View {
        ZStack {
            if usesGradient {
                LinearGradient(
                    colors: backgroundColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                backgroundColors[0]
            }

            if let backgroundURL {
                AsyncImage(url: backgroundURL) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                            .opacity(0.18)
                    default:
                        EmptyView()
                    }
                }
            }
        }
    }

    private func normalizedHex(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        return value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
            .uppercased()
    }
}

private struct loading_container_list_view: View {
    let container: ContainerMeta
    let placeholderCount: Int

    private var gridItems: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: SystemDesign.Spacing.md, alignment: .top),
            count: max(container.columns ?? 2, 1)
        )
    }

    var body: some View {
        if container.layout == .horizontalList {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: SystemDesign.Spacing.md) {
                    ForEach(0..<placeholderCount, id: \.self) { _ in
                        loading_card_placeholder_view(container: container)
                    }
                }
            }
        } else if container.layout == .grid {
            LazyVGrid(columns: gridItems, alignment: .leading, spacing: SystemDesign.Spacing.md) {
                ForEach(0..<placeholderCount, id: \.self) { _ in
                    loading_card_placeholder_view(container: container)
                }
            }
        } else {
            LazyVStack(alignment: .leading, spacing: SystemDesign.Spacing.md) {
                ForEach(0..<placeholderCount, id: \.self) { _ in
                    loading_card_placeholder_view(container: container)
                }
            }
        }
    }
}

private struct container_list_view: View {
    let container: ContainerMeta
    let items: [FeedItem]

    private var gridItems: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: SystemDesign.Spacing.md, alignment: .top),
            count: max(container.columns ?? 2, 1)
        )
    }

    var body: some View {
        if container.layout == .horizontalList {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: SystemDesign.Spacing.md) {
                    ForEach(items) { item in
                        card_type_content_type_view(cardType: container.cardType, item: item, container: container)
                    }
                }
            }
        } else if container.layout == .grid {
            LazyVGrid(columns: gridItems, alignment: .leading, spacing: SystemDesign.Spacing.md) {
                ForEach(items) { item in
                    card_type_content_type_view(cardType: container.cardType, item: item, container: container)
                }
            }
        } else {
            LazyVStack(alignment: .leading, spacing: SystemDesign.Spacing.md) {
                ForEach(items) { item in
                    card_type_content_type_view(cardType: container.cardType, item: item, container: container)
                }
            }
        }
    }
}

private struct loading_card_placeholder_view: View {
    let container: ContainerMeta

    var body: some View {
        let metrics = loading_card_metrics(container: container)

        VStack(alignment: .leading, spacing: SystemDesign.Spacing.sm) {
            if container.showImage {
                RoundedRectangle(cornerRadius: SystemDesign.CornerRadius.imageCornerRadius)
                    .fill(SystemDesign.color(.imagePlaceholder))
                    .frame(height: metrics.imageHeight)
            }

            RoundedRectangle(cornerRadius: SystemDesign.CornerRadius.pill)
                .fill(SystemDesign.color(.imagePlaceholder))
                .frame(width: metrics.primaryLineWidth, height: 12)

            RoundedRectangle(cornerRadius: SystemDesign.CornerRadius.pill)
                .fill(SystemDesign.color(.imagePlaceholder))
                .frame(width: metrics.secondaryLineWidth, height: 12)
        }
        .padding(SystemDesign.Spacing.md)
        .frame(maxWidth: container.layout == .horizontalList ? nil : .infinity, alignment: .leading)
        .frame(width: metrics.width, alignment: .topLeading)
        .frame(minHeight: metrics.minHeight, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: SystemDesign.CornerRadius.card)
                .fill(SystemDesign.color(.surface))
        )
        .overlay(
            RoundedRectangle(cornerRadius: SystemDesign.CornerRadius.card)
                .stroke(SystemDesign.color(.border), lineWidth: SystemDesign.Border.thin)
        )
    }
}

private struct loading_card_metrics {
    let width: CGFloat?
    let minHeight: CGFloat
    let imageHeight: CGFloat
    let primaryLineWidth: CGFloat
    let secondaryLineWidth: CGFloat

    init(container: ContainerMeta) {
        let resolvedWidth: CGFloat? = container.layout == .horizontalList
            ? loading_card_metrics.placeholderWidth(for: container.cardType)
            : nil

        self.width = resolvedWidth

        switch container.cardType {
        case .compactHeight:
            minHeight = SystemDesign.CardMetrics.compactHeightMinHeight
            imageHeight = 52
            primaryLineWidth = 118
            secondaryLineWidth = 84
        case .compactWidth:
            minHeight = SystemDesign.CardMetrics.compactWidthMinHeight
            imageHeight = 72
            primaryLineWidth = 104
            secondaryLineWidth = 76
        case .topThumbnail:
            minHeight = SystemDesign.CardMetrics.topThumbnailMinHeight
            imageHeight = 92
            primaryLineWidth = 132
            secondaryLineWidth = 96
        case .insight:
            minHeight = SystemDesign.CardMetrics.insightMinHeight
            imageHeight = 68
            primaryLineWidth = 144
            secondaryLineWidth = 104
        default:
            minHeight = SystemDesign.CardMetrics.fallbackMinHeight
            imageHeight = 64
            primaryLineWidth = 120
            secondaryLineWidth = 88
        }
    }

    private static func placeholderWidth(for cardType: CardType) -> CGFloat {
        switch cardType {
        case .compactHeight:
            return SystemDesign.CardMetrics.compactHeightWidth
        case .compactWidth:
            return SystemDesign.CardMetrics.compactWidthWidth
        default:
            return SystemDesign.CardMetrics.compactHeightWidth
        }
    }
}

struct FeedSectionStatePreviewView: View {
    let section: FeedSectionState

    var body: some View {
        switch section.state {
        case .skipped:
            Text("Skipped sections intentionally render no UI.")
                .font(SystemDesign.font(.caption))
                .foregroundStyle(SystemDesign.color(.caption))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(SystemDesign.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: SystemDesign.CornerRadius.card)
                        .fill(SystemDesign.color(.imagePlaceholder))
                )
        default:
            section_view(section: section)
        }
    }
}
