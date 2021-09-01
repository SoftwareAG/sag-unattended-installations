// ------------------------------------------------------------------------------------------------
/* Bicep for provisioning of a key vault. 
  
  Expects a list of identity keys to set access policies:
    param identities array = [
      {
        identityKey: XXX
      }
      {
        identityKey: YYY
      }
    ]

  -----------------------------------------------------------------------------------------------*/
@description('KeyVault Name')
param keyVaultName string
param identities array
// param userId string

resource KeyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyVaultName
  location: resourceGroup().location
  properties: {
    createMode: 'default'
    enabledForTemplateDeployment: true
    sku: {
      family: 'A'
      name: 'standard'
    }
    publicNetworkAccess: 'enabled'
    accessPolicies: [ for identity in identities: {
      objectId: identity.identityKey
      permissions: {
        certificates: [
          'all'
        ]
        keys: [
          'all'
        ]
        secrets: [
          'all'
        ]
        storage: [
          'all'
        ]
      }
      tenantId: subscription().tenantId
    }]
    tenantId: subscription().tenantId
    enableSoftDelete: false
  }
}
/*
resource AccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2021-06-01-preview' = {
  name: '${KeyVault.name}/UserPolicy'
  dependsOn:[
    KeyVault
  ]
  properties: {
    accessPolicies: [
      {
        objectId: userId
        permissions: {
          certificates: [
            'create'
            'get'
            'list'
          ]
          keys: [
            'create'
            'get'
            'list'
          ]
          secrets: [
            'get'
            'list'
            'set'
          ]
          storage: [
            'get'
            'list'
            'set'
          ]
        }
        tenantId: subscription().tenantId
      }
    ]
  }
}
*/
output keyVaultName string = KeyVault.name
