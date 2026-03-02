//
//  PublishedDateLabelView.swift
//  HomeFeed
//
//  Created by Ashish Rai on 26/02/26.
//

import SwiftUI

struct PublishedDateLabelView: View {
    var dateText: String
    @State private var typography: SystemDesign.Typography = .caption
    
    var body: some View {
        Text(dateText)
            .foregroundStyle(SystemDesign.color(typography))
            .font(SystemDesign.font(typography))
            .lineSpacing(SystemDesign.lineSpacing(typography))
            .lineLimit(1)
    }
}

#if DEBUG
#Preview {
    PublishedDateLabelView(dateText: "08 April 2025")
}
#endif
