targetScope = 'subscription'

@description('Región de Azure para todos los recursos')
param location string = 'centralindia'

@description('Prefijo usado para nombrar los recursos')
param namePrefix string = 'poc-entrevista'

@description('Nombre del Resource Group creado por este stack')
param resourceGroupName string = 'POC-Entrevista'

@description('IP pública de origen (CIDR, ej. "203.0.113.10/32") permitida para SSH. Único valor que debes completar manualmente antes de desplegar (ver README).')
param sshSourceIp string

@description('SSH public key a inyectar en la VM y guardar en Key Vault. Se resuelve vía az.getSecret() desde un Key Vault de bootstrap — nunca se escribe en texto plano.')
@secure()
param sshPublicKey string

@description('SKU de la VM. Fallback documentado en README si no hay cuota: Standard_B2ats_v2')
param vmSize string = 'Standard_B1s'

@description('Usuario administrador de la VM')
param adminUsername string = 'azureuser'

@description('Monto mensual del budget en USD')
param budgetAmount int = 5

@description('Umbral de alerta del budget, en porcentaje')
param budgetThresholdPercentage int = 80

@description('Correos a notificar en la alerta de budget')
param contactEmails array = [
  'lvasqvera@gmail.com'
]

@description('Object ID (principalId) del Service Principal OIDC del pipeline. Vacío = no se crea el role assignment "Key Vault Secrets User" dentro del stack.')
param pipelinePrincipalId string = ''

var tags = {
  project: 'poc-entrevista'
  managedBy: 'deployment-stack'
  environment: 'demo'
}

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module keyVault 'modules/keyvault.bicep' = {
  name: 'keyvault-deployment'
  scope: rg
  params: {
    location: location
    namePrefix: namePrefix
    sshPublicKey: sshPublicKey
    pipelinePrincipalId: pipelinePrincipalId
    tags: tags
  }
}

module network 'modules/network.bicep' = {
  name: 'network-deployment'
  scope: rg
  params: {
    location: location
    namePrefix: namePrefix
    sshSourceIp: sshSourceIp
    tags: tags
  }
}

module compute 'modules/compute.bicep' = {
  name: 'compute-deployment'
  scope: rg
  params: {
    location: location
    namePrefix: namePrefix
    adminUsername: adminUsername
    vmSize: vmSize
    nicId: network.outputs.nicId
    sshPublicKey: sshPublicKey
    tags: tags
  }
}

module budget 'modules/budget.bicep' = {
  name: 'budget-deployment'
  scope: rg
  params: {
    namePrefix: namePrefix
    budgetAmount: budgetAmount
    budgetThresholdPercentage: budgetThresholdPercentage
    contactEmails: contactEmails
  }
}

output resourceGroupName string = rg.name
output keyVaultName string = keyVault.outputs.keyVaultName
output vmName string = compute.outputs.vmName
output vmPublicIp string = network.outputs.publicIpAddress
