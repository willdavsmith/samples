extension radius

param environment string

resource azureSearchApiApp 'Radius.Core/applications@2025-08-01-preview' = {
  name: 'azure-search-api'
  properties: {
    environment: environment
  }
}

resource search 'Radius.AI/search@2025-08-01-preview' = {
  name: 'search'
  properties: {
    environment: environment
    application: azureSearchApiApp.id
  }
}

resource azureSearchApiImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'azure-search-api-image'
  properties: {
    environment: environment
    application: azureSearchApiApp.id
    build: {
      source: 'git::https://github.com/radius-project/samples.git//samples/azure-search-api/src?ref=08cd6c30b316b622d6ee10426d9bb73a43d99ce1'
    }
  }
}

resource azureSearchApiContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'azure-search-api'
  properties: {
    environment: environment
    application: azureSearchApiApp.id
    connections: {
      search: {
        source: search.id
      }
    }
    containers: {
      api: {
        image: azureSearchApiImage.properties.imageReference
        env: {
          PORT: {
            value: '8080'
          }
          SEARCH_INDEX_NAME: {
            value: 'radius-sample'
          }
          CONNECTION_SEARCH_APIKEY: {
            valueFrom: {
              secretKeyRef: {
                secretName: search.properties.secrets.name
                key: 'apiKey'
              }
            }
          }
        }
        ports: {
          web: {
            containerPort: 8080
          }
        }
      }
    }
  }
}
