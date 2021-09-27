// ------------------------------------------------------------------------------------------------
// Bicep for generating the infrastructure resources for the bastion service: 
//  - Bastion host
//  - Public IP (for Bastion host)
//  - Network security group (and rules)
//  - Virtual Network
//  - Subnet
// ------------------------------------------------------------------------------------------------
@description('Identifier suffix for resource name')
param identifier string = ''
@description('Optional Bastion Hostname')
param bastionHostName string = 'BastionHost-${identifier}'
@description('Optional VNET name')
param virtualNetworkName string = 'Bastion-VNET-${identifier}'
@description('Optional VNET IP address range')
param vNetIpPrefix string = '10.1.0.0/16'
@description('Optional Subnet address range for Bastion Subnet')
param bastionSubnetIpPrefix string = '10.1.1.0/26'
@description('Optional Subnet address range for WorkLoad Subnet')
param workLoadSubnetIpPrefix string = '10.1.0.0/24'

@description('Defult rg scope')
param location string = resourceGroup().location

// Network security group
resource NSG 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: 'Bastion-VNET-NSG-${identifier}'
  location: location
  properties: {
    securityRules: [
      // Inbound
      {
        name: 'AllowHttpsInbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowGatewayManagerInbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowAzureLoadBalancerInbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 140
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowBastionHostCommunication1'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '5701'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 150
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowBastionHostCommunication2'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8080'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 151
          direction: 'Inbound'
        }
      }
      // Outbound
      {
        name: 'AllowSshRdpOutbound1'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowSshRdpOutbound2'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 101
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowAzureCloudOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowBastionCommunication1'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '5701'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 120
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowBastionCommunication2'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '8080'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 121
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowGetSessionInformation'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 130
          direction: 'Outbound'
        }
      }
    ]
  }
}

// Public IP
resource PublicIP 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: 'Bastion-IP-${identifier}'
  location: location
  sku: {
    name: 'Standard'
  }
  zones: [ 
    '1' 
  ]
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Virtual Network
resource VNET 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: virtualNetworkName
  location: location
  dependsOn:[
    NSG
  ]
  properties: {
    subnets:[
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: bastionSubnetIpPrefix
          networkSecurityGroup: {
            id: NSG.id
          }
        }
      }
      {
        name: 'WorkLoadSubnet'
        properties: {
          networkSecurityGroup: {
            id: NSG.id
          }
          addressPrefix: workLoadSubnetIpPrefix
        }
      }
    ]
    addressSpace: {
      addressPrefixes: [
        vNetIpPrefix
      ]
    }
  }
}

// Bastion Host
resource bastionHost 'Microsoft.Network/bastionHosts@2021-02-01' = {
  name: bastionHostName
  location: location
  dependsOn: [
    PublicIP
    VNET
  ]
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: VNET.properties.subnets[0].id
          }
          publicIPAddress: {
            id: PublicIP.id
          }
        }
      }
    ]
  }
}

output vNetId string = VNET.id
output workLoadSubNetId string = VNET.properties.subnets[1].id
