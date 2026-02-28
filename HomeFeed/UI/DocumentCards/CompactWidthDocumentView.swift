import SwiftUI

struct CompactWidthDocumentView: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View {
        compact_width_document_view(item: item, container: container)
    }
}

#Preview {
    CompactWidthDocumentView(item: content_card_preview_item.document)
        .frame(width: 166, height: 278)
        .previewLayout(.sizeThatFits)
}
