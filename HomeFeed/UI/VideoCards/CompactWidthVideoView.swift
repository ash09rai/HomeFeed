import SwiftUI

struct CompactWidthVideoView: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View {
        home_feed_media_card_view(item: item, cardType: .compactWidth, container: container)
    }
}

#if DEBUG
struct CompactWidthVideoView_Previews: PreviewProvider {
    static var previews: some View {
        CompactWidthVideoView(item: content_card_preview_item.video)
            .frame(width: 166, height: 278)
            .previewLayout(.sizeThatFits)
    }
}
#endif
