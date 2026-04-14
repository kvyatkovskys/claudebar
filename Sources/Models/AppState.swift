import SwiftUI

@Observable
final class AppState {
    // MARK: - Auth State
    var sessionKey: String?
    var orgId: String?
    var organizations: [Organization] = []
    var isAuthenticated: Bool { sessionKey != nil && orgId != nil }

    // MARK: - Usage State
    var usage: UsageResponse?
    var lastUpdated: Date?
    var isLoading = false
    var error: AppError?

    // MARK: - UI State
    var showingSettings = false

    // MARK: - Services
    private let keychain: KeychainService
    private var pollTimer: Timer?
    var pollInterval: TimeInterval = 300 // 5 minutes

    init(keychain: KeychainService = KeychainService()) {
        self.keychain = keychain
    }

    // MARK: - Computed Display Values

    var menuBarText: String {
        guard let usage else { return "—%" }
        let pct = Int((usage.fiveHour?.utilization ?? usage.sevenDay.utilization) * 100)
        return "\(pct)%"
    }

    var menuBarUtilization: Double {
        usage?.fiveHour?.utilization ?? usage?.sevenDay.utilization ?? 0
    }

    var usageColor: UsageColor {
        UsageColor.forUtilization(menuBarUtilization)
    }

    // MARK: - Lifecycle

    func loadCredentials() {
        sessionKey = try? keychain.retrieve(account: "sessionKey")
        orgId = try? keychain.retrieve(account: "orgId")
    }

    func saveCredentials(sessionKey: String, orgId: String) throws {
        try keychain.save(account: "sessionKey", value: sessionKey)
        try keychain.save(account: "orgId", value: orgId)
        self.sessionKey = sessionKey
        self.orgId = orgId
    }

    func clearCredentials() {
        try? keychain.delete(account: "sessionKey")
        try? keychain.delete(account: "orgId")
        sessionKey = nil
        orgId = nil
        usage = nil
        organizations = []
    }

    // MARK: - API Calls

    func validateAndFetchOrgs(sessionKey: String) async {
        isLoading = true
        error = nil
        self.sessionKey = sessionKey
        do {
            organizations = try await ClaudeAPIClient.fetchOrganizations(sessionKey: sessionKey)
            if organizations.count == 1 {
                try saveCredentials(sessionKey: sessionKey, orgId: organizations[0].uuid)
                await refreshUsage()
            }
        } catch let apiError as APIError {
            error = .api(apiError)
            self.sessionKey = nil
        } catch {
            self.error = .network(error.localizedDescription)
            self.sessionKey = nil
        }
        isLoading = false
    }

    func selectOrganization(_ org: Organization) async {
        guard let sessionKey else { return }
        do {
            try saveCredentials(sessionKey: sessionKey, orgId: org.uuid)
            await refreshUsage()
        } catch {
            self.error = .network(error.localizedDescription)
        }
    }

    func refreshUsage() async {
        guard let sessionKey, let orgId else { return }
        isLoading = true
        error = nil
        let client = ClaudeAPIClient(sessionKey: sessionKey, orgId: orgId)
        do {
            usage = try await client.fetchUsage()
            lastUpdated = Date()
        } catch APIError.sessionExpired {
            error = .sessionExpired
            clearCredentials()
        } catch APIError.rateLimited {
            error = .rateLimited
        } catch {
            self.error = .network(error.localizedDescription)
        }
        isLoading = false
    }

    // MARK: - Polling

    func startPolling() {
        stopPolling()
        pollTimer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { await self.refreshUsage() }
        }
        // Also fetch immediately
        Task { await refreshUsage() }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }
}

enum AppError: Equatable {
    case api(APIError)
    case sessionExpired
    case rateLimited
    case network(String)

    var message: String {
        switch self {
        case .sessionExpired: return "Session expired — update your key"
        case .rateLimited: return "Rate limited — will retry"
        case .api(let e): return "API error: \(e)"
        case .network(let msg): return msg
        }
    }
}
