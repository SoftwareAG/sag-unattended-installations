// ------------------------------------------------------------------------------------------------
// Bicep for creating a file share on an existing storage resource
// ------------------------------------------------------------------------------------------------
@description('Storage Account Name')
param storageAccountName string
param fileShareName string
param fileShareSize int

resource Storage 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storageAccountName
}

resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2021-04-01' = {
  name: 'default'
  parent: Storage
}
resource symbolicname 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-02-01' = {
  name: fileShareName
  parent: fileService
  properties: {
    metadata: {}
    shareQuota: fileShareSize
    enabledProtocols: 'SMB'
  }
}

