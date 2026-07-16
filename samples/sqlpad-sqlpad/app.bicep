extension radius

param environment string

@secure()
param sqlServerPassword string

resource sqlpadApp 'Radius.Core/applications@2025-08-01-preview' = {
  name: 'sqlpad'
  properties: {
    environment: environment
  }
}

resource sqlServerDb 'Radius.Data/sqlServerDatabases@2025-08-01-preview' = {
  name: 'sqlserver'
  properties: {
    environment: environment
    application: sqlpadApp.id
    database: 'appdb'
    username: 'sqladmin'
    password: sqlServerPassword
  }
}

resource sqlServerRuntimeSecret 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'sqlserver-runtime-secret'
  properties: {
    environment: environment
    application: sqlpadApp.id
    data: {
      password: {
        value: sqlServerPassword
      }
    }
  }
}

resource sqlpadImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'sqlpad-image'
  properties: {
    environment: environment
    application: sqlpadApp.id
    tag: 'v7.5.7'
    build: {
      source: 'git::https://github.com/sqlpad/sqlpad.git?ref=v7.5.7'
    }
  }
}

resource sqlpadContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'sqlpad'
  properties: {
    environment: environment
    application: sqlpadApp.id
    containers: {
      sqlpad: {
        image: sqlpadImage.properties.imageReference
        ports: {
          web: {
            containerPort: 3000
          }
        }
        env: {
          SQLPAD_PORT: {
            value: '3000'
          }
          SQLPAD_DB_PATH: {
            value: '/var/lib/sqlpad'
          }
          SQLPAD_CONNECTIONS__azuresql__name: {
            value: 'Azure SQL'
          }
          SQLPAD_CONNECTIONS__azuresql__driver: {
            value: 'sqlserver'
          }
          SQLPAD_CONNECTIONS__azuresql__host: {
            value: sqlServerDb.properties.host
          }
          SQLPAD_CONNECTIONS__azuresql__port: {
            value: sqlServerDb.properties.port
          }
          SQLPAD_CONNECTIONS__azuresql__database: {
            value: sqlServerDb.properties.database
          }
          SQLPAD_CONNECTIONS__azuresql__username: {
            value: sqlServerDb.properties.username
          }
          SQLPAD_CONNECTIONS__azuresql__password: {
            valueFrom: {
              secretKeyRef: {
                secretName: sqlServerRuntimeSecret.name
                key: 'password'
              }
            }
          }
          SQLPAD_CONNECTIONS__azuresql__sqlserverEncrypt: {
            value: 'true'
          }
          SQLPAD_CONNECTIONS__azuresql__trustServerCertificate: {
            value: 'false'
          }
        }
      }
    }
  }
}

resource sqlpadRoute 'Radius.Compute/routes@2025-08-01-preview' = {
  name: 'sqlpad-route'
  properties: {
    environment: environment
    application: sqlpadApp.id
    rules: [
      {
        matches: [
          { httpPath: '/' }
        ]
        destinationContainer: {
          resourceId: sqlpadContainer.id
          containerName: 'sqlpad'
          containerPort: 3000
        }
      }
    ]
  }
}
