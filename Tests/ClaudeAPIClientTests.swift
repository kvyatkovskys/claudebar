import XCTest
@testable import ClaudeBar

final class ClaudeAPIClientTests: XCTestCase {
    func testBuildUsageRequest() throws {
        let client = ClaudeAPIClient(sessionKey: "sk-test", orgId: "org-123")
        let request = client.buildUsageRequest()

        XCTAssertEqual(request.url?.absoluteString, "https://claude.ai/api/organizations/org-123/usage")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Cookie"), "sessionKey=sk-test")
        XCTAssertEqual(request.httpMethod, "GET")
    }

    func testBuildOrganizationsRequest() {
        let request = ClaudeAPIClient.buildOrganizationsRequest(sessionKey: "sk-test")

        XCTAssertEqual(request.url?.absoluteString, "https://claude.ai/api/organizations")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Cookie"), "sessionKey=sk-test")
    }

    func testParseUsageResponse() throws {
        let json = """
        {
          "five_hour": { "utilization": 0.73, "resets_at": "2026-04-12T15:30:00.000Z" },
          "seven_day": { "utilization": 0.31, "resets_at": "2026-04-14T12:59:00.000Z" },
          "seven_day_sonnet": { "utilization": 0.20, "resets_at": "2026-04-14T12:59:00.000Z" },
          "seven_day_opus": { "utilization": 0.08, "resets_at": null }
        }
        """.data(using: .utf8)!

        let usage = try ClaudeAPIClient.parseUsageResponse(data: json)
        XCTAssertEqual(usage.fiveHour?.utilization, 0.73)
        XCTAssertEqual(usage.sevenDay.utilization, 0.31)
        XCTAssertEqual(usage.sevenDaySonnet?.utilization, 0.20)
    }

    func testParseOrganizationsResponse() throws {
        let json = """
        [
          { "uuid": "org-abc", "name": "Personal" },
          { "uuid": "org-def", "name": "Work" }
        ]
        """.data(using: .utf8)!

        let orgs = try ClaudeAPIClient.parseOrganizationsResponse(data: json)
        XCTAssertEqual(orgs.count, 2)
        XCTAssertEqual(orgs[0].uuid, "org-abc")
        XCTAssertEqual(orgs[1].name, "Work")
    }
}
