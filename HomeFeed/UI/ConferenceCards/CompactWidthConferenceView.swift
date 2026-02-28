import SwiftUI

struct CompactWidthConferenceView: View {
    let item: FeedItem

    private var dateText: String? {
        if
            let startDate = item.eventStartDate,
            let endDate = item.eventEndDate,
            !endDate.isEmpty,
            endDate != startDate
        {
            return "\(startDate) - \(endDate)"
        }

        if let startDate = item.eventStartDate, !startDate.isEmpty {
            return startDate
        }

        return nil
    }

    var body: some View {
        let cardShape = RoundedRectangle(cornerRadius: SystemDesign.CornerRadius.card, style: .continuous)

        VStack(alignment: .leading, spacing: 8) {
            CalendarView()
                .frame(width: 58, height: 58)
                .padding(.bottom, 16)

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

            Spacer()
            VStack(alignment: .leading) {
                RegisteredButtonView()
                FullTextButtonView()
                    .frame(height: 22)
            }
            .padding(.bottom, 0)
        }
        .padding(.all, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(SystemDesign.color(.surface), in: cardShape)
        .overlay(
            cardShape
                .stroke(SystemDesign.accent(for: .conference).opacity(0.2), lineWidth: SystemDesign.Border.thin)
        )
    }
}

struct CompactWidthConferenceView_Previews: PreviewProvider {
    static var previews: some View {
        CompactWidthConferenceView(item: content_card_preview_item.conference)
            .frame(width: 166, height: 278)
            .previewLayout(.sizeThatFits)
    }
}
