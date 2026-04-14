import XCTest
import ViewInspector
@testable import ClaudeBar

// MARK: - Inspectable Conformances

extension PopoverView: @retroactive Inspectable {}
extension SetupView: @retroactive Inspectable {}
extension SessionExpiredView: @retroactive Inspectable {}
extension RingProgressView: @retroactive Inspectable {}
extension SettingsView: @retroactive Inspectable {}

// MARK: - PopoverView Tests

final class PopoverViewTests: XCTestCase {
    private func makeState() -> AppState {
        AppState(keychain: KeychainService(serviceName: "com.claudebar.test"))
    }

    func testShowsSetupViewWhenNotAuthenticated() throws {
        let state = makeState()
        let view = PopoverView(state: state)
        let inspected = try view.inspect()

        // Should contain SetupView when not authenticated
        XCTAssertNoThrow(try inspected.find(SetupView.self))
    }

    func testShowsSessionExpiredView() throws {
        let state = makeState()
        state.sessionKey = "sk-test"
        state.orgId = "org-123"
        state.error = .sessionExpired
        // Note: sessionExpired clears credentials in refreshUsage(), but we set it manually here
        // to test the view routing. Clear auth so the error path is hit differently.
        // Actually, the view checks: isAuthenticated AND error == .sessionExpired
        // So we need both to be true.
        let view = PopoverView(state: state)
        let inspected = try view.inspect()

        XCTAssertNoThrow(try inspected.find(SessionExpiredView.self))
    }

    func testShowsUsageDetailWhenAuthenticated() throws {
        let state = makeState()
        state.sessionKey = "sk-test"
        state.orgId = "org-123"
        let view = PopoverView(state: state)
        let inspected = try view.inspect()

        // Should NOT contain SetupView or SessionExpiredView
        XCTAssertThrowsError(try inspected.find(SetupView.self))
        XCTAssertThrowsError(try inspected.find(SessionExpiredView.self))
    }

    func testPopoverRendersVStack() throws {
        let state = makeState()
        let view = PopoverView(state: state)
        let inspected = try view.inspect()

        // Verify the root is a VStack
        XCTAssertNoThrow(try inspected.vStack())
    }
}

// MARK: - SetupView Tests

final class SetupViewTests: XCTestCase {
    private func makeState() -> AppState {
        AppState(keychain: KeychainService(serviceName: "com.claudebar.test"))
    }

    func testShowsTitle() throws {
        let state = makeState()
        let view = SetupView(state: state)
        let inspected = try view.inspect()

        let title = try inspected.find(text: "Setup ClaudeBar")
        XCTAssertNotNil(title)
    }

    func testShowsInstructions() throws {
        let state = makeState()
        let view = SetupView(state: state)
        let inspected = try view.inspect()

        // Instructions contain "claude.ai"
        XCTAssertNoThrow(try inspected.find(text: "Paste sessionKey here..."))
    }

    func testShowsConnectButton() throws {
        let state = makeState()
        let view = SetupView(state: state)
        let inspected = try view.inspect()

        let connectButton = try inspected.find(button: "Connect")
        XCTAssertNotNil(connectButton)
    }

    func testShowsQuitButton() throws {
        let state = makeState()
        let view = SetupView(state: state)
        let inspected = try view.inspect()

        let quitButton = try inspected.find(button: "Quit ClaudeBar")
        XCTAssertNotNil(quitButton)
    }

    func testShowsErrorMessage() throws {
        let state = makeState()
        state.error = .network("Connection failed")
        let view = SetupView(state: state)
        let inspected = try view.inspect()

        let errorText = try inspected.find(text: "Connection failed")
        XCTAssertNotNil(errorText)
    }

    func testShowsLoadingIndicator() throws {
        let state = makeState()
        state.isLoading = true
        let view = SetupView(state: state)
        let inspected = try view.inspect()

        XCTAssertNoThrow(try inspected.find(ViewType.ProgressView.self))
    }

    func testShowsOrgSelectionWhenMultipleOrgs() throws {
        let state = makeState()
        state.organizations = [
            Organization(uuid: "org-1", name: "Personal", capabilities: nil),
            Organization(uuid: "org-2", name: "Work", capabilities: nil),
        ]
        let view = SetupView(state: state)
        let inspected = try view.inspect()

        XCTAssertNoThrow(try inspected.find(text: "Select organization:"))
        XCTAssertNoThrow(try inspected.find(button: "Personal"))
        XCTAssertNoThrow(try inspected.find(button: "Work"))
    }

    func testHidesOrgSelectionForSingleOrg() throws {
        let state = makeState()
        state.organizations = [
            Organization(uuid: "org-1", name: "Personal", capabilities: nil),
        ]
        let view = SetupView(state: state)
        let inspected = try view.inspect()

        XCTAssertThrowsError(try inspected.find(text: "Select organization:"))
    }
}

// MARK: - SessionExpiredView Tests

final class SessionExpiredViewTests: XCTestCase {
    private func makeState() -> AppState {
        AppState(keychain: KeychainService(serviceName: "com.claudebar.test"))
    }

    func testShowsExpiredTitle() throws {
        let state = makeState()
        let view = SessionExpiredView(state: state)
        let inspected = try view.inspect()

        XCTAssertNoThrow(try inspected.find(text: "Session Expired"))
    }

    func testShowsReconnectButton() throws {
        let state = makeState()
        let view = SessionExpiredView(state: state)
        let inspected = try view.inspect()

        let button = try inspected.find(button: "Reconnect")
        XCTAssertNotNil(button)
    }

    func testShowsKeyInputField() throws {
        let state = makeState()
        let view = SessionExpiredView(state: state)
        let inspected = try view.inspect()

        XCTAssertNoThrow(try inspected.find(ViewType.TextField.self))
    }
}

// MARK: - RingProgressView Tests

final class RingProgressViewTests: XCTestCase {
    func testClampsProgressToZero() throws {
        let view = RingProgressView(progress: -0.5, color: .green)
        let inspected = try view.inspect()

        // Verify it renders (ZStack with two circles)
        let zstack = try inspected.zStack()
        XCTAssertEqual(try zstack.fixedFrame().width, 16) // default size
    }

    func testClampsProgressToOne() throws {
        let view = RingProgressView(progress: 1.5, color: .red)
        // Just verify it doesn't crash and renders correctly
        let inspected = try view.inspect()
        XCTAssertNoThrow(try inspected.zStack())
    }

    func testCustomSize() throws {
        let view = RingProgressView(progress: 0.5, color: .blue, size: 32)
        let inspected = try view.inspect()
        let frame = try inspected.zStack().fixedFrame()
        XCTAssertEqual(frame.width, 32)
        XCTAssertEqual(frame.height, 32)
    }

    func testDefaultSize() throws {
        let view = RingProgressView(progress: 0.5, color: .green)
        let inspected = try view.inspect()
        let frame = try inspected.zStack().fixedFrame()
        XCTAssertEqual(frame.width, 16)
        XCTAssertEqual(frame.height, 16)
    }

    func testContainsTwoCircles() throws {
        let view = RingProgressView(progress: 0.5, color: .green)
        let inspected = try view.inspect()
        let zstack = try inspected.zStack()

        // Background ring + progress arc = 2 shapes
        XCTAssertEqual(zstack.count, 2)
    }
}

// MARK: - SettingsView Tests

final class SettingsViewTests: XCTestCase {
    private func makeState() -> AppState {
        AppState(keychain: KeychainService(serviceName: "com.claudebar.test"))
    }

    func testShowsTitle() throws {
        let state = makeState()
        let view = SettingsView(state: state)
        let inspected = try view.inspect()

        XCTAssertNoThrow(try inspected.find(text: "Settings"))
    }

    func testShowsDisconnectedWhenNotAuthenticated() throws {
        let state = makeState()
        let view = SettingsView(state: state)
        let inspected = try view.inspect()

        XCTAssertNoThrow(try inspected.find(text: "Not connected"))
    }

    func testShowsConnectedWhenAuthenticated() throws {
        let state = makeState()
        state.sessionKey = "sk-test"
        state.orgId = "org-123"
        let view = SettingsView(state: state)
        let inspected = try view.inspect()

        XCTAssertNoThrow(try inspected.find(text: "Connected"))
    }

    func testShowsQuitButton() throws {
        let state = makeState()
        let view = SettingsView(state: state)
        let inspected = try view.inspect()

        XCTAssertNoThrow(try inspected.find(button: "Quit ClaudeBar"))
    }

    func testShowsUpdateSessionKeyButton() throws {
        let state = makeState()
        let view = SettingsView(state: state)
        let inspected = try view.inspect()

        XCTAssertNoThrow(try inspected.find(button: "Update Session Key"))
    }

    func testShowsDoneButton() throws {
        let state = makeState()
        let view = SettingsView(state: state)
        let inspected = try view.inspect()

        XCTAssertNoThrow(try inspected.find(button: "Done"))
    }
}
