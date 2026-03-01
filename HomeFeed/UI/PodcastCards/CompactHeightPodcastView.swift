import SwiftUI

struct CompactHeightPodcastView: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View {
        home_feed_media_card_view(item: item, cardType: .compactHeight, container: container)
    }
}

struct CompactHeightPodcastView_Previews: PreviewProvider {
    static var previews: some View {
        CompactHeightPodcastView(item: content_card_preview_item.podcast)
            .frame(width: 343, height: 136)
            .previewLayout(.sizeThatFits)
    }
}
