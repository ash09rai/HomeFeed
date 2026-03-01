import SwiftUI

struct InsightConferenceView: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View {
        home_feed_event_card_view(item: item, cardType: .insight, container: container)
    }
}

struct InsightConferenceView_Previews: PreviewProvider {
    static var previews: some View {
        InsightConferenceView(item: content_card_preview_item.conference)
            .frame(width: 315, height: 315)
            .previewLayout(.sizeThatFits)
    }
}
