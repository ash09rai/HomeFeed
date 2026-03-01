import SwiftUI

struct InsightDocumentView: View {
    let item: FeedItem

    var body: some View {
        let cardShape = RoundedRectangle(cornerRadius: SystemDesign.CornerRadius.card, style: .continuous)

        VStack(alignment: .leading, spacing: 16) {
            if item.showImage, (!item.imageURLs.isEmpty || item.imageURL != nil) {
                CompactHeightDocumentImageView(item: item, showRadius: false)
                    .frame(width: .infinity, height: 180)
                    .clipped()
            }
            CardTitleLabelView(cardTitle: item.title)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)


            HStack(spacing: 8) {
                if let publishedDate = item.publishedDate, !publishedDate.isEmpty {
                    PublishedDateLabelView(dateText: publishedDate)
                }
                Spacer()
                SaveButton(handler: SaveHandler(), )
                ListenButtonView(handler: ListenHandler())
            }
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(SystemDesign.color(.surface), in: cardShape)
        .overlay(
            cardShape
                .stroke(SystemDesign.accent(for: .conference).opacity(0.2), lineWidth: SystemDesign.Border.thin)
        )
    }
}

struct InsightDocumentView_Previews: PreviewProvider {
    static var previews: some View {
        InsightDocumentView(item: content_card_preview_item.document)
            .frame(width: 315, height: 315)
            .previewLayout(.sizeThatFits)
    }
}
