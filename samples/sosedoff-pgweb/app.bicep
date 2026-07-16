extension radius

param environment string

@secure()
param postgresPassword string

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
    database: 'pgweb'
    username: 'myadmin'
    password: postgresPassword
  }
}

resource postgresRuntimeSecret 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'postgres-runtime-secret'
  properties: {
    environment: environment
    application: pgwebApp.id
    data: {
      url: {
        value: 'postgres://myadmin:${postgresPassword}@${postgresDb.properties.host}:${postgresDb.properties.port}/pgweb?sslmode=disable'
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
        image: 'sosedoff/pgweb:0.17.0'
        ports: {
          web: {
            containerPort: 8081
          }
        }
        env: {
          PGWEB_DATABASE_URL: {
            valueFrom: {
              secretKeyRef: {
                secretName: postgresRuntimeSecret.name
                key: 'url'
              }
            }
          }
        }
      }
    }
  }
}

resource pgwebRoute 'Radius.Compute/routes@2025-08-01-preview' = {
  name: 'pgweb-route'
  properties: {
    environment: environment
    application: pgwebApp.id
    rules: [
      {
        matches: [
          { httpPath: '/' }
        ]
        destinationContainer: {
          resourceId: pgwebContainer.id
          containerName: 'pgweb'
          containerPort: 8081
        }
      }
    ]
  }
}
