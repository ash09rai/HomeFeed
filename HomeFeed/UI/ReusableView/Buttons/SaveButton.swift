//
//  SaveButton.swift
//  HomeFeed
//
//  Created by Ashish Rai on 26/02/26.
//

import SwiftUI

// 1. Define the abstraction (Dependency Inversion)
protocol SaveButtonHandler {
    func saveContent()
}

// 2. Concrete implementation for production
class SaveHandler: SaveButtonHandler {
    func saveContent() {
        print("Production action triggered")
    }
}

// 3. View with injected dependency
struct SaveButton: View {
    // We only know about the abstraction, not the implementation
    let handler: SaveButtonHandler

    var body: some View {
        Button {
            handler.saveContent()
        } label: {
            Image(systemName: "bookmark")
                .scaledToFit()
                .foregroundStyle(SystemDesign.buttonForegroundColor)
                .imageScale(.large)
                .frame(width: SystemDesign.buttonSize.width, height: SystemDesign.buttonSize.height)
        }

    }
}

#Preview {
    SaveButton(handler: SaveHandler())
}
