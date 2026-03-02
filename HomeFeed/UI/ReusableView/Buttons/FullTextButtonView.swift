//
//  FullTextButtonView.swift
//  HomeFeed
//
//  Created by Ashish Rai on 27/02/26.
//

import SwiftUI

struct FullTextButtonView: View {
    var buttonText: String = "View Schedule"
    @State private var typography: SystemDesign.Typography = .secondaryButton
    
    var body: some View {
        Text(buttonText)
            .font(SystemDesign.font(.secondaryButton))
            .foregroundStyle(SystemDesign.color(.secondaryButton))
    }
}

#if DEBUG
#Preview {
    FullTextButtonView()
}
#endif
