import SwiftUI

struct InsightPodcastView: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View {
        insight_podcast_view(item: item, container: container)
    }
}

#Preview {
    InsightPodcastView(item: content_card_preview_item.podcast)
        .frame(width: 315, height: 315)
        .previewLayout(.sizeThatFits)
}
