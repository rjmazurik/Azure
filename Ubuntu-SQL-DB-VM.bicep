
param projectName string = 'SQLProject'


param location string = resourceGroup().location


param adminUsername string = 'azureuser'


param adminPassword string = 'Thisisapassword1'

var vNetName_var = '${projectName}-vnet'
var vNetAddressPrefixes = '10.0.0.0/16'
var vNetSubnetName = '${projectName}-subnet'
var vNetSubnetAddressPrefix = '10.0.0.0/24'
var vmName_var = '${projectName}-vm'
var publicIPAddressName_var = '${projectName}-ip'
var networkInterfaceName_var = '${projectName}-nic'
var networkSecurityGroupName_var = '${projectName}-nsg'
var networkSecurityGroupName2_var = '${vNetSubnetName}-nsg'

module WorkspaceTemplate './Configure-Workspace-Template.bicep'  = {
  name: 'WorkspaceTemplate'
  params: {}
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: networkSecurityGroupName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'ssh_rule'
        properties: {
          description: 'Locks inbound down to ssh default port 22.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 123
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Basic'
  }
}

resource networkSecurityGroupName2 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: networkSecurityGroupName2_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-22'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '22'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-sql'
        properties: {
          priority: 1010
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '1433'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vNetName 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vNetName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNetAddressPrefixes
      ]
    }
    subnets: [
      {
        name: vNetSubnetName
        properties: {
          addressPrefix: vNetSubnetAddressPrefix
          networkSecurityGroup: {
            id: networkSecurityGroupName2.id
          }
        }
      }
    ]
  }
}

resource networkInterfaceName 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: networkInterfaceName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNetName_var, vNetSubnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    vNetName
    networkSecurityGroupName
  ]
}

resource vmName 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vmName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: vmName_var
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName.id
        }
      ]
    }
  }
  dependsOn: [
    publicIPAddressName
    WorkspaceTemplate
  ]
}

resource vmName_my_custom_Linux_script 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = {
  parent: vmName
  name: 'my-custom-Linux-script'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      fileUris: [
        'https://raw.githubusercontent.com/rjmazurik/Test/main/SqlScript.bash'
      ]
      commandToExecute: 'bash ./SqlScript.bash'
    }
  }
}

resource vmName_LogAnalyticsAgent 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = {
  parent: vmName
  name: 'LogAnalyticsAgent'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'OmsAgentForLinux'
    typeHandlerVersion: '1.7'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: WorkspaceTemplate.outputs.WorkspaceID
    }
    protectedSettings: {
      workspaceKey: WorkspaceTemplate.outputs.WorkspaceKey
    }
  }
  dependsOn: [
    vmName_my_custom_Linux_script
  ]
}

resource vmName_DependencyAgent 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  parent: vmName
  name: 'DependencyAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: 'DependencyAgentLinux'
    typeHandlerVersion: '9.5'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: WorkspaceTemplate.outputs.WorkspaceID
    }
    protectedSettings: {
      workspaceKey: WorkspaceTemplate.outputs.WorkspaceKey
    }
  }
  dependsOn: [
    vmName_LogAnalyticsAgent
  ]
}

resource vmName_AzureMonitorLinuxAgent 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  parent: vmName
  name: 'AzureMonitorLinuxAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorLinuxAgent'
    typeHandlerVersion: '1.5'
    autoUpgradeMinorVersion: true
  }
  dependsOn: [
    vmName_DependencyAgent
  ]
}

resource vmName_GuestHealthLinuxAgent 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = {
  parent: vmName
  name: 'GuestHealthLinuxAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor.VirtualMachines.GuestHealth'
    type: 'GuestHealthLinuxAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
  }
  dependsOn: [
    vmName_AzureMonitorLinuxAgent
  ]
}

resource vmName_microsoft_insights_DataCollectionRuleAssociation 'Microsoft.Compute/virtualMachines/providers/dataCollectionRuleAssociations@2019-11-01-preview' = {
  name: '${vmName_var}/microsoft.insights/DataCollectionRuleAssociation'
  properties: {
    description: 'Association of data collection rule for VM Insights Health.'
    dataCollectionRuleId: WorkspaceTemplate.outputs.DataCollectionRuleID
  }
  dependsOn: [
    vmName
  ]
}

output ConnectionString string = '"Server=${publicIPAddressName.properties.ipAddress};Initial Catalog=TestDB;Uid=sa;Pwd=Thisisapassword1"'
