import SwiftUI

struct InsightOnDemandWebinarView: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View {
        insight_on_demand_webinar_view(item: item, container: container)
    }
}

#Preview {
    InsightOnDemandWebinarView(item: content_card_preview_item.on_demand_webinar)
        .frame(width: 315, height: 315)
        .previewLayout(.sizeThatFits)
}
