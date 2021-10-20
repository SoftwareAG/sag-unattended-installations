// ------------------------------------------------------------------------------------------------
// Bicep for provisioning of a virtual machine. 
// ------------------------------------------------------------------------------------------------
@description('Identifier suffix for resource name')
param identifier string

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

param suif_assets_mount string = '/assets'
param suif_vm_init_script string = 'vm_init.sh'

@description('The SUIF home location for scripts (used during initialization)')
param suif_scripts_home string

param storageLocation string
param azStorageVolume string
param azStorageAccount string
param azStorageAccountKey string


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
  zones: [
    '1'
  ]
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
  }
}]

resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = [ for (virtualMachineName,i) in virtualMachineNames: {
  name: '${virtualMachineName}/installcustomscript'
  location: location
  dependsOn: [
    VM[i]
  ]
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      commandToExecute: 'dnf -y install cifs-utils; mkdir -p ${suif_assets_mount}; chown -R sag:sag ${suif_assets_mount}; mount -t cifs ${storageLocation}${azStorageVolume}${suif_assets_mount} ${suif_assets_mount} -o username=${azStorageAccount},password=${azStorageAccountKey},uid=1000,gid=1000,serverino; ${suif_scripts_home}/${suif_vm_init_script} ${identifier} ${adminPassword}'
    }
  }
}]

output vmProperties array = [ for (virtualMachineName,i) in virtualMachineNames: {
  name: virtualMachineName
  id: VM[i].id
  privateIp: NIC[i].properties.ipConfigurations[0].properties.privateIPAddress 
  identityKey: VM[i].identity.principalId
}] 
