// Deployable rebuild of the Azure Secure Network Lab (same design as export/main.bicep).
// Cleaned up from the portal export: removed self-references and duplicate child resources,
// hardcoded OS disk names/IDs and read-only properties; added an admin password parameter.
//
// Deploy:
//   az group create -n rg-secure-network-lab -l eastus
//   az deployment group what-if -g rg-secure-network-lab -f deploy.bicep
//   az deployment group create  -g rg-secure-network-lab -f deploy.bicep
// The CLI prompts for adminPassword, so it never lands in your shell history.

@description('Region of the original lab')
param location string = 'eastus'

@description('Admin user for both VMs')
param adminUsername string = 'AzureAdmin'

@secure()
@description('Admin password for both VMs: 12+ characters, 3 of: upper, lower, digit, symbol')
param adminPassword string

@description('VM size used in the original lab')
param vmSize string = 'Standard_D2s_v4'

var vms = [
  {
    name: 'VM1'
    subnet: 'frontend'
    useAsg: true
  }
  {
    name: 'VM2'
    subnet: 'backend'
    useAsg: false
  }
]

// ---------------- Virtual networks ----------------

resource hubVnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'hub-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet' // unused in this lab, as in the original
        properties: {
          addressPrefix: '10.0.0.0/26'
          defaultOutboundAccess: false
        }
      }
    ]
  }
}

resource appVnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'app-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    dhcpOptions: {
      dnsServers: [
        '1.1.1.1'
        '1.0.0.1'
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.1.63.0/26'
          defaultOutboundAccess: false
        }
      }
      {
        name: 'frontend'
        properties: {
          addressPrefix: '10.1.0.0/24'
          routeTable: {
            id: routeTable.id
          }
          defaultOutboundAccess: false
        }
      }
      {
        name: 'backend'
        properties: {
          addressPrefix: '10.1.1.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
          routeTable: {
            id: routeTable.id
          }
          defaultOutboundAccess: false
        }
      }
    ]
  }
}

// Peering names kept exactly as in the original lab.
// Both wait for the firewall, so Azure doesn't reject them while app-vnet is still being updated.
resource peeringOnHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: hubVnet
  name: 'app-vnet-to-hub'
  properties: {
    remoteVirtualNetwork: {
      id: appVnet.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
  }
  dependsOn: [
    firewall
  ]
}

resource peeringOnApp 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: appVnet
  name: 'hub-to-app-vnet'
  properties: {
    remoteVirtualNetwork: {
      id: hubVnet.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
  }
  dependsOn: [
    firewall
  ]
}

// ---------------- Security: ASG, NSG, route table ----------------

resource asg 'Microsoft.Network/applicationSecurityGroups@2024-05-01' = {
  name: 'app-frontend-asg'
  location: location
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'app-vnet-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowSSH'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationPortRange: '22'
          destinationApplicationSecurityGroups: [
            {
              id: asg.id
            }
          ]
        }
      }
    ]
  }
}

resource routeTable 'Microsoft.Network/routeTables@2024-05-01' = {
  name: 'app-vnet-firewall-rt'
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'outbound-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.1.63.4' // firewall private IP, as in the original
        }
      }
    ]
  }
}

// ---------------- Azure Firewall ----------------

resource fwPip 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'fwpip'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource fwPolicy 'Microsoft.Network/firewallPolicies@2024-05-01' = {
  name: 'fw-policy'
  location: location
  properties: {
    sku: {
      tier: 'Standard'
    }
    threatIntelMode: 'Alert'
  }
}

resource networkRules 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-05-01' = {
  parent: fwPolicy
  name: 'DefaultNetworkRuleCollectionGroup'
  properties: {
    priority: 200
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'app-vnet-fw-nrc-dns'
        priority: 200
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'AllowDns'
            ipProtocols: [
              'UDP'
            ]
            sourceAddresses: [
              '10.1.0.0/23'
            ]
            destinationAddresses: [
              '1.1.1.1'
              '1.0.0.1'
            ]
            destinationPorts: [
              '53'
            ]
          }
        ]
      }
    ]
  }
}

// Rule collection groups on the same policy must be deployed one after the other.
resource applicationRules 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-05-01' = {
  parent: fwPolicy
  name: 'DefaultApplicationRuleCollectionGroup'
  properties: {
    priority: 300
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'app-vnet-fw-rule-collection'
        priority: 200
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'ApplicationRule'
            name: 'AllowAzurePipelines'
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            targetFqdns: [
              'dev.azure.com'
              'azure.microsoft.com'
            ]
            sourceAddresses: [
              '10.1.0.0/23'
            ]
            terminateTLS: false
          }
        ]
      }
    ]
  }
  dependsOn: [
    networkRules
  ]
}

resource firewall 'Microsoft.Network/azureFirewalls@2024-05-01' = {
  name: 'app-vnet-firewall'
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    firewallPolicy: {
      id: fwPolicy.id
    }
    ipConfigurations: [
      {
        name: 'fwpip'
        properties: {
          subnet: {
            id: '${appVnet.id}/subnets/AzureFirewallSubnet'
          }
          publicIPAddress: {
            id: fwPip.id
          }
        }
      }
    ]
  }
  // Wait until the policy's rules are in place before attaching it.
  dependsOn: [
    networkRules
    applicationRules
  ]
}

// ---------------- VMs ----------------

resource vmPips 'Microsoft.Network/publicIPAddresses@2024-05-01' = [for vm in vms: {
  name: '${vm.name}-ip'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}]

resource nics 'Microsoft.Network/networkInterfaces@2024-05-01' = [for (vm, i) in vms: {
  name: '${vm.name}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${appVnet.id}/subnets/${vm.subnet}'
          }
          publicIPAddress: {
            id: vmPips[i].id
          }
          applicationSecurityGroups: vm.useAsg ? [
            {
              id: asg.id
            }
          ] : []
        }
      }
    ]
  }
}]

resource vmResources 'Microsoft.Compute/virtualMachines@2024-07-01' = [for (vm, i) in vms: {
  name: vm.name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS' // same image as the original lab
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        caching: 'ReadWrite'
        deleteOption: 'Delete' // let Azure name the disk and remove it with the VM
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    osProfile: {
      computerName: vm.name
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nics[i].id
        }
      ]
    }
  }
}]

// ---------------- DNS ----------------

// Created but not linked to a VNet, as in the original lab.
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'private.contoso.com'
  location: 'global'
}
