extension radius

param environment string

resource kafkaUiApp 'Radius.Core/applications@2025-08-01-preview' = {
  name: 'kafka-ui'
  properties: {
    environment: environment
  }
}

resource kafka 'Radius.Messaging/kafka@2025-08-01-preview' = {
  name: 'kafka'
  properties: {
    environment: environment
    application: kafkaUiApp.id
  }
}

resource kafkaUiContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'kafka-ui'
  properties: {
    environment: environment
    application: kafkaUiApp.id
    containers: {
      kafkaUi: {
        image: 'ghcr.io/kafbat/kafka-ui@sha256:7cda86a33344160309fdb65146332e4da65db81a945614f2fe32e210803f6fd1'
        ports: {
          web: {
            containerPort: 8080
          }
        }
        env: {
          KAFKA_CLUSTERS_0_NAME: {
            value: 'local'
          }
          KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: {
            value: kafka.properties.host
          }
          DYNAMIC_CONFIG_ENABLED: {
            value: 'true'
          }
        }
      }
    }
  }
}

resource kafkaUiRoute 'Radius.Compute/routes@2025-08-01-preview' = {
  name: 'kafka-ui-route'
  properties: {
    environment: environment
    application: kafkaUiApp.id
    kind: 'HTTP'
    rules: [
      {
        matches: [
          {
            httpPath: '/'
          }
        ]
        destinationContainer: {
          resourceId: kafkaUiContainer.id
          containerName: 'kafkaUi'
          containerPort: 8080
        }
      }
    ]
  }
}
