import SwiftUI

struct CompactWidthUpcomingWebinarView: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View {
        home_feed_event_card_view(item: item, cardType: .compactWidth, container: container)
    }
}

#if DEBUG
struct CompactWidthUpcomingWebinarView_Previews: PreviewProvider {
    static var previews: some View {
        CompactWidthUpcomingWebinarView(item: content_card_preview_item.upcoming_webinar)
            .frame(width: 166, height: 278)
            .previewLayout(.sizeThatFits)
    }
}
#endif
