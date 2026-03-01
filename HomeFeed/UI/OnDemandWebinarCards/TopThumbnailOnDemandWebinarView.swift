import SwiftUI

struct TopThumbnailOnDemandWebinarView: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View {
        let cardShape = RoundedRectangle(cornerRadius: SystemDesign.CornerRadius.card, style: .continuous)

        VStack(alignment: .leading, spacing: 16) {
            if item.shouldShowImage {
                CompactHeightDocumentImageView(item: item, showRadius: false)
                    .frame(width: .infinity, height: 180)
                    .clipped()
            }
            CardTitleLabelView(cardTitle: item.title)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            if item.shouldShowImage == false, let summary = item.summary, !summary.isEmpty {
                Text(summary)
                    .font(SystemDesign.font(.cardDescription))
                    .foregroundStyle(SystemDesign.color(.cardDescription))
            }

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

struct TopThumbnailOnDemandWebinarView_Previews: PreviewProvider {
    static var previews: some View {
        TopThumbnailOnDemandWebinarView(item: content_card_preview_item.document)
            .frame(width: 343, height: 302)
            .previewLayout(.sizeThatFits)
    }
}
