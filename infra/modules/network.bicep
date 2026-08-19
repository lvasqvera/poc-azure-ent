@description('Región donde se despliegan los recursos de red')
param location string

@description('Prefijo usado para nombrar los recursos')
param namePrefix string

@description('IP pública de origen (CIDR, ej. "203.0.113.10/32") desde la que se permite SSH al NSG')
param sshSourceIp string

@description('Tags aplicados a los recursos')
param tags object = {}

var vnetAddressPrefix = '10.0.0.0/16'
var subnetAddressPrefix = '10.0.1.0/24'

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: '${namePrefix}-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTP-Internet'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
        }
      }
      {
        name: 'Allow-SSH-TrustedIP'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: sshSourceIp
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
      {
        // Deny explícito para el resto de Internet en el puerto 22. El NSG
        // ya deniega todo por defecto (DenyAllInBound, prioridad 65500), pero
        // esta regla lo hace explícito y auditable, y evita que una futura
        // regla "Allow *" agregada sin cuidado abra SSH accidentalmente.
        name: 'Deny-SSH-Internet'
        properties: {
          priority: 120
          direction: 'Inbound'
          access: 'Deny'
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: '${namePrefix}-vnet'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: '${namePrefix}-subnet-public'
        properties: {
          addressPrefix: subnetAddressPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: '${namePrefix}-pip'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: '${namePrefix}-nic'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}

output nicId string = nic.id
output publicIpAddress string = publicIp.properties.ipAddress
output vnetId string = vnet.id
output subnetId string = vnet.properties.subnets[0].id
