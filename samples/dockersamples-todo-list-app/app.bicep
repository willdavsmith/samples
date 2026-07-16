extension radius

param environment string

@secure()
param mysqlPassword string

resource todoApp 'Radius.Core/applications@2025-08-01-preview' = {
  name: 'getting-started-todo-app'
  properties: {
    environment: environment
  }
}

resource mysqlDb 'Radius.Data/mySqlDatabases@2025-08-01-preview' = {
  name: 'mysql'
  properties: {
    environment: environment
    application: todoApp.id
    database: 'todos'
    version: '8.4'
    username: 'myadmin'
    password: mysqlPassword
  }
}

resource mysqlRuntimeSecret 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'mysql-runtime-secret'
  properties: {
    environment: environment
    application: todoApp.id
    data: {
      password: {
        value: mysqlPassword
      }
    }
  }
}

resource todoImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'getting-started-todo-app-image'
  properties: {
    environment: environment
    application: todoApp.id
    build: {
      source: 'git::https://github.com/docker/getting-started-todo-app.git?ref=55680777bc46c59d3fe0ab9ff7e79ee947d0c757'
    }
  }
}

resource todoContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'getting-started-todo-app'
  properties: {
    environment: environment
    application: todoApp.id
    containers: {
      todo: {
        image: todoImage.properties.imageReference
        ports: {
          web: {
            containerPort: 3000
          }
        }
        env: {
          MYSQL_HOST: {
            value: mysqlDb.properties.host
          }
          MYSQL_USER: {
            value: 'myadmin'
          }
          MYSQL_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                secretName: mysqlRuntimeSecret.name
                key: 'password'
              }
            }
          }
          MYSQL_DB: {
            value: 'todos'
          }
        }
      }
    }
  }
}
