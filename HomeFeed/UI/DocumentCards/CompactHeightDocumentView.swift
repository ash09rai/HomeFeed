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
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    CompactHeightDocumentView(item: .init(id: UUID().uuidString, contentType: .document, title: "How To Calculate Business Value and Cost for Generative AI Use Case"))
}
