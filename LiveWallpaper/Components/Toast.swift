//
//  HUD.swift
//  LiveWallpaper
//

import SwiftUI


struct Toast: View {
    var systemImage: String
    var message: String
    @Binding var isVisible: Bool
    
    var body: some View {
        if isVisible {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(width: 180, height: 150)
            .background(BlurView())
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 10)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: isVisible)
        }
    }
}
