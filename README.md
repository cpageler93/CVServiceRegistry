# CVServiceRegistry

CVServiceRegistry is a Service Registry based on Consul and Vapor.

## Usage

### Register your Service


```swift
let registerError = try drop.registerService()
```

### List Datacenters

```swift
// [ConsulCatalogDatacenter]?
let datacenters = CVServiceRegistry.sharedInstance.datacenters()
```

### Get Nodes for Service ID

```swift
// [ConsulCatalogNodeWithServiceAndChecks]?
let nodes = CVServiceRegistry.sharedInstance.nodesForService("authService", tag: "production")
```

### Get BaseURL for Service ID (in same datacenter and nearest to the current node)

```swift
// https://127.0.0.1:8050
let baseURL = CVServiceRegistry.sharedInstance.baseURLForNodeWithService("authService", tag: "production")
```

## Configure

Config/consul.json

```json
{
    "service": {
        "id": "idOfYourService",
        "name": "Name of your Service",
        "tags": [
            "production",
            "v1",
            "https"
        ]
    }
}
```