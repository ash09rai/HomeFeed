#if DEBUG
import SwiftUI

private struct feed_section_state_preview_case_view: View {
    let title: String
    let note: String?
    let section: FeedSectionState

    var body: some View {
        VStack(alignment: .leading, spacing: SystemDesign.Spacing.sm) {
            Text(title)
                .font(SystemDesign.font(.sectionTitle))
                .foregroundStyle(SystemDesign.color(.cardTitle))

            if let note {
                Text(note)
                    .font(SystemDesign.font(.caption))
                    .foregroundStyle(SystemDesign.color(.caption))
            }

            FeedSectionStatePreviewView(section: section)
        }
        .padding(SystemDesign.Spacing.xl)
        .background(Color(red: 0.97, green: 0.97, blue: 0.98))
    }
}

private enum feed_section_state_preview_fixture {
    static let loading = FeedSectionState(
        meta: lastActivityMeta,
        state: .loading
    )

    static let loadedMedia = FeedSectionState(
        meta: lastActivityMeta,
        state: .loaded(
            SectionData(items: [
                content_card_preview_item.document,
                content_card_preview_item.video,
                content_card_preview_item.podcast
            ])
        )
    )

    static let loadedEvent = FeedSectionState(
        meta: eventMeta,
        state: .loaded(
            SectionData(items: [
                content_card_preview_item.upcoming_webinar,
                content_card_preview_item.conference
            ])
        )
    )

    static let failed = FeedSectionState(
        meta: failureMeta,
        state: .failed("Unable to refresh this section right now.")
    )

    static let skipped = FeedSectionState(
        meta: failureMeta,
        state: .skipped(.unsupportedLayout)
    )

    private static var lastActivityMeta: SectionMeta {
        SectionMeta(
            id: "preview-last-activity",
            originalOrder: 0,
            rank: 1,
            sectionType: "last_activity",
            endpoint: "http://localhost:3000/lastActivity",
            header: SectionHeaderMeta(
                title: "Continue with",
                subtitle: "Resume where you left off",
                titleColorHex: "#5A5B66",
                subtitleColorHex: "#5A5B66"
            ),
            supportedContents: [.document, .video, .podcast],
            theme: SectionThemeMeta(
                backgroundImageURL: nil,
                primaryColorHex: "#E0F1FF",
                secondaryColorHex: "#E0F1FF"
            ),
            analytics: "last_activity",
            showSection: true,
            groupCount: 1,
            cardCount: 3,
            sectionHeaderCta: SectionCtaMeta(
                actionType: "navigate",
                actionName: "past_activity",
                text: "View More",
                position: "right"
            ),
            footerCta: nil,
            contentHeaderCta: nil,
            contentFooterCta: nil,
            sectionStyle: "single",
            placement: nil,
            containers: [
                ContainerMeta(
                    layout: .horizontalList,
                    cardType: .compactHeight,
                    scrollDirection: .horizontal,
                    showImage: false,
                    cardCount: 3,
                    imagePaginationEnabled: false
                )
            ],
            behaviour: nil,
            declaredParameters: [],
            unknownParameters: []
        )
    }

    private static var eventMeta: SectionMeta {
        SectionMeta(
            id: "preview-events",
            originalOrder: 1,
            rank: 2,
            sectionType: "events_for_you",
            endpoint: "http://localhost:3000/events",
            header: SectionHeaderMeta(
                title: "Events for You",
                subtitle: "Upcoming sessions and conferences",
                titleColorHex: "#1F1F1F",
                subtitleColorHex: "#5A5B66"
            ),
            supportedContents: [.upcomingWebinar, .conference],
            theme: SectionThemeMeta(
                backgroundImageURL: nil,
                primaryColorHex: "#FFF4E6",
                secondaryColorHex: "#F4F8FF"
            ),
            analytics: "events_for_you",
            showSection: true,
            groupCount: 1,
            cardCount: 2,
            sectionHeaderCta: SectionCtaMeta(
                actionType: "navigate",
                actionName: "events_listing",
                text: "Open",
                position: "left"
            ),
            footerCta: SectionCtaMeta(
                actionType: "navigate",
                actionName: "all_events",
                text: "View Schedule",
                position: "right"
            ),
            contentHeaderCta: nil,
            contentFooterCta: nil,
            sectionStyle: "single",
            placement: nil,
            containers: [
                ContainerMeta(
                    layout: .verticalList,
                    cardType: .insight,
                    scrollDirection: .vertical,
                    showImage: false,
                    cardCount: 2,
                    imagePaginationEnabled: false
                )
            ],
            behaviour: nil,
            declaredParameters: [],
            unknownParameters: []
        )
    }

    private static var failureMeta: SectionMeta {
        SectionMeta(
            id: "preview-failure",
            originalOrder: 2,
            rank: 3,
            sectionType: "recommended_for_you",
            endpoint: "http://localhost:3000/recommended",
            header: SectionHeaderMeta(
                title: "Recommended for You",
                subtitle: nil,
                titleColorHex: "#000000",
                subtitleColorHex: nil
            ),
            supportedContents: [.document, .onDemandWebinar],
            theme: SectionThemeMeta(
                backgroundImageURL: nil,
                primaryColorHex: "#FFFFFF",
                secondaryColorHex: "#FFFFFF"
            ),
            analytics: "recommended",
            showSection: true,
            groupCount: 1,
            cardCount: 1,
            sectionHeaderCta: nil,
            footerCta: nil,
            contentHeaderCta: nil,
            contentFooterCta: nil,
            sectionStyle: "single",
            placement: nil,
            containers: [
                ContainerMeta(
                    layout: .verticalList,
                    cardType: .topThumbnail,
                    scrollDirection: .vertical,
                    showImage: true,
                    cardCount: 1,
                    imagePaginationEnabled: false
                )
            ],
            behaviour: nil,
            declaredParameters: [],
            unknownParameters: []
        )
    }
}

struct FeedSectionStateCases_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            feed_section_state_preview_case_view(
                title: "Loading State",
                note: "Skeleton cards reflect configured header, theme, and container count.",
                section: feed_section_state_preview_fixture.loading
            )
            .frame(width: 393)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Loading")

            feed_section_state_preview_case_view(
                title: "Loaded Media Section",
                note: "Horizontal section using compact-height media cards.",
                section: feed_section_state_preview_fixture.loadedMedia
            )
            .frame(width: 393)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Loaded Media")

            feed_section_state_preview_case_view(
                title: "Loaded Event Section",
                note: "Vertical section with gradient theme, left CTA, and footer CTA.",
                section: feed_section_state_preview_fixture.loadedEvent
            )
            .frame(width: 393)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Loaded Event")

            feed_section_state_preview_case_view(
                title: "Failed State",
                note: "Section chrome remains visible while the content shows an error.",
                section: feed_section_state_preview_fixture.failed
            )
            .frame(width: 393)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Failed")

            feed_section_state_preview_case_view(
                title: "Skipped State",
                note: "Skipped sections intentionally render no feed content.",
                section: feed_section_state_preview_fixture.skipped
            )
            .frame(width: 393)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Skipped")
        }
    }
}
#endif
