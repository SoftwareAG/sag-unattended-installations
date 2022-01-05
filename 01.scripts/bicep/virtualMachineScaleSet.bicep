/* ------------------------------------------------------------------------------------------------
    Bicep for provisioning of a virtual machine scale set
    -------------------------------------------------
    This deployment will create a separate Load Balancer in front of the VM scaleset
    ScaleSet is based on an capacity count, then dynamically scaled based on a CPU metric rule

    To support oubound traffic (e.g. for installing utilities on the VMs), a separate public Load Balancer
    with a public IP is required, configured for outbound traffic only.

    The loadBalancerProfiles array parameter is meant to include the necessary information for probes and rules
    Below is an example profiles array with LB frontend access on port 80 or 443, and translates to 
    backend ports 8080 and 10443 respectively. Both backend ports will be used in probing.

      param lbProfiles array = [
        {
          name: 'PublicHTTP'
          frontEndPort: 80
          backendPort: 8080
        }
        {
          name: 'PublicHTTPS'
          frontEndPort: 443
          backendPort: 10443
        }
      ]

  -------------------------------------------------------------------------------------------------- */
@description('Identifier suffix for resource name')
param identifier string

// ------------------------------------------------------------------
// Public Load Balancer with Public IP for outbound communication
// ------------------------------------------------------------------
resource PublicIP 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: 'FrontendIP-Outbound-Public'
  location: resourceGroup().location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  zones: [
    '1' 
    '2' 
    '3'
  ]
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource PublicLB 'Microsoft.Network/loadBalancers@2021-02-01' = {
  name: 'LoadBalancer-Outbound-Public'
  location: resourceGroup().location
  dependsOn: [
    PublicIP
  ]
  sku: {
    name: 'Standard'
  }
  properties: {
    
    frontendIPConfigurations: [
      {
        name: 'LBFrontendIPConfig-Public'
        properties: {
          publicIPAddress: {
            id: PublicIP.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'BackEndPool-Public'
      }
    ]
    outboundRules: [
      {
        name: 'ScaleSetOutboundRule'
        properties: {
          allocatedOutboundPorts: 10000
          protocol: 'All'
          enableTcpReset: false
          idleTimeoutInMinutes: 5
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'LoadBalancer-Outbound-Public', 'BackEndPool-Public')
          }
          frontendIPConfigurations: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', 'LoadBalancer-Outbound-Public', 'LBFrontendIPConfig-Public')
            }
          ]
        }
      }
    ]
  }
}

// ------------------------------------------------
// Internal (Private) Load Balancer
// ------------------------------------------------
param privateFrontEndIP string
param subNetId string
param loadBalancerProfiles array = [
  {
    name: 'PublicHTTP'
    frontendPort: 80
    backendPort: 8080
  }
]
// ------------------------------------------------
resource PrivateLB 'Microsoft.Network/loadBalancers@2021-02-01' = {
  name: 'LoadBalancer-Private'
  location: resourceGroup().location
  sku: {
    name: 'Standard'
  }
  properties: {
    probes: [ for item in loadBalancerProfiles: { 
      name: 'Probe-${item.name}'
      properties: {
        protocol: 'Tcp'
        port: item.backendPort
        intervalInSeconds: 15
        numberOfProbes: 2
      }
    }]
    frontendIPConfigurations: [
      {
        name: 'LBFrontendIPConfig-Private'
        properties: {
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: subNetId
          }
          privateIPAddress: privateFrontEndIP
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'BackEndPool-Private'
      }
    ]
    loadBalancingRules: [ for item in loadBalancerProfiles: { 
      name: 'LBRule-${item.name}'
      properties: {
        frontendIPConfiguration: {
          id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', 'LoadBalancer-Private', 'LBFrontendIPConfig-Private')
        }
        backendAddressPool: {
          id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'LoadBalancer-Private', 'BackEndPool-Private')
        }
        probe: {
          id: resourceId('Microsoft.Network/loadBalancers/probes', 'LoadBalancer-Private', 'Probe-${item.name}')
        }
        protocol: 'Tcp'
        frontendPort: item.frontendPort
        backendPort: item.backendPort
        idleTimeoutInMinutes: 15
        disableOutboundSnat: false
      }
    }]
  }
}

// ------------------------------------------------
// ScaleSet
// ------------------------------------------------
param scaleSetName string

@description('Capacity (number of VM nodes) of scaleset')
param vmScaleSetCapacity int

@description('Username for the Virtual Machine.')
param adminUsername string

param suif_assets_mount string = '/assets'
param suif_vm_init_script string = 'vm_init.sh'

@description('The SUIF home location for scripts (used during initialization)')
param suif_scripts_home string

param storageLocation string
param azStorageVolume string
param azStorageAccount string
param azStorageAccountKey string

@description('Password for the User.')
@secure()
param adminPassword string

param hostNamePrefix string
param storageProfile object
param imageSizeIdentifier string
// ------------------------------------------------
resource VMSS 'Microsoft.Compute/virtualMachineScaleSets@2021-04-01' = {
  name: scaleSetName
  location: resourceGroup().location
  sku: {
    name: imageSizeIdentifier
    tier: 'Standard'
    capacity: vmScaleSetCapacity
  }
  zones: [
    '1' 
    '2' 
    '3'
  ]
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    upgradePolicy: {
      mode: 'Manual'
    }
    overprovision: false
    zoneBalance: true
    virtualMachineProfile: {
      storageProfile: storageProfile
      osProfile: {
        computerNamePrefix: hostNamePrefix
        adminUsername: adminUsername
        adminPassword: adminPassword
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'NIC-${identifier}'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'IPConfig-${identifier}'
                  properties: {
                    subnet: {
                      id: subNetId
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: '${PublicLB.id}/backendAddressPools/BackEndPool-Public'
                      }
                      {
                        id: '${PrivateLB.id}/backendAddressPools/BackEndPool-Private'
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
      extensionProfile: {
        extensions: [
          {
            name: 'InitializeVM'
            properties: {
              publisher: 'Microsoft.Azure.Extensions'
              type: 'CustomScript'
              typeHandlerVersion: '2.0'
              autoUpgradeMinorVersion: true
              protectedSettings: {
                commandToExecute: 'dnf -y install cifs-utils; mkdir -p ${suif_assets_mount}; chown -R sag:sag ${suif_assets_mount}; mount -t cifs ${storageLocation}${azStorageVolume}${suif_assets_mount} ${suif_assets_mount} -o username=${azStorageAccount},password=${azStorageAccountKey},uid=1000,gid=1000,serverino; ${suif_scripts_home}/${suif_vm_init_script} ${identifier} ${adminPassword}'
              }
            }
          }
        ]
      }
    }
  }
}
// ------------------------------------------------
// AutoScaling Properties
// ------------------------------------------------
resource autoScaleSettings 'Microsoft.Insights/autoscalesettings@2015-04-01' = {
  name: 'CpuAutoScale'
  location: resourceGroup().location
  properties: {
    name: 'CpuAutoScale'
    targetResourceUri: VMSS.id
    enabled: true
    profiles: [
      {
        name: 'Profile1'
        capacity: {
          minimum: '3'
          maximum: '10'
          default: '3'
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricNamespace: ''
              metricResourceUri: VMSS.id
              timeGrain: 'PT1M'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 60
              statistic: 'Average'
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricNamespace: ''
              metricResourceUri: VMSS.id
              timeGrain: 'PT1M'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 30
              statistic: 'Average'
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
        ]
      }
    ]
  }
}
output vmScaleSetPrincipalId string = VMSS.identity.principalId
