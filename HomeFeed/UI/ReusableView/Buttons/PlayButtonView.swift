//
//  PlayButtonView.swift
//  HomeFeed
//
//  Created by Ashish Rai on 28/02/26.
//

import SwiftUI

// 1. Define the abstraction (Dependency Inversion)
protocol PlayButtonHandler {
    func playContent()
}

// 2. Concrete implementation for production
class PlayHandler: PlayButtonHandler {
    func playContent() {
        print("Production action triggered")
    }
}

struct PlayButtonView: View {
    // We only know about the abstraction, not the implementation
    let handler: PlayButtonHandler

    var body: some View {
        Button {
            handler.playContent()
        } label: {
            Image(systemName: "play.fill")
                .scaledToFit()
                .foregroundStyle(SystemDesign.buttonForegroundColor)
                .imageScale(.large)
                .frame(width: SystemDesign.buttonSize.width, height: SystemDesign.buttonSize.height)
        }

    }
}

struct PlayButtonView_Previews: PreviewProvider {
    static var previews: some View {
        PlayButtonView(handler: PlayHandler())
        .frame(width: 44, height: 44)
        .previewLayout(.sizeThatFits)
    }
}

