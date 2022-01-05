// ===========================================================================================
// Bicep template for preparing infrastructure:
//  - Creates a storage volume on existing storage resource
//  - Creates directories on file share volume
//  - Upload files to target directories
// ===========================================================================================
targetScope = 'resourceGroup'

// --------------------------------------------------------------
// Parameters
// --------------------------------------------------------------
param storageAccountName string
param fileShareName string

// --------------------------------------------------------------
// Creates a File share on existing storage account
// --------------------------------------------------------------
module fileShare '../../../../../../01.scripts/bicep/fileShare.bicep' = {
  scope: resourceGroup()
  name: 'FileShare'
  params: {
    storageAccountName: storageAccountName
    fileShareName: fileShareName
    fileShareSize: 256
  }
}
