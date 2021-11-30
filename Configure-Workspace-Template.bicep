param workspaceName string = 'SQLProject-Workspace'
param location string = resourceGroup().location
param DataCollectionRuleName string = 'SQLProject-DataCollectionRule'
param SyslogFacilityNames array = [
  'auth'
  'authpriv'
  'daemon'
  'kern'
  'syslog'
  'user'
]
param logLevels array = [ 
  'Debug'
  'Info'
  'Notice'
  'Warning'
  'Error'
  'Critical'
  'Alert'
  'Emergency'
]


resource workspaceName_resource 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: workspaceName
  location: location
  properties: {}
}

resource VMInsights_Microsoft_OperationalInsights_workspaces_workspaceName_8 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  location: location
  name: 'VMInsights(${split(workspaceName_resource.id, '/')[8]})'
  properties: {
    workspaceResourceId: workspaceName_resource.id
  }
  plan: {
    name: 'VMInsights(${split(workspaceName_resource.id, '/')[8]})'
    product: 'OMSGallery/VMInsights'
    promotionCode: ''
    publisher: 'Microsoft'
  }
}

resource DataCollectionRuleName_resource 'Microsoft.Insights/dataCollectionRules@2019-11-01-preview' = {
  name: DataCollectionRuleName
  location: location
  properties: {
    description: 'Data Collection Rule for Linux VM.'
    dataSources: {
      syslog: [
        {
          name: 'LinuxSyslog'
          streams: [
            'Microsoft-Syslog'
          ]
          facilityNames: SyslogFacilityNames
          logLevels: logLevels
        }
      ]
      performanceCounters: [
        {
          name: 'VMHealthPerfCounters'
          streams: [
            'Microsoft-Perf'
          ]
          scheduledTransferPeriod: 'PT1M'
          samplingFrequencyInSeconds: 60
          counterSpecifiers: [
            '\\LogicalDisk(*)\\% Free Space'
            '\\Memory\\Available Bytes'
            '\\Processor(_Total)\\% Processor Time'
            '\\Network(*)\\Total Bytes Transmitted'
            '\\Network(*)\\Total Bytes Received'
          ]
        }
      ]
      extensions: [
        {
          name: 'Microsoft-VMInsights-Health'
          streams: [
            'Microsoft-HealthStateChange'
          ]
          extensionName: 'HealthExtension'
          extensionSettings: {
            schemaVersion: '1.0'
            contentVersion: ''
            healthRuleOverrides: [
              {
                scopes: [
                  '*'
                ]
                monitors: [
                  'root'
                ]
                alertConfiguration: {
                  isEnabled: true
                }
              }
            ]
          }
          inputDataSources: [
            'VMHealthPerfCounters'
          ]
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: workspaceName_resource.id
          name: 'Microsoft-HealthStateChange-Dest'
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-HealthStateChange'
        ]
        destinations: [
          'Microsoft-HealthStateChange-Dest'
        ]
      }
    ]
  }
}

output WorkspaceID string = reference(workspaceName_resource.id, '2015-03-20').customerId
output WorkspaceKey string = listKeys(workspaceName_resource.id, '2015-11-01-preview').primarySharedKey
output DataCollectionRuleID string = DataCollectionRuleName_resource.id
