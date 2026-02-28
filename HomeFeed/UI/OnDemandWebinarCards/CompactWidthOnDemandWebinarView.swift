import SwiftUI

struct CompactWidthOnDemandWebinarView: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View {
        compact_width_on_demand_webinar_view(item: item, container: container)
    }
}

#Preview {
    CompactWidthOnDemandWebinarView(item: content_card_preview_item.on_demand_webinar)
        .frame(width: 166, height: 278)
        .previewLayout(.sizeThatFits)
}
