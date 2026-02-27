//
//  ListenButtonView.swift
//  HomeFeed
//
//  Created by Ashish Rai on 26/02/26.
//

import SwiftUI

// 1. Define the abstraction (Dependency Inversion)
protocol ListenButtonHandler {
    func listenContent()
}

// 2. Concrete implementation for production
class ListenHandler: ListenButtonHandler {
    func listenContent() {
        print("Production action triggered")
    }
}

// 3. View with injected dependency
struct ListenButtonView: View {
    // We only know about the abstraction, not the implementation
    let handler: ListenButtonHandler

    var body: some View {
        Button {
            handler.listenContent()
        } label: {
            Image(systemName: "headphones.over.ear")
                .scaledToFit()
                .foregroundStyle(SystemDesign.buttonForegroundColor)
                .imageScale(.large)
                .frame(width: SystemDesign.buttonSize.width, height: SystemDesign.buttonSize.height)
        }

    }
}

#Preview {
    ListenButtonView(handler: ListenHandler())
}
