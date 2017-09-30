import XCTest
import Vapor

@testable import CVServiceRegistry


class CVServiceRegistryTests: XCTestCase {
    
    static var allTests = [
        ("testDatacenters", testDatacenters),
    ]
    
    func testDatacenters() {
        let datacenters = CVServiceRegistry.sharedInstance.datacenters()
        XCTAssertNotNil(datacenters)
        XCTAssertGreaterThan(datacenters?.count ?? 0, 0)
    }

}
