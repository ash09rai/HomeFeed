import SwiftUI

struct CompactHeightInquiryView: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View {
        home_feed_event_card_view(item: item, cardType: .compactHeight, container: container)
    }
}

#if DEBUG
struct CompactHeightInquiryView_Previews: PreviewProvider {
    static var previews: some View {
        CompactHeightInquiryView(item: content_card_preview_item.inquiry)
            .frame(width: 343, height: 128)
            .previewLayout(.sizeThatFits)
    }
}
#endif
