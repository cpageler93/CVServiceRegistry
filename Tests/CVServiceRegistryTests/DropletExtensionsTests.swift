import XCTest
import Vapor

@testable import CVServiceRegistry

extension Droplet {
    
    static func testable(configDir: String = "") throws -> Droplet {
        let config = try Config(arguments: [
            "vapor",
            "--env=test",
            "--configDir=\(configDir)"
            ])
        let drop = try Droplet(config)
        return drop
    }
    
    func serveInBackground() throws {
        background {
            try! self.run()
        }
        console.wait(seconds: 0.5)
    }
    
}


class DropletExtensionsTests: XCTestCase {
    
    static var allTests = [
        ("testRegisterServiceFromConfig", testRegisterServiceFromConfig),
    ]
    
    func testRegisterServiceFromConfig() {
        do {
            let testBundle = Bundle(for: type(of: self))
            
            try FileManager.default.createDirectory(atPath: "\(testBundle.resourcePath!)/Config/", withIntermediateDirectories: true, attributes: nil)
            
            let consulJsonPath = "\(testBundle.resourcePath!)/Config/consul.json"
            try """
            {
                "service": {
                    "id": "com.pageler.christoph.test.from.config",
                    "name": "TestServiceFromConfig",
                    "tags": [
                        "foo",
                        "bar"
                    ]
                }
            }
            """.write(to: URL(fileURLWithPath: consulJsonPath), atomically: true, encoding: String.Encoding.utf8)
            
            let drop = try Droplet.testable(configDir: testBundle.resourcePath!)
            
            let registerError = try CVServiceRegistry.sharedInstance.register(droplet: drop)
            XCTAssertNil(registerError)
            
            let deregisterError = try CVServiceRegistry.sharedInstance.deregister(droplet: drop)
            XCTAssertNil(deregisterError)
        } catch {
            XCTFail("Failed droplet registration")
        }
    }
    
}

