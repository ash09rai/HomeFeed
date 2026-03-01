import SwiftUI

struct TopThumbnailInquiryView: View {
    let item: FeedItem

    var body: some View {
        let cardShape = RoundedRectangle(cornerRadius: SystemDesign.CornerRadius.card, style: .continuous)

        HStack(alignment: .top, spacing: 8) {
            CalendarView()
                .frame(width: 70, height: 70)

            VStack(alignment: .leading, spacing: 8) {
                ContentLabel(contentType: item.contentType)
                    .frame(height: 16)

                CardTitleLabelView(cardTitle: item.title)

                if let location = item.eventLocation, !location.isEmpty {
                    Text(location)
                        .font(SystemDesign.font(.location))
                        .foregroundStyle(SystemDesign.color(.location))
                }

                if let eventTime = item.eventTime, !eventTime.isEmpty {
                    Text(eventTime)
                        .font(SystemDesign.font(.location))
                        .foregroundStyle(SystemDesign.color(.location))
                }

                if let eventSummary = item.summary, !eventSummary.isEmpty {
                    Text(eventSummary)
                        .font(SystemDesign.font(.cardDescription))
                        .foregroundStyle(SystemDesign.color(.cardDescription))
                }

                Spacer()
                HStack(spacing: 20) {
                    RegisteredButtonView()
                    FullTextButtonView()
                        .frame(height: 22)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(.all, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(SystemDesign.color(.surface), in: cardShape)
        .overlay(
            cardShape
                .stroke(SystemDesign.accent(for: .conference).opacity(0.2), lineWidth: SystemDesign.Border.thin)
        )
    }
}

struct TopThumbnailInquiryView_Previews: PreviewProvider {
    static var previews: some View {
        TopThumbnailInquiryView(item: content_card_preview_item.inquiry)
            .frame(width: 343, height: 241)
            .previewLayout(.sizeThatFits)
    }
}
