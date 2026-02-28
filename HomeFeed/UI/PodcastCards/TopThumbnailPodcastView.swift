import SwiftUI

struct TopThumbnailPodcastView: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View {
        top_thumbnail_podcast_view(item: item, container: container)
    }
}

#Preview {
    TopThumbnailPodcastView(item: content_card_preview_item.podcast)
        .frame(width: 343, height: 241)
        .previewLayout(.sizeThatFits)
}
