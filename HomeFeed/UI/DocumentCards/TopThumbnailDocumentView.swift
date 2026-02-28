import SwiftUI

struct TopThumbnailDocumentView: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View {
        top_thumbnail_document_view(item: item, container: container)
    }
}

#Preview {
    TopThumbnailDocumentView(item: content_card_preview_item.document)
        .frame(width: 343, height: 241)
        .previewLayout(.sizeThatFits)
}
