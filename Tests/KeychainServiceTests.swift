import XCTest
@testable import ClaudeBar

final class KeychainServiceTests: XCTestCase {
    let service = KeychainService(serviceName: "com.claudebar.test")

    override func tearDown() {
        try? service.delete(account: "sessionKey")
        try? service.delete(account: "orgId")
    }

    func testSaveAndRetrieve() throws {
        try service.save(account: "sessionKey", value: "sk-ant-sid01-test123")
        let retrieved = try service.retrieve(account: "sessionKey")
        XCTAssertEqual(retrieved, "sk-ant-sid01-test123")
    }

    func testRetrieveNonExistent() {
        let result = try? service.retrieve(account: "nonexistent")
        XCTAssertNil(result)
    }

    func testOverwriteExisting() throws {
        try service.save(account: "sessionKey", value: "old-value")
        try service.save(account: "sessionKey", value: "new-value")
        let retrieved = try service.retrieve(account: "sessionKey")
        XCTAssertEqual(retrieved, "new-value")
    }

    func testDelete() throws {
        try service.save(account: "orgId", value: "abc-123")
        try service.delete(account: "orgId")
        let result = try? service.retrieve(account: "orgId")
        XCTAssertNil(result)
    }
}
