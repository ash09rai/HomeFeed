//
//  RegisteredButtonView.swift
//  HomeFeed
//
//  Created by Ashish Rai on 26/02/26.
//

import SwiftUI

struct RegisteredButtonView: View {
    @State private var typography: SystemDesign.Typography = .primaryButton
    
    var body: some View {
        Label {
            Text("Registered")
                .foregroundStyle(typography.foregroundColor)
                .font(SystemDesign.font(typography))
        } icon: {
            Image(systemName: "calendar.badge")
                .foregroundStyle(typography.foregroundColor)
        }
    }
}

#Preview {
    RegisteredButtonView()
}
