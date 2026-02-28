import SwiftUI

struct InsightVideoView: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View {
        insight_video_view(item: item, container: container)
    }
}

#Preview {
    InsightVideoView(item: content_card_preview_item.video)
        .frame(width: 315, height: 315)
        .previewLayout(.sizeThatFits)
}
