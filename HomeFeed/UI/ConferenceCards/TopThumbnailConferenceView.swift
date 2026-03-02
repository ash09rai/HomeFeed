import SwiftUI

struct TopThumbnailConferenceView: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View {
        home_feed_event_card_view(item: item, cardType: .topThumbnail, container: container)
    }
}

#if DEBUG
struct TopThumbnailConferenceView_Previews: PreviewProvider {
    static var previews: some View {
        TopThumbnailConferenceView(item: content_card_preview_item.conference)
            .frame(width: 343, height: 241)
            .previewLayout(.sizeThatFits)
    }
}
#endif
