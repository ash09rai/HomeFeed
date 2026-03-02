import SwiftUI

struct TopThumbnailUpcomingWebinarView: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View {
        home_feed_event_card_view(item: item, cardType: .topThumbnail, container: container)
    }
}

#if DEBUG
struct TopThumbnailUpcomingWebinarView_Previews: PreviewProvider {
    static var previews: some View {
        TopThumbnailUpcomingWebinarView(item: content_card_preview_item.upcoming_webinar)
            .frame(width: 343, height: 241)
            .previewLayout(.sizeThatFits)
    }
}
#endif
