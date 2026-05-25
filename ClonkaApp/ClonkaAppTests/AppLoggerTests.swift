import XCTest
@testable import ClonkaApp

final class AppLoggerTests: XCTestCase {

    func testRedactShortString() {
        let result = AppLogger.redact("abc")
        XCTAssertEqual(result, "abc****")
    }

    func testRedactLongString() {
        let result = AppLogger.redact("d026d82a-bdf6-4ca1-aaa4-ac81b5804c99")
        XCTAssertTrue(result.hasPrefix("d026"))
        XCTAssertTrue(result.hasSuffix("****"))
        XCTAssertEqual(result, "d026****")
    }

    func testRedactExactlyFourChars() {
        let result = AppLogger.redact("abcd")
        XCTAssertEqual(result, "abcd****")
    }

    func testRedactEmptyString() {
        let result = AppLogger.redact("")
        XCTAssertEqual(result, "<empty>")
    }

    func testRedactURLSensitiveParam() {
        let url = URL(string: "https://api.example.com/login?ID_Login=secret-token&other=value")!
        let result = AppLogger.redactURL(url)
        XCTAssertFalse(result.contains("secret-token"))
        XCTAssertTrue(result.contains("other=value"))
    }

    func testRedactURLNoSensitiveParams() {
        let url = URL(string: "https://api.example.com/data?page=1&count=20")!
        let result = AppLogger.redactURL(url)
        XCTAssertTrue(result.contains("page=1"))
        XCTAssertTrue(result.contains("count=20"))
    }

    func testRedactURLPasswordParam() {
        let url = URL(string: "https://api.example.com?password=hunter2&name=test")!
        let result = AppLogger.redactURL(url)
        XCTAssertFalse(result.contains("hunter2"))
        XCTAssertTrue(result.contains("name=test"))
    }

    func testRedactBody() {
        let json = """
        {"ID_Login":"secret-token-123","DisplayName":"Tester"}
        """
        let data = json.data(using: .utf8)
        let result = AppLogger.redactBody(data)
        XCTAssertFalse(result.contains("secret-token-123"))
        XCTAssertTrue(result.contains("Tester"))
    }

    func testRedactBodyNilData() {
        let result = AppLogger.redactBody(nil)
        XCTAssertEqual(result, "<no body>")
    }
}
