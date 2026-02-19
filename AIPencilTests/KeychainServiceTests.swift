import XCTest
@testable import AIPencil

final class KeychainServiceTests: XCTestCase {

    private let keychain = KeychainService.shared
    private let testKey = "sk-ant-test-1234567890abcdef"

    override func tearDown() {
        try? keychain.deleteAPIKey()
        super.tearDown()
    }

    func testSaveAndLoadAPIKey() throws {
        try keychain.saveAPIKey(testKey)
        let loaded = keychain.loadAPIKey()
        XCTAssertEqual(loaded, testKey)
    }

    func testHasAPIKey() throws {
        XCTAssertFalse(keychain.hasAPIKey)
        try keychain.saveAPIKey(testKey)
        XCTAssertTrue(keychain.hasAPIKey)
    }

    func testDeleteAPIKey() throws {
        try keychain.saveAPIKey(testKey)
        XCTAssertTrue(keychain.hasAPIKey)
        try keychain.deleteAPIKey()
        XCTAssertFalse(keychain.hasAPIKey)
    }

    func testMaskedAPIKey() throws {
        try keychain.saveAPIKey(testKey)
        let masked = keychain.maskedAPIKey()
        XCTAssertNotNil(masked)
        // Should show first 7 + ****** + last 4
        XCTAssertEqual(masked, "sk-ant-******cdef")
        // Should NOT contain the full key
        XCTAssertNotEqual(masked, testKey)
    }

    func testMaskedAPIKeyReturnsNilWhenNoKey() {
        let masked = keychain.maskedAPIKey()
        XCTAssertNil(masked)
    }

    func testSaveOverwritesExistingKey() throws {
        try keychain.saveAPIKey("first-key")
        try keychain.saveAPIKey("second-key")
        XCTAssertEqual(keychain.loadAPIKey(), "second-key")
    }
}
