extension radius

param environment string

@secure()
param postgresPassword string

@secure()
param litellmMasterKey string

@secure()
param openaiApiKey string

resource litellmApp 'Radius.Core/applications@2025-08-01-preview' = {
  name: 'litellm'
  properties: {
    environment: environment
  }
}

resource postgresDb 'Radius.Data/postgreSqlDatabases@2025-08-01-preview' = {
  name: 'postgres'
  properties: {
    environment: environment
    application: litellmApp.id
    size: 'S'
    database: 'litellm'
    username: 'llmproxy'
    password: postgresPassword
  }
}

resource postgresRuntimeSecret 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'postgres-runtime-secret'
  properties: {
    environment: environment
    application: litellmApp.id
    data: {
      password: {
        value: postgresPassword
      }
    }
  }
}

resource appSecrets 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'app-secrets'
  properties: {
    environment: environment
    application: litellmApp.id
    data: {
      LITELLM_MASTER_KEY: {
        value: litellmMasterKey
      }
      OPENAI_API_KEY: {
        value: openaiApiKey
      }
    }
  }
}

resource litellmConfig 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'litellm-config'
  properties: {
    environment: environment
    application: litellmApp.id
    data: {
      'config.yaml': {
        value: '''
model_list:
  - model_name: gpt-4o-mini
    litellm_params:
      model: openai/gpt-4o-mini
      api_key: os.environ/OPENAI_API_KEY
general_settings:
  master_key: os.environ/LITELLM_MASTER_KEY
  store_model_in_db: true
'''
      }
    }
  }
}

resource litellmContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'litellm'
  properties: {
    environment: environment
    application: litellmApp.id
    containers: {
      litellm: {
        image: 'ghcr.io/berriai/litellm-database:v1.91.0@sha256:6151ddc97c5dc4590740bd14646d78d48267d8b7a1bf398eeaffcd6729b8f0b9'
        args: [
          '--config'
          '/etc/litellm/config.yaml'
          '--port'
          '4000'
        ]
        ports: {
          web: {
            containerPort: 4000
          }
        }
        env: {
          DATABASE_HOST: {
            value: '${postgresDb.properties.host}:${postgresDb.properties.port}'
          }
          DATABASE_USERNAME: {
            value: 'llmproxy'
          }
          DATABASE_NAME: {
            value: 'litellm'
          }
          DATABASE_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                secretName: postgresRuntimeSecret.name
                key: 'password'
              }
            }
          }
          LITELLM_MASTER_KEY: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'LITELLM_MASTER_KEY'
              }
            }
          }
          OPENAI_API_KEY: {
            valueFrom: {
              secretKeyRef: {
                secretName: appSecrets.name
                key: 'OPENAI_API_KEY'
              }
            }
          }
        }
        volumeMounts: [
          {
            volumeName: 'config'
            mountPath: '/etc/litellm'
          }
        ]
      }
    }
    volumes: {
      config: {
        secretName: litellmConfig.name
      }
    }
  }
}

resource litellmRoute 'Radius.Compute/routes@2025-08-01-preview' = {
  name: 'litellm-route'
  properties: {
    environment: environment
    application: litellmApp.id
    rules: [
      {
        matches: [
          {
            httpPath: '/'
          }
        ]
        destinationContainer: {
          resourceId: litellmContainer.id
          containerName: 'litellm'
          containerPort: litellmContainer.properties.containers.litellm.ports.web.containerPort
        }
      }
    ]
  }
}
