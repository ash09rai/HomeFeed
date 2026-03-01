import SwiftUI

struct InsightUpcomingWebinarView: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View {
        home_feed_event_card_view(item: item, cardType: .insight, container: container)
    }
}

struct InsightUpcomingWebinarView_Previews: PreviewProvider {
    static var previews: some View {
        InsightUpcomingWebinarView(item: content_card_preview_item.upcoming_webinar)
            .frame(width: 315, height: 315)
            .previewLayout(.sizeThatFits)
    }
}
