import SwiftUI

struct CompactWidthVideoView: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View {
        compact_width_video_view(item: item, container: container)
    }
}

#Preview {
    CompactWidthVideoView(item: content_card_preview_item.video)
        .frame(width: 166, height: 278)
        .previewLayout(.sizeThatFits)
}
