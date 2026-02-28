import SwiftUI

struct CompactHeightPodcastView: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View {
        compact_height_podcast_view(item: item, container: container)
    }
}

#Preview {
    CompactHeightPodcastView(item: content_card_preview_item.podcast)
        .frame(width: 343, height: 128)
        .previewLayout(.sizeThatFits)
}
