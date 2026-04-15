import SwiftUI

public struct SessionExpiredView: View {
    public let state: AppState

    public init(state: AppState) { self.state = state }

    public var body: some View {
        SessionKeyInputView(
            state: state,
            title: String(localized: "session.expired", bundle: .module),
            subtitle: String(localized: "session.expiredSubtitle", bundle: .module),
            buttonLabel: String(localized: "action.reconnect", bundle: .module),
            titleIcon: "exclamationmark.triangle",
            titleColor: .orange
        )
    }
}
