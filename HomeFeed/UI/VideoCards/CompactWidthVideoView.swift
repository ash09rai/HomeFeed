import SwiftUI

struct CompactWidthVideoView: View {
    let item: FeedItem
    let container: ContainerMeta?

    init(item: FeedItem, container: ContainerMeta? = nil) {
        self.item = item
        self.container = container
    }

    var body: some View {
        let cardShape = RoundedRectangle(cornerRadius: SystemDesign.CornerRadius.card, style: .continuous)

        VStack(alignment: .leading, spacing: 12) {
            if item.showImage, (!item.imageURLs.isEmpty || item.imageURL != nil) {
                CompactHeightDocumentImageView(item: item, showRadius: false)
                    .frame(width: .infinity, height: 94)
                    .clipShape(
                        Rectangle().size(width: 166, height: 94)
                    )
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
                PlayButtonView(handler: PlayHandler())
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

struct CompactWidthVideoView_Previews: PreviewProvider {
    static var previews: some View {
        CompactHeightOnDemandWebinarView(item: content_card_preview_item.on_demand_webinar)
            .frame(width: 343, height: 136)
            .previewLayout(.sizeThatFits)
    }
}
