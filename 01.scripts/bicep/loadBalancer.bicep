/* ------------------------------------------------------------------------------------------------
    Bicep for creating an internal load balancer
    -------------------------------------------------
    The profiles array parameter is meant to include the necessary information for probes and rules
    Below is an example profiles array with LB frontend access on port 80 or 443, and translates to 
    backend ports 8080 and 10443 respectively. Both backend ports will be used in probing.

      param lbProfiles array = [
        {
          frontEndPort: 80
          backendPort: 8080
        }
        {
          frontEndPort: 443
          backendPort: 10443
        }
      ]

  -------------------------------------------------------------------------------------------------- */
param loadBalancerName string
param privateFrontEndIP string
param vmProperties array
param subNetId string
param location string = resourceGroup().location
param profiles array = [
  {
    name: 'PublicHTTP'
    frontendPort: 80
    backendPort: 8080
  }
]

resource BEPool 'Microsoft.Network/loadBalancers/backendAddressPools@2021-02-01' = {
  name: 'BackendPool'
  parent: LB
  properties: {
    loadBalancerBackendAddresses: [ for vmProperty in vmProperties: {
      name: vmProperty.name
      properties: {
        ipAddress: vmProperty.privateIp
      }
    }]
  }
}

resource LB 'Microsoft.Network/loadBalancers@2021-02-01' = {
  name: loadBalancerName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    probes: [ for item in profiles: { 
      name: 'Probe-${item.name}'
      properties: {
        protocol: 'Tcp'
        port: item.backendPort
        intervalInSeconds: 15
        numberOfProbes: 2
      }
    }]
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontend'
        properties: {
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: subNetId
          }
          privateIPAddress: privateFrontEndIP
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'BackendPool'
      }
    ]
    loadBalancingRules: [ for item in profiles: { 
      name: 'LBRule-${item.name}'
      properties: {
        frontendIPConfiguration: {
          id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', loadBalancerName, 'LoadBalancerFrontend')
        }
        backendAddressPool: {
          id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, 'BackendPool')
        }
        probe: {
          id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerName, 'Probe-${item.name}')
        }
        protocol: 'Tcp'
        frontendPort: item.frontendPort
        backendPort: item.backendPort
        idleTimeoutInMinutes: 15
      }
    }]
  }
}
