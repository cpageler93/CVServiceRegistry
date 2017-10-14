//
//  CVServiceRegistry.swift
//  CVServiceRegistry
//
//  Created by Christoph Pageler on 30.09.17.
//

import Vapor
import ConsulSwift
import Foundation


public class CVServiceRegistry {
    
    public static let sharedInstance = CVServiceRegistry()
    private let consul = Consul()
    private var currentAgentConfiguration: ConsulAgentConfiguration?
    
    private init() {
        initConsulConfiguration()
    }
    
    private func initConsulConfiguration() {
        let configurationResult = consul.agentReadConfiguration()
        
        switch configurationResult {
        case .success(let configuration):
            currentAgentConfiguration = configuration
        case .failure:
            break
        }
    }
    
    /// Registers droplet as service in local Consul
    ///
    /// - Parameter droplet: droplet to register
    /// - Returns: Error on failure
    /// - Throws: throws when config is not readable
    public func register(droplet: Droplet) throws -> Error? {
        return try droplet.registerService()
    }
    
    /// Deregisters droplet as service in local Consul
    ///
    /// - Parameter droplet: droplet to deregister
    /// - Returns: Error on failure
    /// - Throws: throws when config is not readable
    public func deregister(droplet: Droplet) throws -> Error? {
        return try droplet.deregisterService()
    }
    
    /// Registers service in local Consul
    /// Blocks thread (not async)
    ///
    /// - Parameters:
    ///   - name: name of service
    ///   - id: id of service
    ///   - tags: tags of service
    /// - Returns: Error on failure
    public func registerServiceWith(name: String,
                                    id: String? = nil,
                                    tags: [String]? = nil,
                                    host: String? = nil,
                                    port portString: String? = nil) -> Error? {
        // apply default values for address
        let host = host ?? "0.0.0.0"
        var port = 8080 // default
        if let ps = portString, let portStringAsInt = Int(ps) {
            port = portStringAsInt
        }
        
        let service = ConsulAgentServiceInput(name: name,
                                              id: id,
                                              tags: tags ?? [],
                                              address: host,
                                              port: port)
        let result = consul.agentRegisterService(service)
        
        switch result {
        case .success:
            // register check
            let checkProtocol = (tags?.contains("https") ?? false) ? "https" : "http"
            let checkHost = host
            let checkPort = String(port)
            let serviceId = id ?? name
            let checkId = "\(serviceId).check.vapor.running"
            let checkInput = ConsulAgentCheckInput(name: "Vapor Running - \(name)", http: "\(checkProtocol)://\(checkHost):\(checkPort)", interval: "10s")
            checkInput.serviceID = serviceId
            checkInput.id = checkId
            let checkResult = consul.agentRegisterCheck(checkInput)
            
            switch checkResult {
            case .success: return nil
            case .failure(let error): return error
            }
            
        case .failure(let error): return error
        }
    }
    
    /// Deregisters service in local Consul
    /// Blocks thread (not async)
    ///
    /// - Parameter id: id of service
    /// - Returns: Error on failure
    public func deregisterServiceWith(id: String) -> Error? {
        let result = consul.agentDeregisterService(id)
        
        switch result {
        case .success: return nil
        case .failure(let error): return error
        }
    }
    
    /// Datacenters from Consul
    ///
    /// - Returns: Array of Consul Datacenters
    public func datacenters() -> [ConsulCatalogDatacenter]? {
        let result = consul.catalogDatacenters()
        
        switch result {
        case .success(let datacenters): return datacenters
        case .failure: return nil
        }
    }
    
    /// Returns healty nodes with a given service, tags, ...
    ///
    /// - Parameters:
    ///   - service: the service id you are searching for
    ///   - tag: a tag the service needs to have
    ///   - datacenter: datacenter of the service
    ///   - near: service near to
    /// - Returns: Array of Nodes
    public func nodesForService(_ service: String,
                                tag: String? = nil,
                                datacenter: String? = nil,
                                near: String? = nil) -> [ConsulCatalogNodeWithServiceAndChecks]? {
        let result = consul.healthNodesFor(service: service,
                                           passing: true,
                                           tag: tag,
                                           datacenter: datacenter,
                                           near: near)
        
        switch result {
        case .success(let nodes): return nodes
        case .failure: return nil
        }
    }
    
    
    /// Returns BaseURL for a given service, tags, ...
    /// for example: http://127.0.0.1:8080
    ///
    /// - Parameters:
    ///   - service: the service id you are searching for
    ///   - tag: a tag the service needs to have
    /// - Returns: an url for the service
    public func baseURLForNodeWithService(_ service: String,
                                          tag: String? = nil) -> URL? {
    
        // find nodes
        guard let nodes = nodesForService(service,
                                          tag: tag,
                                          datacenter: currentAgentConfiguration?.datacenter,
                                          near: currentAgentConfiguration?.nodeID) else {
                                            return nil
        }
        
        // find first node
        guard let firstNode = nodes.first else {
            return nil
        }
        
        // determine scheme
        let scheme = firstNode.service.tags.contains("https") ? "https": "http"
        
        // build and return url
        let urlString = "\(scheme)://\(firstNode.service.address):\(firstNode.service.port)"
        return URL(string: urlString)
    }
    
}
