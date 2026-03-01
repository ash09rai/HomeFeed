//
//  ContentLabel.swift
//  HomeFeed
//
//  Created by Ashish Rai on 27/02/26.
//

import SwiftUI

struct ContentLabel: View {
    @State var contentType: ContentType
    @State private var typography: SystemDesign.Typography = .cardContentType

    private var displayText: String {
        switch contentType {
        case .document:
            return "Document"
        case .onDemandWebinar:
            return "On-Demand Webinar"
        case .upcomingWebinar:
            return "Upcoming Webinar"
        case .video:
            return "Video"
        case .podcast:
            return "Podcast"
        case .inquiry:
            return "Inquiry"
        case .conference:
            return "Conference"
        default:
            return contentType.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    var body: some View {
        Text(displayText)
            .font(SystemDesign.font(typography))
            .foregroundStyle(SystemDesign.color(typography))
    }
}

#Preview {
    ContentLabel(contentType: .audio)
}
