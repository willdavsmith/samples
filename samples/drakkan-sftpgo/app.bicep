extension radius

param environment string

resource sftpgoApp 'Radius.Core/applications@2025-08-01-preview' = {
  name: 'sftpgo'
  properties: {
    environment: environment
  }
}

resource blobStore 'Radius.Storage/objectStorage@2025-08-01-preview' = {
  name: 'blob-store'
  properties: {
    environment: environment
    application: sftpgoApp.id
    containerName: 'data'
  }
}

resource sftpgoImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'sftpgo-image'
  properties: {
    environment: environment
    application: sftpgoApp.id
    tag: 'v2.7.4'
    build: {
      source: 'git::https://github.com/drakkan/sftpgo.git?ref=v2.7.4'
      dockerfile: 'Dockerfile'
      platforms: [
        'linux/amd64'
      ]
    }
  }
}

resource sftpgoContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'sftpgo'
  properties: {
    environment: environment
    application: sftpgoApp.id
    connections: {
      storage: {
        source: blobStore.id
      }
    }
    containers: {
      sftpgo: {
        image: sftpgoImage.properties.imageReference
        ports: {
          sftp: {
            containerPort: 2022
            protocol: 'TCP'
          }
          web: {
            containerPort: 8080
            protocol: 'TCP'
          }
        }
      }
    }
  }
}
