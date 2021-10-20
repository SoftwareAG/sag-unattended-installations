/* ------------------------------------------------------------------------------------------------
    Bicep for creating an availability set
    -------------------------------------------------
    Use this resource and reference the id when creating the virtual machines
  -------------------------------------------------------------------------------------------------- */
param availabilitySetName string
param numFaultDomains int
param numUpdateDomains int
param location string = resourceGroup().location

resource AvailabilitySet 'Microsoft.Compute/availabilitySets@2021-04-01' = {
  name: availabilitySetName
  location: location
  properties: {
    platformFaultDomainCount: numFaultDomains
    platformUpdateDomainCount: numUpdateDomains
  }
  sku:{
    name: 'Aligned'
  }
}

output id string = AvailabilitySet.id 
