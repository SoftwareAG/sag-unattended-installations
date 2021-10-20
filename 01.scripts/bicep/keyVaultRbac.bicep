// ------------------------------------------------------------------------------------------------
/* Bicep for provisioning of a key vault with RBAC authorization. 
  -----------------------------------------------------------------------------------------------*/
@description('KeyVault Name')
param keyVaultName string

resource KeyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyVaultName
  location: resourceGroup().location
  properties: {
    createMode: 'default'
    enabledForTemplateDeployment: true
    enablePurgeProtection: false
    enableRbacAuthorization: true
    enableSoftDelete: true
    sku: {
      family: 'A'
      name: 'standard'
    }
    publicNetworkAccess: 'enabled'
    tenantId: subscription().tenantId
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      ipRules: []
      virtualNetworkRules: []
    }
  }
}
output keyVaultId string = KeyVault.id
