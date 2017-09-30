//
//  DropletExtensions.swift
//  CVServiceRegistry
//
//  Created by Christoph Pageler on 30.09.17.
//

import Vapor
import ConsulSwift

public extension Droplet {
    
    
    /// Registers service in local Consul
    /// Blocks thread (not async)
    ///
    /// - Returns: Error on failure
    /// - Throws: throws error when config is not readable
    public func registerService() throws -> Error? {
        let serviceName = try readConfigServiceName()
        let serviceId = config["consul"]?["service"]?["id"]?.string
        let serviceTags = config["consul"]?["service"]?["tags"]?.array?.map{ $0.string }.flatMap { $0 }
        
        return registerServiceWith(name: serviceName, id: serviceId, tags: serviceTags)
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
                             tags: [String]? = nil) -> Error? {
        let consul = Consul()
        let service = ConsulAgentServiceInput(name: name,
                                              id: id,
                                              tags: tags ?? [],
                                              address: nil,
                                              port: nil)
        let result = consul.agentRegisterService(service)
        
        switch result {
        case .success: return nil
        case .failure(let error): return error
        }
    }
    
    /// Deregisters service in local Consul
    /// Blocks thread (not async)
    ///
    /// - Returns: Error on failure
    /// - Throws: throws error when config is not readable
    public func deregisterService() throws -> Error? {
        // read service id from config
        var possibleServiceId = config["consul"]?["service"]?["id"]?.string
        
        // when no service id was found in config, try to use the service name
        if possibleServiceId == nil {
            possibleServiceId = try readConfigServiceName()
        }
        
        guard let serviceId = possibleServiceId else {
            throw Abort(.internalServerError,
                        reason: "could not determine service id",
                        suggestedFixes: [
                            "Add consul.json to your config directory",
                            "- add service.id",
                            "or",
                            "- add service.name"
                ])
        }
        
        return deregisterServiceWith(id: serviceId)
    }
    
    /// Deregisters service in local Consul
    /// Blocks thread (not async)
    ///
    /// - Parameter id: id of service
    /// - Returns: Error on failure
    public func deregisterServiceWith(id: String) -> Error? {
        let consul = Consul()
        let result = consul.agentDeregisterService(id)
        
        switch result {
        case .success: return nil
        case .failure(let error): return error
        }
    }
    
    private func readConfigServiceName() throws -> String {
        guard let serviceName = config["consul"]?["service"]?["name"]?.string else {
            throw Abort(.internalServerError,
                        reason: "could not read config from consul.service.name",
                        suggestedFixes: [
                            "Add consul.json to your config directory",
                            "- add service.name"
                ])
        }
        
        return serviceName
    }
    
}
