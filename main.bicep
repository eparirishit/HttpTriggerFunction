param suffixName string = 'azexp-httptrigger'
param location string = resourceGroup().location

resource storage_account 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: 'strgazexphttptrigger'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

resource app_insights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-${suffixName}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource appservice_plan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: 'asp-${suffixName}'
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
}

resource function_app 'Microsoft.Web/sites@2021-02-01' = {
  name: 'func-${suffixName}'
  location: location
  kind: 'functionapp'
  properties: {
    httpsOnly: true
    serverFarmId: appservice_plan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storage_account.name};AccountKey=${listKeys(storage_account.id, '2021-04-01').keys[0].value}'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference(app_insights.id, '2020-02-02').InstrumentationKey
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storage_account.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storage_account.id, storage_account.apiVersion).keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: '${substring(uniqueString(resourceGroup().id), 3)}-functionapp-dev01'
        }
      ]
    }
  }
}
