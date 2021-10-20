/* ===========================================================================================
   Main bicep template for setting up a 3-node API Gateway cluster
    - Creates a Resource Group
    - Creates a Bastion Host Service (with associated virtual network, subnets, security rules)
    - Creates an availability Set for below workload nodes
    - Creates a VM x 3 workload nodes (APIGW + TSA)
    - Creates a VM for Admin (Windows)
    - Creates a KeyVault
      Access Policies to the Key Vault is based on the workload VM nodes + user performing deployment
    - Creates a Load Balancer
      
   ===========================================================================================*/

// --------------------------------------------------------------
// Identifier used for suffixing resources and deployments
// --------------------------------------------------------------
param identifier string

// --------------------------------------------------------------
// Creates the new Resource Group
// --------------------------------------------------------------
targetScope = 'subscription'
param resourceGroupName string
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: deployment().location
}

// --------------------------------------------------------------
// Creates the Bastion Host Service with associated VNet, Subnet and network security rules
// --------------------------------------------------------------
module bastionService '../../../../../../01.scripts/bicep/bastion.bicep' = {
  scope: resourceGroup
  name: 'BastionService'
}

// --------------------------------------------------------------
// Create an availability Set
// --------------------------------------------------------------
module availabilitySet '../../../../../../01.scripts/bicep/availabilitySet.bicep' = {
  scope: resourceGroup
  name: 'AvailabilitySet'
  params: {
    availabilitySetName: 'AvailabilitySet'
    numFaultDomains: 3
    numUpdateDomains: 5
  }
}

// --------------------------------------------------------------
// Creates the workload vm's
// --------------------------------------------------------------
param vmImageIdentifier string = 'OpenLogic:CentOS:8_3:8.3.2021020400'
param vmImageSizeIdentifier string = 'Standard_B2ms'
param vmPublisher string = split(vmImageIdentifier,':')[0]
param vmOffer string = split(vmImageIdentifier,':')[1]
param vmSKU string = split(vmImageIdentifier,':')[2]
param vmVersion string = split(vmImageIdentifier,':')[3]

param workLoadStorageProfile object = {
  imageReference: {
    publisher: vmPublisher
    offer: vmOffer
    sku: vmSKU
    version: vmVersion
  }
}

param userName string = 'sag'
@minLength(6)
@secure()
param userPass string
param wlNodes array = [
  'apigw01'
  'apigw02'
  'apigw03'
]
module workLoadVMs '../../../../../../01.scripts/bicep/virtualMachineAvSet.bicep' = {
  scope: resourceGroup
  name: 'VM-WorkLoad'
  params: {
    availabilitySetId: availabilitySet.outputs.id
    virtualMachineNames: wlNodes
    adminUsername: userName
    adminPassword: userPass
    storageProfile: workLoadStorageProfile
    imageSizeIdentifier: vmImageSizeIdentifier
    subNetId: bastionService.outputs.workLoadSubNetId
  }
}

// --------------------------------------------------------------
// Creates the Admin vm - default windows + version + size
// --------------------------------------------------------------
param adminNodes array = [
  'admin'
]
param adminStorageProfile object = {
  imageReference: {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'Windows-10'
    sku: '20h2-pro-g2'
    version: 'latest'
  }
}
module virtualMachine '../../../../../../01.scripts/bicep/virtualMachineSimple.bicep' = {
  scope: resourceGroup
  name: 'VM-Admin'
  params: {
    virtualMachineNames: adminNodes
    adminUsername: userName
    adminPassword: userPass
    storageProfile: adminStorageProfile
    imageSizeIdentifier: 'Standard_B1ms'
    subNetId: bastionService.outputs.workLoadSubNetId
  }
}

// --------------------------------------------------------------
// Creates a keyvault - and adds identityKeys to access policies
// --------------------------------------------------------------
param azureUserId string
var userIdentity = [
  {
    name: 'principalId'
    identityKey: azureUserId
  }
]

module keyVault '../../../../../../01.scripts/bicep/keyVault.bicep' = {
  scope: resourceGroup
  name: 'KeyVault-${identifier}'
  params: {
    keyVaultName: 'KeyVault-${identifier}'
    identities: concat(userIdentity, workLoadVMs.outputs.vmProperties)
  }
}


// --------------------------------------------------------------
// Creates the internal Load Balancer with associated rules
// --------------------------------------------------------------
param loadBalancerFrontEndAddress string = '10.1.0.100'
param lbProfiles array = [
  {
    name: 'PublicHTTP'
    protocol: 'Tcp'
    frontendPort: 80
    backendPort: 9072
  }
  {
    name: 'PublicHTTPS'
    protocol: 'Tcp'
    frontendPort: 443
    backendPort: 9073
  }
]

module loadBalancer '../../../../../../01.scripts/bicep/loadBalancer.bicep' = {
  scope: resourceGroup
  name: 'LoadBalancer'
  params: {
    loadBalancerName: 'LoadBalancer'
    privateFrontEndIP: loadBalancerFrontEndAddress
    vmProperties: workLoadVMs.outputs.vmProperties
    vNetId: bastionService.outputs.vNetId
    subNetId: bastionService.outputs.workLoadSubNetId
    lbProfiles: lbProfiles
  }
}

output workLoadVMs array = wlNodes 
