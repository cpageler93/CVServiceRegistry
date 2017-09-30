//
//  CVServiceRegistry.swift
//  CVServiceRegistry
//
//  Created by Christoph Pageler on 30.09.17.
//

import Vapor
import ConsulSwift

public class CVServiceRegistry {
    
    public static let sharedInstance = CVServiceRegistry()
    
    private let consul = Consul()
    
    public func register(droplet: Droplet) throws -> Error? {
        return try droplet.registerService()
    }
    
    public func deregister(droplet: Droplet) throws -> Error? {
        return try droplet.deregisterService()
    }
    
    public func datacenters() -> [ConsulCatalogDatacenter]? {
        let result = consul.catalogDatacenters()
        switch result {
        case .success(let datacenters):
            return datacenters
        case .failure:
            return nil
        }
    }
    
}
