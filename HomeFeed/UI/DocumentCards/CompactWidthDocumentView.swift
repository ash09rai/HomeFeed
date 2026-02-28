import SwiftUI

struct CompactWidthDocumentView: View {
    let item: FeedItem

    var body: some View {
        let cardShape = RoundedRectangle(cornerRadius: SystemDesign.CornerRadius.card, style: .continuous)

        VStack(alignment: .leading, spacing: 12) {
            if item.showImage, (!item.imageURLs.isEmpty || item.imageURL != nil) {
                CompactHeightDocumentImageView(item: item, showRadius: false)
                    .frame(width: .infinity, height: 94)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                CardTitleLabelView(cardTitle: item.title)
                
                if let publishedDate = item.publishedDate, !publishedDate.isEmpty {
                    PublishedDateLabelView(dateText: publishedDate)
                }
            }
            .padding(.horizontal, 12)

            Spacer()
            HStack(spacing: 8) {
                SaveButton(handler: SaveHandler(), )
                ListenButtonView(handler: ListenHandler())
                Spacer()
            }
            .padding(.bottom, 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(SystemDesign.color(.surface), in: cardShape)
        .overlay(
            cardShape
                .stroke(SystemDesign.accent(for: .conference).opacity(0.2), lineWidth: SystemDesign.Border.thin)
        )
    }
}

struct CompactWidthDocumentView_Previews: PreviewProvider {
    static var previews: some View {
        CompactWidthDocumentView(item: content_card_preview_item.document)
            .frame(width: 166, height: 278)
            .previewLayout(.sizeThatFits)
    }
}
