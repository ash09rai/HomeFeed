import SwiftUI

struct TopThumbnailPodcastView: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View {
        home_feed_media_card_view(item: item, cardType: .topThumbnail, container: container)
    }
}

struct TopThumbnailPodcastView_Previews: PreviewProvider {
    static var previews: some View {
        TopThumbnailPodcastView(item: content_card_preview_item.podcast)
            .frame(width: 343, height: 302)
            .previewLayout(.sizeThatFits)
    }
}
