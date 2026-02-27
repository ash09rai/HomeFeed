//
//  InsightVideoView.swift
//  HomeFeed
//
//  Created by Ashish Rai on 26/02/26.
//

import SwiftUI

struct InsightVideoView: View {
    let item: FeedItem

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    InsightVideoView(item: .init(id: UUID().uuidString, contentType: .video, title: "How To Calculate Business Value and Cost for Generative AI Use Case"))
}
