//
//  RegisteredButtonView.swift
//  HomeFeed
//
//  Created by Ashish Rai on 26/02/26.
//

import SwiftUI

struct RegisteredButtonView: View {
    var buttonText: String = "Registered"
    @State private var typography: SystemDesign.Typography = .primaryButton
    
    var body: some View {
        Label {
            Text(buttonText)
                .foregroundStyle(typography.foregroundColor)
                .font(SystemDesign.font(typography))
        } icon: {
            Image(systemName: "calendar.badge")
                .foregroundStyle(typography.foregroundColor)
        }
    }
}

#if DEBUG
#Preview {
    RegisteredButtonView()
}
#endif
