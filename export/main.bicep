param virtualMachines_VM1_name string = 'VM1'
param virtualMachines_VM2_name string = 'VM2'
param publicIPAddresses_fwpip_name string = 'fwpip'
param publicIPAddresses_VM1_ip_name string = 'VM1-ip'
param publicIPAddresses_VM2_ip_name string = 'VM2-ip'
param virtualNetworks_app_vnet_name string = 'app-vnet'
param virtualNetworks_hub_vnet_name string = 'hub-vnet'
param networkInterfaces_VM1_nic_name string = 'VM1-nic'
param networkInterfaces_VM2_nic_name string = 'VM2-nic'
param firewallPolicies_fw_policy_name string = 'fw-policy'
param azureFirewalls_app_vnet_firewall_name string = 'app-vnet-firewall'
param routeTables_app_vnet_firewall_rt_name string = 'app-vnet-firewall-rt'
param networkSecurityGroups_app_vnet_nsg_name string = 'app-vnet-nsg'
param privateDnsZones_private_contoso_com_name string = 'private.contoso.com'
param applicationSecurityGroups_app_frontend_asg_name string = 'app-frontend-asg'

resource applicationSecurityGroups_app_frontend_asg_name_resource 'Microsoft.Network/applicationSecurityGroups@2025-07-01' = {
  name: applicationSecurityGroups_app_frontend_asg_name
  location: 'eastus'
  properties: {}
}

resource firewallPolicies_fw_policy_name_resource 'Microsoft.Network/firewallPolicies@2025-07-01' = {
  name: firewallPolicies_fw_policy_name
  location: 'eastus'
  properties: {
    sku: {
      tier: 'Standard'
    }
    threatIntelMode: 'Alert'
  }
}

resource privateDnsZones_private_contoso_com_name_resource 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: privateDnsZones_private_contoso_com_name
  location: 'global'
  properties: {}
}

resource publicIPAddresses_fwpip_name_resource 'Microsoft.Network/publicIPAddresses@2025-07-01' = {
  name: publicIPAddresses_fwpip_name
  location: 'eastus'
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    ipTags: []
  }
}

resource publicIPAddresses_VM1_ip_name_resource 'Microsoft.Network/publicIPAddresses@2025-07-01' = {
  name: publicIPAddresses_VM1_ip_name
  location: 'eastus'
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    ipTags: []
    ddosSettings: {
      protectionMode: 'VirtualNetworkInherited'
    }
  }
}

resource publicIPAddresses_VM2_ip_name_resource 'Microsoft.Network/publicIPAddresses@2025-07-01' = {
  name: publicIPAddresses_VM2_ip_name
  location: 'eastus'
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    ipTags: []
    ddosSettings: {
      protectionMode: 'VirtualNetworkInherited'
    }
  }
}

resource routeTables_app_vnet_firewall_rt_name_resource 'Microsoft.Network/routeTables@2025-07-01' = {
  name: routeTables_app_vnet_firewall_rt_name
  location: 'eastus'
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'outbound-firewall'
        id: routeTables_app_vnet_firewall_rt_name_outbound_firewall.id
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.1.63.4'
        }
      }
    ]
  }
}

resource virtualMachines_VM1_name_resource 'Microsoft.Compute/virtualMachines@2026-03-01' = {
  name: virtualMachines_VM1_name
  location: 'eastus'
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v4'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        name: '${virtualMachines_VM1_name}_disk1_6a38f4133b104e6fb10ee60804d2902b'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
          id: resourceId(
            'Microsoft.Compute/disks',
            '${virtualMachines_VM1_name}_disk1_6a38f4133b104e6fb10ee60804d2902b'
          )
        }
        deleteOption: 'Detach'
        diskSizeGB: 30
      }
      dataDisks: []
    }
    osProfile: {
      computerName: virtualMachines_VM1_name
      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'ImageDefault'
          assessmentMode: 'ImageDefault'
        }
      }
      secrets: []
      allowExtensionOperations: true
      requireGuestProvisionSignal: true
      adminUsername: 'AzureAdmin'
    }
    securityProfile: {
      securityType: 'Standard'
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaces_VM1_nic_name_resource.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }
}

resource virtualMachines_VM2_name_resource 'Microsoft.Compute/virtualMachines@2026-03-01' = {
  name: virtualMachines_VM2_name
  location: 'eastus'
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v4'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        name: '${virtualMachines_VM2_name}_disk1_a76711e00aa04f15a1a08e59308344ed'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
          id: resourceId(
            'Microsoft.Compute/disks',
            '${virtualMachines_VM2_name}_disk1_a76711e00aa04f15a1a08e59308344ed'
          )
        }
        deleteOption: 'Detach'
        diskSizeGB: 30
      }
      dataDisks: []
    }
    osProfile: {
      computerName: virtualMachines_VM2_name
      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'ImageDefault'
          assessmentMode: 'ImageDefault'
        }
      }
      secrets: []
      allowExtensionOperations: true
      requireGuestProvisionSignal: true
      adminUsername: 'AzureAdmin'
    }
    securityProfile: {
      securityType: 'Standard'
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaces_VM2_nic_name_resource.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }
}

resource firewallPolicies_fw_policy_name_DefaultApplicationRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2025-07-01' = {
  parent: firewallPolicies_fw_policy_name_resource
  name: 'DefaultApplicationRuleCollectionGroup'
  location: 'eastus'
  properties: {
    priority: 300
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
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
            fqdnTags: []
            webCategories: []
            targetFqdns: [
              'dev.azure.com'
              'azure.microsoft.com'
            ]
            targetUrls: []
            terminateTLS: false
            sourceAddresses: [
              '10.1.0.0/23'
            ]
            destinationAddresses: []
            sourceIpGroups: []
            httpHeadersToInsert: []
          }
        ]
        name: 'app-vnet-fw-rule-collection'
        priority: 200
      }
    ]
  }
}

resource firewallPolicies_fw_policy_name_DefaultNetworkRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2025-07-01' = {
  parent: firewallPolicies_fw_policy_name_resource
  name: 'DefaultNetworkRuleCollectionGroup'
  location: 'eastus'
  properties: {
    priority: 200
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
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
            sourceIpGroups: []
            destinationAddresses: [
              '1.1.1.1'
              '1.0.0.1'
            ]
            destinationIpGroups: []
            destinationFqdns: []
            destinationPorts: [
              '53'
            ]
          }
        ]
        name: 'app-vnet-fw-nrc-dns'
        priority: 200
      }
    ]
  }
}

resource networkSecurityGroups_app_vnet_nsg_name_resource 'Microsoft.Network/networkSecurityGroups@2025-07-01' = {
  name: networkSecurityGroups_app_vnet_nsg_name
  location: 'eastus'
  properties: {
    securityRules: [
      {
        name: 'AllowSSH'
        id: networkSecurityGroups_app_vnet_nsg_name_AllowSSH.id
        properties: {
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          priority: 100
          protocol: 'TCP'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
          destinationApplicationSecurityGroups: [
            {
              id: applicationSecurityGroups_app_frontend_asg_name_resource.id
            }
          ]
        }
      }
    ]
  }
}

resource Microsoft_Network_privateDnsZones_SOA_privateDnsZones_private_contoso_com_name 'Microsoft.Network/privateDnsZones/SOA@2024-06-01' = {
  parent: privateDnsZones_private_contoso_com_name_resource
  name: '@'
  properties: {
    ttl: 3600
    soaRecord: {
      email: 'azureprivatedns-host.microsoft.com'
      expireTime: 2419200
      host: 'azureprivatedns.net'
      minimumTtl: 10
      refreshTime: 3600
      retryTime: 300
      serialNumber: 1
    }
  }
}

resource routeTables_app_vnet_firewall_rt_name_outbound_firewall 'Microsoft.Network/routeTables/routes@2025-07-01' = {
  name: '${routeTables_app_vnet_firewall_rt_name}/outbound-firewall'
  properties: {
    addressPrefix: '0.0.0.0/0'
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: '10.1.63.4'
  }
  dependsOn: [
    routeTables_app_vnet_firewall_rt_name_resource
  ]
}

resource virtualNetworks_hub_vnet_name_resource 'Microsoft.Network/virtualNetworks@2025-07-01' = {
  name: virtualNetworks_hub_vnet_name
  location: 'eastus'
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    encryption: {
      enabled: false
      enforcement: 'AllowUnencrypted'
    }
    privateEndpointVNetPolicies: 'Disabled'
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        id: virtualNetworks_hub_vnet_name_AzureFirewallSubnet.id
        properties: {
          addressPrefixes: [
            '10.0.0.0/26'
          ]
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          defaultOutboundAccess: false
        }
      }
    ]
    virtualNetworkPeerings: [
      {
        name: 'app-vnet-to-hub'
        id: virtualNetworks_hub_vnet_name_app_vnet_to_hub.id
        properties: {
          peeringState: 'Connected'
          peeringSyncLevel: 'FullyInSync'
          remoteVirtualNetwork: {
            id: virtualNetworks_app_vnet_name_resource.id
          }
          allowVirtualNetworkAccess: true
          allowForwardedTraffic: false
          allowGatewayTransit: false
          useRemoteGateways: false
          doNotVerifyRemoteGateways: false
          peerCompleteVnets: true
          enableOnlyIPv6Peering: false
          remoteAddressSpace: {
            addressPrefixes: [
              '10.1.0.0/16'
            ]
          }
          remoteVirtualNetworkAddressSpace: {
            addressPrefixes: [
              '10.1.0.0/16'
            ]
          }
        }
      }
    ]
    enableDdosProtection: false
  }
}

resource virtualNetworks_app_vnet_name_AzureFirewallSubnet 'Microsoft.Network/virtualNetworks/subnets@2025-07-01' = {
  name: '${virtualNetworks_app_vnet_name}/AzureFirewallSubnet'
  properties: {
    addressPrefix: '10.1.63.0/26'
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    defaultOutboundAccess: false
  }
  dependsOn: [
    virtualNetworks_app_vnet_name_resource
  ]
}

resource virtualNetworks_hub_vnet_name_AzureFirewallSubnet 'Microsoft.Network/virtualNetworks/subnets@2025-07-01' = {
  name: '${virtualNetworks_hub_vnet_name}/AzureFirewallSubnet'
  properties: {
    addressPrefixes: [
      '10.0.0.0/26'
    ]
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    defaultOutboundAccess: false
  }
  dependsOn: [
    virtualNetworks_hub_vnet_name_resource
  ]
}

resource networkInterfaces_VM2_nic_name_resource 'Microsoft.Network/networkInterfaces@2025-07-01' = {
  name: networkInterfaces_VM2_nic_name
  location: 'eastus'
  kind: 'Regular'
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        id: '${networkInterfaces_VM2_nic_name_resource.id}/ipConfigurations/ipconfig1'
        properties: {
          privateIPAddress: '10.1.1.4'
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddresses_VM2_ip_name_resource.id
          }
          subnet: {
            id: virtualNetworks_app_vnet_name_backend.id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: false
    enableIPForwarding: false
    disableTcpStateTracking: false
    nicType: 'Standard'
    auxiliaryMode: 'None'
    auxiliarySku: 'None'
  }
}

resource networkSecurityGroups_app_vnet_nsg_name_AllowSSH 'Microsoft.Network/networkSecurityGroups/securityRules@2025-07-01' = {
  name: '${networkSecurityGroups_app_vnet_nsg_name}/AllowSSH'
  properties: {
    sourcePortRange: '*'
    destinationPortRange: '22'
    sourceAddressPrefix: '*'
    priority: 100
    protocol: 'TCP'
    access: 'Allow'
    direction: 'Inbound'
    sourcePortRanges: []
    destinationPortRanges: []
    sourceAddressPrefixes: []
    destinationAddressPrefixes: []
    destinationApplicationSecurityGroups: [
      {
        id: applicationSecurityGroups_app_frontend_asg_name_resource.id
      }
    ]
  }
  dependsOn: [
    networkSecurityGroups_app_vnet_nsg_name_resource
  ]
}

resource virtualNetworks_app_vnet_name_frontend 'Microsoft.Network/virtualNetworks/subnets@2025-07-01' = {
  name: '${virtualNetworks_app_vnet_name}/frontend'
  properties: {
    addressPrefix: '10.1.0.0/24'
    routeTable: {
      id: routeTables_app_vnet_firewall_rt_name_resource.id
    }
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    defaultOutboundAccess: false
  }
  dependsOn: [
    virtualNetworks_app_vnet_name_resource
  ]
}

resource virtualNetworks_hub_vnet_name_app_vnet_to_hub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2025-07-01' = {
  name: '${virtualNetworks_hub_vnet_name}/app-vnet-to-hub'
  properties: {
    peeringState: 'Connected'
    peeringSyncLevel: 'FullyInSync'
    remoteVirtualNetwork: {
      id: virtualNetworks_app_vnet_name_resource.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    doNotVerifyRemoteGateways: false
    peerCompleteVnets: true
    enableOnlyIPv6Peering: false
    remoteAddressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    remoteVirtualNetworkAddressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
  }
  dependsOn: [
    virtualNetworks_hub_vnet_name_resource
  ]
}

resource virtualNetworks_app_vnet_name_hub_to_virtualNetworks_app_vnet_name 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2025-07-01' = {
  name: '${virtualNetworks_app_vnet_name}/hub-to-${virtualNetworks_app_vnet_name}'
  properties: {
    peeringState: 'Connected'
    peeringSyncLevel: 'FullyInSync'
    remoteVirtualNetwork: {
      id: virtualNetworks_hub_vnet_name_resource.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    doNotVerifyRemoteGateways: false
    peerCompleteVnets: true
    enableOnlyIPv6Peering: false
    remoteAddressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    remoteVirtualNetworkAddressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
  }
  dependsOn: [
    virtualNetworks_app_vnet_name_resource
  ]
}

resource azureFirewalls_app_vnet_firewall_name_resource 'Microsoft.Network/azureFirewalls@2025-07-01' = {
  name: azureFirewalls_app_vnet_firewall_name
  location: 'eastus'
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    threatIntelMode: 'Alert'
    additionalProperties: {}
    ipConfigurations: [
      {
        name: 'fwpip'
        id: '${azureFirewalls_app_vnet_firewall_name_resource.id}/azureFirewallIpConfigurations/fwpip'
        properties: {
          publicIPAddress: {
            id: publicIPAddresses_fwpip_name_resource.id
          }
          subnet: {
            id: virtualNetworks_app_vnet_name_AzureFirewallSubnet.id
          }
        }
      }
    ]
    networkRuleCollections: []
    applicationRuleCollections: []
    natRuleCollections: []
    firewallPolicy: {
      id: firewallPolicies_fw_policy_name_resource.id
    }
  }
}

resource networkInterfaces_VM1_nic_name_resource 'Microsoft.Network/networkInterfaces@2025-07-01' = {
  name: networkInterfaces_VM1_nic_name
  location: 'eastus'
  kind: 'Regular'
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        id: '${networkInterfaces_VM1_nic_name_resource.id}/ipConfigurations/ipconfig1'
        properties: {
          privateIPAddress: '10.1.0.4'
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddresses_VM1_ip_name_resource.id
          }
          subnet: {
            id: virtualNetworks_app_vnet_name_frontend.id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
          applicationSecurityGroups: [
            {
              id: applicationSecurityGroups_app_frontend_asg_name_resource.id
            }
          ]
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: false
    enableIPForwarding: false
    disableTcpStateTracking: false
    nicType: 'Standard'
    auxiliaryMode: 'None'
    auxiliarySku: 'None'
  }
}

resource virtualNetworks_app_vnet_name_resource 'Microsoft.Network/virtualNetworks@2025-07-01' = {
  name: virtualNetworks_app_vnet_name
  location: 'eastus'
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    privateEndpointVNetPolicies: 'Disabled'
    dhcpOptions: {
      dnsServers: [
        '1.1.1.1'
        '1.0.0.1'
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        id: virtualNetworks_app_vnet_name_AzureFirewallSubnet.id
        properties: {
          addressPrefix: '10.1.63.0/26'
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          defaultOutboundAccess: false
        }
      }
      {
        name: 'frontend'
        id: virtualNetworks_app_vnet_name_frontend.id
        properties: {
          addressPrefix: '10.1.0.0/24'
          routeTable: {
            id: routeTables_app_vnet_firewall_rt_name_resource.id
          }
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          defaultOutboundAccess: false
        }
      }
      {
        name: 'backend'
        id: virtualNetworks_app_vnet_name_backend.id
        properties: {
          addressPrefix: '10.1.1.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroups_app_vnet_nsg_name_resource.id
          }
          routeTable: {
            id: routeTables_app_vnet_firewall_rt_name_resource.id
          }
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          defaultOutboundAccess: false
        }
      }
    ]
    virtualNetworkPeerings: [
      {
        name: 'hub-to-${virtualNetworks_app_vnet_name}'
        id: virtualNetworks_app_vnet_name_hub_to_virtualNetworks_app_vnet_name.id
        properties: {
          peeringState: 'Connected'
          peeringSyncLevel: 'FullyInSync'
          remoteVirtualNetwork: {
            id: virtualNetworks_hub_vnet_name_resource.id
          }
          allowVirtualNetworkAccess: true
          allowForwardedTraffic: false
          allowGatewayTransit: false
          useRemoteGateways: false
          doNotVerifyRemoteGateways: false
          peerCompleteVnets: true
          enableOnlyIPv6Peering: false
          remoteAddressSpace: {
            addressPrefixes: [
              '10.0.0.0/16'
            ]
          }
          remoteVirtualNetworkAddressSpace: {
            addressPrefixes: [
              '10.0.0.0/16'
            ]
          }
        }
      }
    ]
    enableDdosProtection: false
  }
}

resource virtualNetworks_app_vnet_name_backend 'Microsoft.Network/virtualNetworks/subnets@2025-07-01' = {
  name: '${virtualNetworks_app_vnet_name}/backend'
  properties: {
    addressPrefix: '10.1.1.0/24'
    networkSecurityGroup: {
      id: networkSecurityGroups_app_vnet_nsg_name_resource.id
    }
    routeTable: {
      id: routeTables_app_vnet_firewall_rt_name_resource.id
    }
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    defaultOutboundAccess: false
  }
  dependsOn: [
    virtualNetworks_app_vnet_name_resource
  ]
}
