import SwiftUI

struct CompactWidthPodcastView: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View {
        compact_width_podcast_view(item: item, container: container)
    }
}

#Preview {
    CompactWidthPodcastView(item: content_card_preview_item.podcast)
        .frame(width: 166, height: 278)
        .previewLayout(.sizeThatFits)
}
