extension radius

@description('The ID of your Radius Environment. Set automatically by the rad CLI.')
param environment string

@description('Administrator password for the PostgreSQL database.')
@secure()
param password string

var databaseName = 'appdb'
var databaseUsername = 'radadmin'

resource pgwebApp 'Radius.Core/applications@2025-08-01-preview' = {
  name: 'pgweb'
  properties: {
    environment: environment
  }
}

resource postgresDb 'Radius.Data/postgreSqlDatabases@2025-08-01-preview' = {
  name: 'postgres'
  properties: {
    environment: environment
    application: pgwebApp.id
    size: 'S'
    database: databaseName
    username: databaseUsername
    password: password
  }
}

resource postgresRuntimeSecret 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'postgres-runtime-secret'
  properties: {
    environment: environment
    application: pgwebApp.id
    data: {
      password: {
        value: password
      }
    }
  }
}

resource pgwebImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'pgweb-image'
  properties: {
    environment: environment
    application: pgwebApp.id
    tag: 'v0.17.0'
    build: {
      source: 'git::https://github.com/sosedoff/pgweb.git//?ref=v0.17.0'
      args: {
        BUILDKIT_CONTEXT_KEEP_GIT_DIR: '1'
      }
    }
  }
}

resource pgwebContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'pgweb'
  properties: {
    environment: environment
    application: pgwebApp.id
    containers: {
      pgweb: {
        image: pgwebImage.properties.imageReference
        args: [
          '--host=${postgresDb.properties.host}'
          '--port=5432'
          '--user=${databaseUsername}'
          '--db=${databaseName}'
          '--ssl=require'
          '--pass=$(DB_PASSWORD)'
        ]
        env: {
          DB_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                secretName: postgresRuntimeSecret.name
                key: 'password'
              }
            }
          }
        }
        ports: {
          web: {
            containerPort: 8081
          }
        }
      }
    }
  }
}
