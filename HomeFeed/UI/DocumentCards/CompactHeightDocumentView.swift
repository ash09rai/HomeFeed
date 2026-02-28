import SwiftUI

struct CompactHeightDocumentView: View {
    let item: FeedItem

    var body: some View {
        let cardShape = RoundedRectangle(cornerRadius: SystemDesign.CornerRadius.card, style: .continuous)

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                CardTitleLabelView(cardTitle: item.title)

                if item.showImage {
                    CompactHeightDocumentImageView(item: item)
                }
            }
            Spacer()
            HStack(alignment: .center, spacing: 8) {
                if let publishedDate = item.publishedDate {
                    PublishedDateLabelView(dateText: publishedDate)
                }
                Spacer()
                SaveButton(handler: SaveHandler())
                ListenButtonView(handler: ListenHandler())
            }
            .padding(.bottom, 0)
            .frame(height: 44)
        }
        .padding([.top, .leading, .trailing], 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(SystemDesign.color(.surface), in: cardShape)
        .overlay(
            cardShape
                .stroke(SystemDesign.accent(for: .document).opacity(0.2), lineWidth: SystemDesign.Border.thin)
        )
    }
}

struct CompactHeightDocumentView_Previews: PreviewProvider {
    static var previews: some View {
        CompactHeightDocumentView(item: content_card_preview_item.document)
            .frame(width: 343, height: 128)
            .previewLayout(.sizeThatFits)
    }
}
