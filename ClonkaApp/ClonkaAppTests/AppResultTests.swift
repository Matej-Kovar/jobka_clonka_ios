import XCTest
@testable import ClonkaApp

final class AppResultTests: XCTestCase {

    func testSuccessResult() {
        let result: AppResult<String> = .success("hello")
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(result.data, "hello")
        XCTAssertNil(result.error)
    }

    func testFailureResult() {
        let result: AppResult<String> = .failure(.unauthorized)
        XCTAssertFalse(result.isSuccess)
        XCTAssertNil(result.data)
        XCTAssertNotNil(result.error)
    }

    func testMapSuccess() {
        let result: AppResult<Int> = .success(42)
        let mapped = result.map { String($0) }
        XCTAssertEqual(mapped.data, "42")
        XCTAssertTrue(mapped.isSuccess)
    }

    func testMapFailure() {
        let result: AppResult<Int> = .failure(.unauthorized)
        let mapped = result.map { String($0) }
        XCTAssertFalse(mapped.isSuccess)
        XCTAssertNil(mapped.data)
    }

    func testNetworkError() {
        let urlError = URLError(.notConnectedToInternet)
        let result: AppResult<String> = .failure(.network(urlError))
        XCTAssertFalse(result.isSuccess)
        XCTAssertNotNil(result.error?.errorDescription)
    }

    func testServerError() {
        let result: AppResult<String> = .failure(.server(statusCode: 500, message: "Internal"))
        XCTAssertNotNil(result.error?.errorDescription)
        XCTAssertTrue(result.error!.errorDescription!.contains("500"))
    }

    func testValidationError() {
        let result: AppResult<String> = .failure(.validation(messages: ["Field required", "Too short"]))
        XCTAssertNotNil(result.error?.errorDescription)
        XCTAssertTrue(result.error!.errorDescription!.contains("Field required"))
        XCTAssertTrue(result.error!.errorDescription!.contains("Too short"))
    }

    func testMaintenanceError() {
        let result: AppResult<String> = .failure(.maintenance)
        XCTAssertNotNil(result.error?.errorDescription)
        XCTAssertTrue(result.error!.errorDescription!.contains("maintenance"))
    }
}
