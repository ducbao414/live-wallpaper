//
//  Extensions.swift
//  LiveWallpaper
//

import SwiftUI

struct DisabledOpacityModifier: ViewModifier {
    var isDisabled: Bool
    
    func body(content: Content) -> some View {
        content
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.6 : 1.0)
    }
}

extension View {
    func disabledStyle(_ isDisabled: Bool) -> some View {
        self.modifier(DisabledOpacityModifier(isDisabled: isDisabled))
    }
}
