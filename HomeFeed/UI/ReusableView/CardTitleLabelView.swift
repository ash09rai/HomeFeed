//
//  CardTitleLabelView.swift
//  HomeFeed
//
//  Created by Ashish Rai on 26/02/26.
//

import SwiftUI

struct CardTitleLabelView: View {
    var cardTitle: String
    @State private var typography: SystemDesign.Typography = .cardTitle
    
    var body: some View {
        Text(cardTitle)
            .foregroundStyle(SystemDesign.color(typography))
            .font(SystemDesign.font(typography))
            .lineSpacing(SystemDesign.lineSpacing(typography))
            .lineLimit(3)
    }
}

#Preview {
    CardTitleLabelView(cardTitle: "Client Webinar: Managing Generative AI's Impact on Endpoint Management")
}
