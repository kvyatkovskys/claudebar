import SwiftUI

struct RingProgressView: View {
    let progress: Double // 0.0 to 1.0
    let color: Color
    let size: CGFloat

    init(progress: Double, color: Color, size: CGFloat = 16) {
        self.progress = min(max(progress, 0), 1)
        self.color = color
        self.size = size
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.25), lineWidth: size * 0.15)

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: size * 0.15, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}
