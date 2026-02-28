import SwiftUI

struct TopThumbnailOnDemandWebinarView: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View {
        top_thumbnail_on_demand_webinar_view(item: item, container: container)
    }
}

#Preview {
    TopThumbnailOnDemandWebinarView(item: content_card_preview_item.on_demand_webinar)
        .frame(width: 343, height: 241)
        .previewLayout(.sizeThatFits)
}
