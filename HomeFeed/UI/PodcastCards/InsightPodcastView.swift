import SwiftUI

struct InsightPodcastView: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View {
        home_feed_media_card_view(item: item, cardType: .insight, container: container)
    }
}

#if DEBUG
struct InsightPodcastView_Previews: PreviewProvider {
    static var previews: some View {
        InsightPodcastView(item: content_card_preview_item.podcast)
            .frame(width: 315, height: 315)
            .previewLayout(.sizeThatFits)
    }
}
#endif
