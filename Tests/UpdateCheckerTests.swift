import XCTest
@testable import ClaudeBar

final class UpdateCheckerTests: XCTestCase {
    func testNewerMajorVersion() {
        XCTAssertTrue(UpdateChecker.compareVersions("2.0.0", isNewerThan: "1.0.0"))
    }

    func testNewerMinorVersion() {
        XCTAssertTrue(UpdateChecker.compareVersions("1.1.0", isNewerThan: "1.0.0"))
    }

    func testNewerPatchVersion() {
        XCTAssertTrue(UpdateChecker.compareVersions("1.0.1", isNewerThan: "1.0.0"))
    }

    func testSameVersion() {
        XCTAssertFalse(UpdateChecker.compareVersions("1.0.0", isNewerThan: "1.0.0"))
    }

    func testOlderVersion() {
        XCTAssertFalse(UpdateChecker.compareVersions("1.0.0", isNewerThan: "1.1.0"))
    }

    func testDifferentLengthVersions() {
        XCTAssertTrue(UpdateChecker.compareVersions("1.0.0.1", isNewerThan: "1.0.0"))
        XCTAssertFalse(UpdateChecker.compareVersions("1.0", isNewerThan: "1.0.0"))
    }
}
