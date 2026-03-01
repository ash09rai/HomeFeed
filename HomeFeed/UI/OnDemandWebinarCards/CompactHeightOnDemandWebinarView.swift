import SwiftUI

struct CompactHeightOnDemandWebinarView: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View {
        home_feed_media_card_view(item: item, cardType: .compactHeight, container: container)
    }
}

struct CompactHeightOnDemandWebinarView_Previews: PreviewProvider {
    static var previews: some View {
        CompactHeightOnDemandWebinarView(item: content_card_preview_item.on_demand_webinar)
            .frame(width: 343, height: 136)
            .previewLayout(.sizeThatFits)
    }
}
