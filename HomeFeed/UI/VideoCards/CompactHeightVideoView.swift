import SwiftUI

struct CompactHeightVideoView: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View {
        compact_height_video_view(item: item, container: container)
    }
}

#Preview {
    CompactHeightVideoView(item: content_card_preview_item.video)
        .frame(width: 343, height: 128)
        .previewLayout(.sizeThatFits)
}
