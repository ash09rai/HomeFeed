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
    
    var body: some View {
        Text(contentType.rawValue)
            .font(SystemDesign.font(typography))
            .foregroundStyle(SystemDesign.color(typography))
    }
}

#Preview {
    ContentLabel(contentType: .audio)
}
