@description('Región donde se despliega la VM')
param location string

@description('Prefijo usado para nombrar los recursos')
param namePrefix string

@description('Usuario administrador de la VM')
param adminUsername string

@description('SKU de la VM. Fallback documentado en el README: si Standard_B1s no tiene cuota disponible, usar Standard_B2ats_v2 (arm64) redesplegando con --parameters vmSize=Standard_B2ats_v2')
param vmSize string = 'Standard_B1s'

@description('Resource ID de la NIC a asociar a la VM')
param nicId string

@description('SSH public key inyectada como credencial de acceso (nunca password)')
@secure()
param sshPublicKey string

@description('Tags aplicados a los recursos')
param tags object = {}

// Standard_B2ats_v2 es una SKU arm64 (Ampere Altra); Standard_B1s es x64.
// Detectamos la arquitectura a partir del nombre de la SKU para elegir
// automáticamente la imagen de Ubuntu correcta sin exigir un parámetro extra.
var isArm64 = contains(toLower(vmSize), 'ats')
var imageSku = isArm64 ? '22_04-lts-arm64' : '22_04-lts-gen2'

resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: '${namePrefix}-vm'
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: '${namePrefix}-vm'
      adminUsername: adminUsername
      customData: base64(loadTextContent('cloud-init.yaml'))
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: imageSku
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicId
        }
      ]
    }
  }
}

output vmName string = vm.name
output vmId string = vm.id
