import SwiftUI

struct CompactWidthInquiryView: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View {
        home_feed_event_card_view(item: item, cardType: .compactWidth, container: container)
    }
}

#if DEBUG
struct CompactWidthInquiryView_Previews: PreviewProvider {
    static var previews: some View {
        CompactWidthInquiryView(item: content_card_preview_item.inquiry)
            .frame(width: 166, height: 278)
            .previewLayout(.sizeThatFits)
    }
}
#endif
