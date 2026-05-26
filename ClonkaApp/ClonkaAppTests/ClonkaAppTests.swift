import XCTest
@testable import ClonkaApp

final class ClonkaAppTests: XCTestCase {
    @MainActor
    func testAppStateDefaults() {
        let state = AppState()
        XCTAssertFalse(state.isAuthenticated)
        XCTAssertFalse(state.isMaintenanceMode)
        XCTAssertFalse(state.isDeveloperMode)
        XCTAssertNil(state.colorSchemeOverride)
    }
}
