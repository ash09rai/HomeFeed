import SwiftUI

struct CompactHeightVideoView: View {
    let item: FeedItem

    var body: some View {
        let cardShape = RoundedRectangle(cornerRadius: SystemDesign.CornerRadius.card, style: .continuous)

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                CardTitleLabelView(cardTitle: item.title)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                if item.showImage, (!item.imageURLs.isEmpty || item.imageURL != nil) {
                    CompactHeightDocumentImageView(item: item)
                        .frame(width: 116, height: 67)
                }
            }

            Spacer()
            
            HStack(alignment: .center, spacing: 8) {
                if let publishedDate = item.publishedDate {
                    PublishedDateLabelView(dateText: publishedDate)
                }
                Spacer()
                SaveButton(handler: SaveHandler())
                PlayButtonView(handler: PlayHandler())
            }
            .frame(height: 44)
        }
        .padding([.top, .leading], 16)
        .padding(.trailing, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(SystemDesign.color(.surface), in: cardShape)
        .overlay(
            cardShape
                .stroke(SystemDesign.accent(for: .document).opacity(0.2), lineWidth: SystemDesign.Border.thin)
        )
    }
}

struct CompactHeightVideoView_Previews: PreviewProvider {
    static var previews: some View {
        CompactHeightVideoView(item: content_card_preview_item.video)
            .frame(width: 343, height: 145)
            .previewLayout(.sizeThatFits)
    }
}
