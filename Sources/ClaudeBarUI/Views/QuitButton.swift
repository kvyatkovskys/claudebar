import SwiftUI

public struct QuitButton: View {
    private let foregroundStyle: Color

    public init(foregroundStyle: Color = .red) {
        self.foregroundStyle = foregroundStyle
    }

    public var body: some View {
        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Text("action.quit", bundle: .module)
                .font(.subheadline.bold())
                .foregroundStyle(foregroundStyle)
        }
        .buttonStyle(.plain)
    }
}
