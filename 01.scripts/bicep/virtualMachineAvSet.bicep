// ------------------------------------------------------------------------------------------------
// Bicep for provisioning of a virtual machine within an Availability Set
// ------------------------------------------------------------------------------------------------
@description('Username for the Virtual Machine.')
param adminUsername string

@description('Password for the User.')
@secure()
param adminPassword string

param virtualMachineNames array
param storageProfile object
param imageSizeIdentifier string

param subNetId string
param location string = resourceGroup().location

param availabilitySetId string

resource NIC 'Microsoft.Network/networkInterfaces@2021-02-01' = [ for virtualMachineName in virtualMachineNames: {
  name: '${virtualMachineName}-NIC'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'localIPConfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subNetId
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
  }
}]

resource VM 'Microsoft.Compute/virtualMachines@2021-03-01' = [ for (virtualMachineName,i) in virtualMachineNames: {
  name: virtualMachineName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: imageSizeIdentifier
    }
    osProfile: {
      computerName: virtualMachineName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: storageProfile
    networkProfile: {
      networkInterfaces: [
        {
          id: NIC[i].id
        }
      ]
    }
    availabilitySet: {
      id: availabilitySetId
    }
  }
}]

output vmProperties array = [ for (virtualMachineName,i) in virtualMachineNames: {
  name: virtualMachineName
  id: VM[i].id
  privateIp: NIC[i].properties.ipConfigurations[0].properties.privateIPAddress 
  identityKey: VM[i].identity.principalId
}] 
