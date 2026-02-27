//
//  CompactHeightDocumentView.swift
//  HomeFeed
//
//  Created by Ashish Rai on 26/02/26.
//

import SwiftUI

struct CompactHeightDocumentView: View {
    let item: FeedItem

    var body: some View {
        let cardShape = RoundedRectangle(cornerRadius: SystemDesign.CornerRadius.card, style: .continuous)
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                CardTitleLabelView(cardTitle: item.title)
                
                if item.showImage {
                    HomeFeedZoo
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
                .stroke(SystemDesign.accent(for: .conference).opacity(0.2), lineWidth: SystemDesign.Border.thin)
        )
    }
}

struct CompactHeightDocumentView_Previews: PreviewProvider {
    static var previews: some View {
        CompactHeightDocumentView(
            item: .init(
                id: UUID().uuidString,
                contentType: .document,
                title: "Client Webinar: Executive FastStart - How New AI Leaders can Accelerate",
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
                    isRegistered: false,
                    primaryAction: FeedItemAction(title: "Registered"),
                    secondaryAction: FeedItemAction(title: "View Schedule")
                )
            )
        )
        .frame(width: 343, height: 128)
        .previewLayout(.sizeThatFits)
    }
}
