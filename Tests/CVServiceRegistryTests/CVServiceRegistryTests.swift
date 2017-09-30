import XCTest
import Vapor
import ConsulSwift

@testable import CVServiceRegistry


class CVServiceRegistryTests: XCTestCase {
    
    static var allTests = [
        ("testDatacenters", testDatacenters),
        ("testNodesForService", testNodesForService),
    ]
    
    func testDatacenters() {
        let datacenters = CVServiceRegistry.sharedInstance.datacenters()
        XCTAssertNotNil(datacenters)
        XCTAssertGreaterThan(datacenters?.count ?? 0, 0)
    }
    
    func testNodesForService() {
        let consul = Consul()
        
        // register node
        let service = ConsulAgentServiceInput(name: "testNodesForService",
                                              id: "testNodesForService",
                                              tags: ["production"],
                                              address: nil,
                                              port: nil)
        let registerResult = consul.agentRegisterService(service)
        switch registerResult {
        case .success: break
        case .failure: XCTFail("Failed register service")
        }
        
        // get nodes
        guard let nodesResult = CVServiceRegistry.sharedInstance.nodesForService("testNodesForService",
                                                                                 tag: "production")
        else {
            XCTFail("Failed NodesForService")
            return
        }
        
        XCTAssertEqual(nodesResult.count, 1)
        guard let firstNode = nodesResult.first else {
            XCTFail("Failed getting first node")
            return
        }
        
        XCTAssertEqual(firstNode.service.id, "testNodesForService")
        XCTAssertEqual(firstNode.service.tags.count, 1)
        XCTAssertEqual(firstNode.service.tags.first ?? "", "production")
        
        
        // deregister node
        consul.agentDeregisterService("testNodesForService")
    }
    
    func testBaseURLForNodeWithService() {
        let consul = Consul()
        
        // register node
        let service = ConsulAgentServiceInput(name: "testBaseURLForNodeWithService",
                                              id: "testBaseURLForNodeWithService",
                                              tags: ["production", "https"],
                                              address: "123.123.123.123",
                                              port: 1337)
        let registerResult = consul.agentRegisterService(service)
        switch registerResult {
        case .success: break
        case .failure: XCTFail("Failed register service")
        }
        
        guard let baseURL = CVServiceRegistry.sharedInstance.baseURLForNodeWithService("testBaseURLForNodeWithService", tag: "production") else {
            XCTFail("Failed getting base url")
            return
        }
        XCTAssertEqual(baseURL.absoluteString, "https://123.123.123.123:1337")
        
        // deregister node
        consul.agentDeregisterService("testBaseURLForNodeWithService")
    }

}
