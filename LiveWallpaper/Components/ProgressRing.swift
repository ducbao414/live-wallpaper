import SwiftUI

struct ProgressRing: View {
    var progress: CGFloat  // Value between 0 and 1
    var size: CGFloat      // Diameter of the circle
    var lineWidth: CGFloat = 7
    var color: Color = .accentColor
    
    var body: some View {
        ZStack {
            // Background Circle (Gray)
            Circle()
                .stroke(.foreground.opacity(0.3), lineWidth: lineWidth)
            
            // Foreground Progress Circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90)) // Start from the top
                .animation(.easeInOut, value: progress)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    ProgressRing(progress: 0.8, size: 100)
}
