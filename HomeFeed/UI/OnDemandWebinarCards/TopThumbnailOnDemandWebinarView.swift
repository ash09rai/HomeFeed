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

struct TopThumbnailOnDemandWebinarView_Previews: PreviewProvider {
    static var previews: some View {
        TopThumbnailOnDemandWebinarView(item: content_card_preview_item.document)
            .frame(width: 343, height: 302)
            .previewLayout(.sizeThatFits)
    }
}
