//
//  CompactHeightUpcomingWebinarView.swift
//  HomeFeed
//
//  Created by Ashish Rai on 26/02/26.
//

import SwiftUI

struct CompactHeightUpcomingWebinarView: View {
    let item: FeedItem

    var body: some View {
        let cardShape = RoundedRectangle(cornerRadius: SystemDesign.CornerRadius.card, style: .continuous)

        HStack(alignment: .top, spacing: 12) {
            CalendarView()
                .frame(width: 70, height: 70)
            
            VStack(alignment: .leading, spacing: 4) {
                ContentLabel(contentType: item.contentType)
                    .frame(height: 16)
                CardTitleLabelView(cardTitle: item.title)
                Text(item.eventLocation ?? "")
                    .font(SystemDesign.font(.location))
                    .foregroundStyle(SystemDesign.color(.location))
                    .frame(height: 19)
                
                HStack(spacing: 20) {
                    RegisteredButtonView()
                    FullTextButtonView()
                }
                .padding(.top, 12)
                .frame(height: 22)
            }
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

struct CompactHeightUpcomingWebinarView_Previews: PreviewProvider {
    static var previews: some View {
        CompactHeightUpcomingWebinarView(
            item: .init(
                id: UUID().uuidString,
                contentType: .upcomingWebinar,
                title: "Emerging Risks in 2026",
                behaviour: FeedItemBehaviour(
                    summary: nil,
                    media: FeedItemMedia(),
                    schedule: FeedItemSchedule(
                        eventStartDate: "8 Jan 2026",
                        eventTime: "9:00 AM - 10:00 AM EDT",
                        eventLocation: "Barcelona, Spain",
                        displayTimeZone: nil
                    ),
                    statusText: "Registered",
                    isRegistered: true,
                    primaryAction: FeedItemAction(title: "Registered"),
                    secondaryAction: FeedItemAction(title: "View Schedule")
                )
            )
        )
        .frame(width: 343, height: 128)
        .previewLayout(.sizeThatFits)
    }
}
