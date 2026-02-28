import SwiftUI

struct InsightDocumentView: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View {
        insight_document_view(item: item, container: container)
    }
}

#Preview {
    InsightDocumentView(item: content_card_preview_item.document)
        .frame(width: 315, height: 315)
        .previewLayout(.sizeThatFits)
}
