//
//  Styles.swift
//  memTV
//
//  Created by Taymur Khumush on 8/30/25.
//

import SwiftUI

extension ButtonStyle where Self == CardButtonStyle {
    static var appleTV: CardButtonStyle {
        CardButtonStyle()
    }
}

struct CardButtonStyle: ButtonStyle {
    @Environment(\.isFocused) var isFocused

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : (isFocused ? 1.05 : 1.0))
            .shadow(color: isFocused ? .white : .clear, radius: isFocused ? 8 : 0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
