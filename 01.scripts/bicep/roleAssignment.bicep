// ------------------------------------------------------------------------------------------------
/* Bicep for assigning user/scaleset identities to RBAC KeyVault roles. 
  -----------------------------------------------------------------------------------------------*/
@description('Role Definition ID')
// param roleName string = 'Key Vault Secrets Officer'
param userId string
param scaleSetId string

resource RoleAssignmentSecrets 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: '${guid(resourceGroup().name, 'secrets')}'
  properties: {
    roleDefinitionId: '${subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')}'
    principalId: userId
    principalType: 'User'
  }
}

resource RoleAssignmentScaleSet 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: '${guid(resourceGroup().name, 'Secrets')}'
  properties: {
    roleDefinitionId: '${subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')}'
    principalId: scaleSetId
    principalType: 'ServicePrincipal'
  }
}

