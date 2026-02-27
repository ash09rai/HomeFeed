import SwiftUI

public struct HomeFeedView: View {
    @ObservedObject private var viewModel: HomeFeedViewModel
    private let showsSkippedDebug: Bool

    public init(viewModel: HomeFeedViewModel, showsSkippedDebug: Bool = false) {
        self.viewModel = viewModel
        self.showsSkippedDebug = showsSkippedDebug
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
        .onAppear { viewModel.loadIfNeeded() }
    }
}

private struct section_view: View {
    let section: FeedSectionState

    var body: some View {
        switch section.state {
        case .idle, .loading:
            Text(section.meta.sectionType)
                .font(SystemDesign.font(.sectionTitle))
                .foregroundStyle(SystemDesign.color(.sectionTitle))
                .redacted(reason: .placeholder)
        case let .failed(message):
            VStack(alignment: .leading, spacing: SystemDesign.Spacing.xs) {
                Text(section.meta.sectionType)
                    .font(SystemDesign.font(.sectionTitle))
                Text(message)
                    .font(SystemDesign.font(.sectionTitle))
                    .foregroundStyle(SystemDesign.color(.sectionTitle))
            }
        case let .loaded(data):
            loaded_section_view(meta: section.meta, data: data)
        case .skipped:
            EmptyView()
        }
    }
}

private struct loaded_section_view: View {
    let meta: SectionMeta
    let data: SectionData

    var body: some View {
        VStack(alignment: .leading, spacing: SystemDesign.Spacing.md) {
            Text(meta.sectionType.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(SystemDesign.font(.sectionTitle))
                .foregroundStyle(SystemDesign.color(.cardTitle))

            ForEach(Array(meta.containers.enumerated()), id: \.offset) { _, container in
                container_list_view(container: container, items: data.items)
            }
        }
    }
}

private struct container_list_view: View {
    let container: ContainerMeta
    let items: [FeedItem]

    var body: some View {
        if container.layout == .horizontalList {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: SystemDesign.Spacing.md) {
                    ForEach(items) { item in
                        card_type_content_type_view(cardType: container.cardType, item: item, container: container)
                    }
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
