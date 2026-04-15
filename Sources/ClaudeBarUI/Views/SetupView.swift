import SwiftUI

public struct SetupView: View {
    public let state: AppState

    public init(state: AppState) { self.state = state }

    public var body: some View {
        SessionKeyInputView(
            state: state,
            title: String(localized: "setup.title", bundle: .module),
            subtitle: String(localized: "setup.instructions", bundle: .module),
            buttonLabel: String(localized: "action.connect", bundle: .module),
            showQuitButton: true
        )
    }
}
