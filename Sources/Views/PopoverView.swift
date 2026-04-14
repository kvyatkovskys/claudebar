import SwiftUI

struct PopoverView: View {
    let state: AppState

    var body: some View {
        VStack(spacing: 0) {
            if !state.isAuthenticated {
                SetupView(state: state)
            } else if let error = state.error, error == .sessionExpired {
                SessionExpiredView(state: state)
            } else {
                UsageDetailView(state: state)
            }
        }
        .frame(width: 320)
    }
}

// MARK: - Usage Detail View

private struct UsageDetailView: View {
    let state: AppState

    var body: some View {
        VStack(spacing: 0) {
            header
            if let usage = state.usage {
                fiveHourSection(usage)
                sevenDaySection(usage)
            } else if state.isLoading {
                ProgressView()
                    .padding(40)
            } else if let error = state.error {
                Text(error.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(20)
            }
            footer
        }
    }

    private var header: some View {
        HStack {
            Text("Claude Usage")
                .font(.headline)
            Spacer()
            if let usage = state.usage {
                Text(tierLabel(usage))
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.quaternary)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func fiveHourSection(_ usage: UsageResponse) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("5-Hour Window")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if let reset = usage.fiveHour?.resetsAt {
                    Text("Resets in \(resetTimeString(reset))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            let utilization = usage.fiveHour?.utilization ?? 0
            let color = UsageColor.forUtilization(utilization).swiftUIColor

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.quaternary)
                    .frame(height: 20)
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color)
                        .frame(width: geo.size.width * utilization, height: 20)
                }
                .frame(height: 20)
                Text("\(Int(utilization * 100))%")
                    .font(.system(size: 11, weight: .bold))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }



    private func sevenDaySection(_ usage: UsageResponse) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("7-Day Windows")
                .font(.caption)
                .foregroundStyle(.secondary)

            slimBar(label: "Total", utilization: usage.sevenDay.utilization, resetDate: usage.sevenDay.resetsAt, color: .blue)

            if let opus = usage.sevenDayOpus {
                slimBar(label: "Opus", utilization: opus.utilization, resetDate: opus.resetsAt, color: Color(red: 0.75, green: 0.52, blue: 0.99))
            }

            if let sonnet = usage.sevenDaySonnet {
                slimBar(label: "Sonnet", utilization: sonnet.utilization, resetDate: sonnet.resetsAt, color: Color(red: 0.38, green: 0.65, blue: 0.98))
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private func slimBar(label: String, utilization: Double, resetDate: Date?, color: Color) -> some View {
        VStack(spacing: 3) {
            HStack {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(utilization * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let date = resetDate {
                    Text("· resets \(shortResetString(date))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.quaternary)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * utilization)
                }
            }
            .frame(height: 8)
        }
    }

    private var footer: some View {
        HStack {
            if let lastUpdated = state.lastUpdated {
                Text("Updated \(lastUpdated, style: .relative) ago")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Button("Refresh") {
                Task { await state.refreshUsage() }
            }
            .font(.caption2)
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
            Button("Settings") {
                state.showingSettings = true
            }
            .font(.caption2)
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
            .padding(.leading, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func tierLabel(_ usage: UsageResponse) -> String {
        if usage.sevenDayOpus != nil {
            if let extra = usage.extraUsage, let limit = extra.monthlyLimit {
                return "Max $\(Int(limit))"
            }
            return "Max"
        }
        return "Pro"
    }

    private func resetTimeString(_ date: Date) -> String {
        let interval = date.timeIntervalSinceNow
        if interval <= 0 { return "now" }
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }

    private func shortResetString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Setup View (first-launch auth)

struct SetupView: View {
    let state: AppState
    @State private var keyInput = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Setup ClaudeBar")
                .font(.headline)

            Text("1. Open **claude.ai** in your browser\n2. DevTools (\u{2318}\u{2325}I) \u{2192} Application \u{2192} Cookies\n3. Copy the `sessionKey` value")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("Paste sessionKey here...", text: $keyInput)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12, design: .monospaced))

            if state.organizations.count > 1 {
                Text("Select organization:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(state.organizations, id: \.uuid) { org in
                    Button(org.name) {
                        Task { await state.selectOrganization(org) }
                    }
                    .buttonStyle(.bordered)
                }
            }

            if state.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }

            if let error = state.error {
                Text(error.message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button("Connect") {
                    Task { await state.validateAndFetchOrgs(sessionKey: keyInput) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(keyInput.isEmpty || state.isLoading)
            }

            Divider()
            Button("Quit ClaudeBar") {
                NSApplication.shared.terminate(nil)
            }
            .font(.caption)
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(16)
    }
}

// MARK: - Session Expired View

struct SessionExpiredView: View {
    let state: AppState
    @State private var keyInput = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Session Expired", systemImage: "exclamationmark.triangle")
                .font(.headline)
                .foregroundStyle(.orange)

            Text("Your sessionKey has expired. Paste a new one from claude.ai cookies.")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("Paste new sessionKey...", text: $keyInput)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12, design: .monospaced))

            HStack {
                Spacer()
                Button("Reconnect") {
                    Task { await state.validateAndFetchOrgs(sessionKey: keyInput) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(keyInput.isEmpty || state.isLoading)
            }
        }
        .padding(16)
    }
}
