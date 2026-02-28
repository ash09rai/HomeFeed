import SwiftUI

struct TopThumbnailVideoView: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View {
        top_thumbnail_video_view(item: item, container: container)
    }
}

#Preview {
    TopThumbnailVideoView(item: content_card_preview_item.video)
        .frame(width: 343, height: 241)
        .previewLayout(.sizeThatFits)
}
