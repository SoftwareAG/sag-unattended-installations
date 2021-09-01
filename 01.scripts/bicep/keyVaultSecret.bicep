// ------------------------------------------------------------------------------------------------
// Bicep for adding a secret to a Key Vault
// ------------------------------------------------------------------------------------------------
@description('KeyVault Name')
param keyVaultName string
param secretName string
@secure()
param secretValue string

resource KeyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: keyVaultName
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  name: '${KeyVault.name}/${secretName}'
  properties: {
    value: secretValue
    attributes: {
      enabled: true
    }
  }
}
