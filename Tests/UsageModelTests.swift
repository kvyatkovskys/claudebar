import XCTest
@testable import ClaudeBar

final class UsageModelTests: XCTestCase {
    func testDecodeFullUsageResponse() throws {
        let json = """
        {
          "five_hour": { "utilization": 0.42, "resets_at": "2026-04-12T15:30:00.000Z" },
          "seven_day": { "utilization": 0.15, "resets_at": "2026-04-14T12:59:00.000Z" },
          "seven_day_sonnet": { "utilization": 0.08, "resets_at": "2026-04-14T12:59:00.000Z" },
          "seven_day_opus": { "utilization": 0.03, "resets_at": null },
          "extra_usage": { "is_enabled": true, "monthly_limit": 100.0, "used_credits": 12.50, "utilization": 0.125 }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let usage = try decoder.decode(UsageResponse.self, from: json)

        XCTAssertEqual(usage.fiveHour?.utilization, 0.42)
        XCTAssertNotNil(usage.fiveHour?.resetsAt)
        XCTAssertEqual(usage.sevenDay.utilization, 0.15)
        XCTAssertEqual(usage.sevenDaySonnet?.utilization, 0.08)
        XCTAssertEqual(usage.sevenDayOpus?.utilization, 0.03)
        XCTAssertNil(usage.sevenDayOpus?.resetsAt)
        XCTAssertEqual(usage.extraUsage?.isEnabled, true)
        XCTAssertEqual(usage.extraUsage?.monthlyLimit, 100.0)
        XCTAssertEqual(usage.extraUsage?.usedCredits, 12.50)
    }

    func testDecodeMinimalResponse() throws {
        let json = """
        {
          "seven_day": { "utilization": 0.05, "resets_at": "2026-04-14T12:59:00.000Z" }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let usage = try decoder.decode(UsageResponse.self, from: json)

        XCTAssertNil(usage.fiveHour)
        XCTAssertEqual(usage.sevenDay.utilization, 0.05)
        XCTAssertNil(usage.sevenDaySonnet)
        XCTAssertNil(usage.sevenDayOpus)
        XCTAssertNil(usage.extraUsage)
    }

    func testDecodeOrganization() throws {
        let json = """
        [{ "uuid": "abc-123", "name": "My Org", "capabilities": ["chat"] }]
        """.data(using: .utf8)!

        let orgs = try JSONDecoder().decode([Organization].self, from: json)

        XCTAssertEqual(orgs.count, 1)
        XCTAssertEqual(orgs[0].uuid, "abc-123")
        XCTAssertEqual(orgs[0].name, "My Org")
    }

    func testDecodePercentageScaleResponse() throws {
        // Real API returns utilization as 0-100, not 0-1
        let json = """
        {
          "five_hour": { "utilization": 5.0, "resets_at": "2026-04-12T15:30:00.000Z" },
          "seven_day": { "utilization": 15.0, "resets_at": "2026-04-14T12:59:00.000Z" }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let usage = try decoder.decode(UsageResponse.self, from: json)

        XCTAssertEqual(usage.fiveHour!.utilization, 0.05, accuracy: 0.001)
        XCTAssertEqual(usage.sevenDay.utilization, 0.15, accuracy: 0.001)
    }

    func testNormalizationViaInit() {
        // Values > 1.0 are treated as percentage scale
        let window = WindowUsage(utilization: 73.0, resetsAt: nil)
        XCTAssertEqual(window.utilization, 0.73, accuracy: 0.001)

        // Values <= 1.0 are kept as-is
        let fraction = WindowUsage(utilization: 0.42, resetsAt: nil)
        XCTAssertEqual(fraction.utilization, 0.42)
    }

    func testColorForUtilization() {
        XCTAssertEqual(UsageColor.forUtilization(0.0), .green)
        XCTAssertEqual(UsageColor.forUtilization(0.3), .green)
        XCTAssertEqual(UsageColor.forUtilization(0.5), .green)
        XCTAssertEqual(UsageColor.forUtilization(0.51), .yellow)
        XCTAssertEqual(UsageColor.forUtilization(0.75), .yellow)
        XCTAssertEqual(UsageColor.forUtilization(0.76), .orange)
        XCTAssertEqual(UsageColor.forUtilization(0.9), .orange)
        XCTAssertEqual(UsageColor.forUtilization(0.91), .red)
        XCTAssertEqual(UsageColor.forUtilization(1.0), .red)
    }
}
