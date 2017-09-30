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
    /// - Throws: throws when config is not readable
    public func registerService() throws -> Error? {
        let serviceName = try readConfigServiceName()
        let serviceId = config["consul"]?["service"]?["id"]?.string
        let serviceTags = config["consul"]?["service"]?["tags"]?.array?.map{ $0.string }.flatMap { $0 }
        
        return CVServiceRegistry.sharedInstance.registerServiceWith(name: serviceName,
                                                                    id: serviceId,
                                                                    tags: serviceTags)
    }
    
    /// Deregisters service in local Consul
    /// Blocks thread (not async)
    ///
    /// - Returns: Error on failure
    /// - Throws: throws when config is not readable
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
        
        return CVServiceRegistry.sharedInstance.deregisterServiceWith(id: serviceId)
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
