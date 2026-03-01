import SwiftUI

struct TopThumbnailVideoView: View {
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

struct TopThumbnailVideoView_Previews: PreviewProvider {
    static var previews: some View {
        TopThumbnailVideoView(item: content_card_preview_item.video)
            .frame(width: 343, height: 302)
            .previewLayout(.sizeThatFits)
    }
}
