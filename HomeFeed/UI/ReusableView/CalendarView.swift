//
//  CalendarView.swift
//  HomeFeed
//
//  Created by Ashish Rai on 27/02/26.
//

import SwiftUI

struct CalendarView: View {
    var startDate: Date?
    var endDate: Date?
    
    var body: some View {
        ZStack {
            Color(red: 0, green: 40/255, blue: 105/255)
            calendarView
                .overlay(
                    RoundedRectangle(cornerRadius: 6) // Use the same corner radius for the border
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .init(red: 184/255, green: 222/255, blue: 1.0),
                                    .init(red: 31/255, green: 150/255, blue: 1.0),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .padding(.all, 6)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    
    
    var calendarView: some View {
        ZStack(alignment: .center) {
            VStack(alignment: .center) {
                Text("Jan")
                    .font(SystemDesign.font(SystemDesign.Typography.dateMonth))
                    .foregroundStyle(Color.white)
                Text("8")
                    .font(SystemDesign.font(SystemDesign.Typography.dateDay))
                    .foregroundStyle(Color.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
            .frame(width: 70, height: 70)
            .previewLayout(.sizeThatFits)
    }
}
