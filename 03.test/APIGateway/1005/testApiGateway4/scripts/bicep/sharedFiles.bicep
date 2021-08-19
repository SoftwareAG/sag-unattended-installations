// ===========================================================================================
// Bicep template for preparing infrastructure:
//  - Creates a storage volume on existing storage resource
//  - Creates directories on file share volume
//  - Upload files to target directories
// ===========================================================================================
targetScope = 'resourceGroup'
// --------------------------------------------------------------
// Identifier used for suffixing resources and deployments
// --------------------------------------------------------------
param identifier string

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
  name: 'FileShare-${identifier}'
  params: {
    storageAccountName: storageAccountName
    fileShareName: fileShareName
    fileShareSize: 256
  }
}
