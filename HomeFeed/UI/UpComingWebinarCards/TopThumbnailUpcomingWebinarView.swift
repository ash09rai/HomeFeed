//
//  TopThumbnailUpcomingWebinarView.swift
//  HomeFeed
//
//  Created by Ashish Rai on 26/02/26.
//

import SwiftUI

struct TopThumbnailUpcomingWebinarView: View {
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
                .stroke(.white, lineWidth: SystemDesign.Border.thin)
        )
    }
}

struct TopThumbnailUpcomingWebinarView_Previews: PreviewProvider {
    static var previews: some View {
        TopThumbnailUpcomingWebinarView(
            item: .init(
                id: UUID().uuidString,
                contentType: .upcomingWebinar,
                title: "Emerging Risks in 2026",
                behaviour: FeedItemBehaviour(
                    summary: "This webinar will review our latest benchmarking on emerging risks for 2026 and provide executives with best practices for actionable trend analysis and scenario planning.This webinar will review our latest benchmarking on emerging risks for 2026 and provide executives with best practices for actionable trend analysis and scenario planning.",
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
        .frame(width: 343, height: 241)
        .previewLayout(.sizeThatFits)
    }
}
