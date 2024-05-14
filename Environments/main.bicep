@description('the location of the deployment')
param location string = resourceGroup().location

@description('VM version')
param imageVersion string = '333.0.0'

@description('the addressprefix of the virtual network')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('the subnet prefix of the virtual network')
param subnetAddressPrefix string = '10.0.0.0/24'


@description('The size of the VM')
param virtualMachineSize string = 'Standard_B2als_v2'


var virtualNetworkName = 'vnet-compga-test'
var networkSecurityGroupName = 'nsg-compga-test'
var vnetDefaultSubnetName = 'simulator'
var networkInterfaceName1 = 'nic-compga-test'
var publicIpAddressName1 = 'pip-compga-test'
var osDiskType = 'Standard_LRS'
var virtualMachineName1 = 'vm-compga-test'


resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-RDP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*' 
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
      }
    subnets: [
      {
        name: vnetDefaultSubnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    enableDdosProtection: false
  }
  resource defaultSubnet 'subnets' existing = {
    name: vnetDefaultSubnetName
  }
}

resource networkInterface1 'Microsoft.Network/networkInterfaces@2022-11-01' = {
  name: networkInterfaceName1
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: virtualNetwork::defaultSubnet.id
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.0.4'
          publicIPAddress: {
            id: publicIPAddress1.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
  }
}

resource publicIPAddress1 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: publicIpAddressName1
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
  }
}

resource virtualMachine1 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: virtualMachineName1
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'fromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        id:'/subscriptions/19bbdbd5-8d14-4501-9ef0-cc543254ddde/resourceGroups/rg-comga/providers/Microsoft.Compute/galleries/cgtest/images/def01-s-win-gen1/versions/${imageVersion}'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface1.id
        }
      ]
    }
    additionalCapabilities: {
      hibernationEnabled: false
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}
