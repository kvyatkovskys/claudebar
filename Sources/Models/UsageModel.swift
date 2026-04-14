import SwiftUI

// MARK: - API Response Models

struct UsageResponse: Codable {
    let fiveHour: WindowUsage?
    let sevenDay: WindowUsage
    let sevenDaySonnet: WindowUsage?
    let sevenDayOpus: WindowUsage?
    let extraUsage: ExtraUsage?
}

struct WindowUsage: Codable {
    /// Utilization as a fraction (0.0 to 1.0). The API returns 0–100; we normalize on decode.
    let utilization: Double
    let resetsAt: Date?

    init(utilization: Double, resetsAt: Date?) {
        self.utilization = utilization > 1.0 ? utilization / 100.0 : utilization
        self.resetsAt = resetsAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawUtilization = try container.decode(Double.self, forKey: .utilization)
        self.utilization = rawUtilization > 1.0 ? rawUtilization / 100.0 : rawUtilization
        self.resetsAt = try container.decodeIfPresent(Date.self, forKey: .resetsAt)
    }
}

struct ExtraUsage: Codable {
    let isEnabled: Bool
    let monthlyLimit: Double?
    let usedCredits: Double?
    let utilization: Double?
}

struct Organization: Codable {
    let uuid: String
    let name: String
    let capabilities: [String]?
}

// MARK: - Display Helpers

enum UsageColor {
    case green, yellow, orange, red

    static func forUtilization(_ value: Double) -> UsageColor {
        switch value {
        case ..<0.51: return .green
        case ..<0.76: return .yellow
        case ..<0.91: return .orange
        default: return .red
        }
    }

    var swiftUIColor: Color {
        switch self {
        case .green: return Color(red: 0.29, green: 0.87, blue: 0.50)   // #4ade80
        case .yellow: return Color(red: 0.98, green: 0.80, blue: 0.08)  // #facc15
        case .orange: return Color(red: 0.83, green: 0.65, blue: 0.46)  // #D4A574
        case .red: return Color(red: 0.94, green: 0.27, blue: 0.27)     // #ef4444
        }
    }
}
