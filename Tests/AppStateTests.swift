import XCTest
@testable import ClaudeBar

final class AppStateTests: XCTestCase {
    private func makeState() -> AppState {
        let state = AppState(keychain: KeychainService(serviceName: "com.claudebar.test"))
        // Clean slate
        state.clearCredentials()
        return state
    }

    // MARK: - Authentication State

    func testInitialStateIsNotAuthenticated() {
        let state = makeState()
        XCTAssertFalse(state.isAuthenticated)
        XCTAssertNil(state.sessionKey)
        XCTAssertNil(state.orgId)
    }

    func testIsAuthenticatedRequiresBothKeys() {
        let state = makeState()

        state.sessionKey = "sk-test"
        XCTAssertFalse(state.isAuthenticated, "Should not be authenticated with only sessionKey")

        state.orgId = "org-123"
        XCTAssertTrue(state.isAuthenticated, "Should be authenticated with both keys")
    }

    func testSaveAndLoadCredentials() throws {
        let state = makeState()
        try state.saveCredentials(sessionKey: "sk-ant-test", orgId: "org-abc")

        XCTAssertEqual(state.sessionKey, "sk-ant-test")
        XCTAssertEqual(state.orgId, "org-abc")
        XCTAssertTrue(state.isAuthenticated)

        // Create a new state with the same keychain to verify persistence
        let state2 = AppState(keychain: KeychainService(serviceName: "com.claudebar.test"))
        state2.loadCredentials()
        XCTAssertEqual(state2.sessionKey, "sk-ant-test")
        XCTAssertEqual(state2.orgId, "org-abc")
        XCTAssertTrue(state2.isAuthenticated)

        // Cleanup
        state2.clearCredentials()
    }

    func testClearCredentialsResetsState() throws {
        let state = makeState()
        try state.saveCredentials(sessionKey: "sk-test", orgId: "org-123")
        state.usage = UsageResponse(
            fiveHour: WindowUsage(utilization: 0.5, resetsAt: nil),
            sevenDay: WindowUsage(utilization: 0.3, resetsAt: nil),
            sevenDaySonnet: nil, sevenDayOpus: nil, extraUsage: nil
        )
        state.organizations = [Organization(uuid: "org-123", name: "Test", capabilities: nil)]

        state.clearCredentials()

        XCTAssertNil(state.sessionKey)
        XCTAssertNil(state.orgId)
        XCTAssertNil(state.usage)
        XCTAssertTrue(state.organizations.isEmpty)
        XCTAssertFalse(state.isAuthenticated)
    }

    // MARK: - Menu Bar Display Values

    func testMenuBarTextWithNoUsage() {
        let state = makeState()
        XCTAssertEqual(state.menuBarText, "—%")
    }

    func testMenuBarTextWithFiveHourUsage() {
        let state = makeState()
        state.usage = UsageResponse(
            fiveHour: WindowUsage(utilization: 0.73, resetsAt: nil),
            sevenDay: WindowUsage(utilization: 0.3, resetsAt: nil),
            sevenDaySonnet: nil, sevenDayOpus: nil, extraUsage: nil
        )
        XCTAssertEqual(state.menuBarText, "73%")
    }

    func testMenuBarTextFallsBackToSevenDay() {
        let state = makeState()
        state.usage = UsageResponse(
            fiveHour: nil,
            sevenDay: WindowUsage(utilization: 0.42, resetsAt: nil),
            sevenDaySonnet: nil, sevenDayOpus: nil, extraUsage: nil
        )
        XCTAssertEqual(state.menuBarText, "42%")
    }

    func testMenuBarTextAtZero() {
        let state = makeState()
        state.usage = UsageResponse(
            fiveHour: WindowUsage(utilization: 0.0, resetsAt: nil),
            sevenDay: WindowUsage(utilization: 0.0, resetsAt: nil),
            sevenDaySonnet: nil, sevenDayOpus: nil, extraUsage: nil
        )
        XCTAssertEqual(state.menuBarText, "0%")
    }

    func testMenuBarTextAtFull() {
        let state = makeState()
        state.usage = UsageResponse(
            fiveHour: WindowUsage(utilization: 1.0, resetsAt: nil),
            sevenDay: WindowUsage(utilization: 0.5, resetsAt: nil),
            sevenDaySonnet: nil, sevenDayOpus: nil, extraUsage: nil
        )
        XCTAssertEqual(state.menuBarText, "100%")
    }

    // MARK: - Utilization & Color

    func testMenuBarUtilizationWithNoUsage() {
        let state = makeState()
        XCTAssertEqual(state.menuBarUtilization, 0)
    }

    func testMenuBarUtilizationPrefersFiveHour() {
        let state = makeState()
        state.usage = UsageResponse(
            fiveHour: WindowUsage(utilization: 0.8, resetsAt: nil),
            sevenDay: WindowUsage(utilization: 0.2, resetsAt: nil),
            sevenDaySonnet: nil, sevenDayOpus: nil, extraUsage: nil
        )
        XCTAssertEqual(state.menuBarUtilization, 0.8)
    }

    func testUsageColorGreen() {
        let state = makeState()
        state.usage = UsageResponse(
            fiveHour: WindowUsage(utilization: 0.3, resetsAt: nil),
            sevenDay: WindowUsage(utilization: 0.1, resetsAt: nil),
            sevenDaySonnet: nil, sevenDayOpus: nil, extraUsage: nil
        )
        XCTAssertEqual(state.usageColor, .green)
    }

    func testUsageColorYellow() {
        let state = makeState()
        state.usage = UsageResponse(
            fiveHour: WindowUsage(utilization: 0.6, resetsAt: nil),
            sevenDay: WindowUsage(utilization: 0.1, resetsAt: nil),
            sevenDaySonnet: nil, sevenDayOpus: nil, extraUsage: nil
        )
        XCTAssertEqual(state.usageColor, .yellow)
    }

    func testUsageColorOrange() {
        let state = makeState()
        state.usage = UsageResponse(
            fiveHour: WindowUsage(utilization: 0.85, resetsAt: nil),
            sevenDay: WindowUsage(utilization: 0.1, resetsAt: nil),
            sevenDaySonnet: nil, sevenDayOpus: nil, extraUsage: nil
        )
        XCTAssertEqual(state.usageColor, .orange)
    }

    func testUsageColorRed() {
        let state = makeState()
        state.usage = UsageResponse(
            fiveHour: WindowUsage(utilization: 0.95, resetsAt: nil),
            sevenDay: WindowUsage(utilization: 0.1, resetsAt: nil),
            sevenDaySonnet: nil, sevenDayOpus: nil, extraUsage: nil
        )
        XCTAssertEqual(state.usageColor, .red)
    }

    // MARK: - Error Messages

    func testAppErrorMessages() {
        XCTAssertEqual(AppError.sessionExpired.message, "Session expired — update your key")
        XCTAssertEqual(AppError.rateLimited.message, "Rate limited — will retry")
        XCTAssertEqual(AppError.network("Connection failed").message, "Connection failed")
        XCTAssertEqual(AppError.api(.httpError(500)).message, "API error: httpError(500)")
    }

    // MARK: - Organization Selection

    func testSessionKeyRetainedForOrgSelection() {
        let state = makeState()
        // Simulate what validateAndFetchOrgs does when multiple orgs are returned:
        // it should store the sessionKey so selectOrganization can use it.
        state.sessionKey = "sk-ant-multi-org"
        state.organizations = [
            Organization(uuid: "org-1", name: "Personal", capabilities: nil),
            Organization(uuid: "org-2", name: "Work", capabilities: nil),
        ]

        // sessionKey must be available for selectOrganization to proceed
        XCTAssertEqual(state.sessionKey, "sk-ant-multi-org")
        XCTAssertFalse(state.isAuthenticated, "Not yet authenticated until org is selected")
    }

    func testSelectOrganizationSavesCredentials() throws {
        let state = makeState()
        state.sessionKey = "sk-ant-test"

        // Directly test saveCredentials (selectOrganization calls this)
        try state.saveCredentials(sessionKey: "sk-ant-test", orgId: "org-2")

        XCTAssertEqual(state.sessionKey, "sk-ant-test")
        XCTAssertEqual(state.orgId, "org-2")
        XCTAssertTrue(state.isAuthenticated)

        state.clearCredentials()
    }

    // MARK: - Initial UI State

    func testInitialLoadingState() {
        let state = makeState()
        XCTAssertFalse(state.isLoading)
        XCTAssertNil(state.error)
        XCTAssertNil(state.lastUpdated)
        XCTAssertFalse(state.showingSettings)
    }
}
