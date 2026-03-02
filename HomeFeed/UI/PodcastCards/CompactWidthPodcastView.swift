import SwiftUI

struct CompactWidthPodcastView: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View {
        home_feed_media_card_view(item: item, cardType: .compactWidth, container: container)
    }
}

#if DEBUG
struct CompactWidthPodcastView_Previews: PreviewProvider {
    static var previews: some View {
        CompactWidthPodcastView(item: content_card_preview_item.podcast)
            .frame(width: 166, height: 278)
            .previewLayout(.sizeThatFits)
    }
}
#endif
