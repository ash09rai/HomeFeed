//
//  CompactHeightConferenceView.swift
//  HomeFeed
//
//  Created by Ashish Rai on 26/02/26.
//

import SwiftUI

struct CompactHeightConferenceView: View {
    let item: FeedItem

    var body: some View {
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
            Spacer()
        }
        .padding(.all, 12)
        .ignoresSafeArea()
    }
}

struct CompactHeightConferenceView_Previews: PreviewProvider {
    static var previews: some View {
        CompactHeightConferenceView(
            item: .init(id: UUID().uuidString, contentType: .conference, title: "IT Symposium/XPO")
        )
        .frame(width: 343, height: 128)
        .previewLayout(.sizeThatFits)
    }
}
