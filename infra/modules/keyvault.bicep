@description('Región donde se despliega el Key Vault')
param location string

@description('Prefijo usado para nombrar los recursos')
param namePrefix string

@description('Valor de la SSH public key que se guarda como secreto en el Key Vault')
@secure()
param sshPublicKey string

@description('Object ID (principalId) del Service Principal del pipeline OIDC al que se le otorga el rol "Key Vault Secrets User" sobre este vault. Vacío = no se crea el role assignment.')
param pipelinePrincipalId string = ''

@description('Tags aplicados a los recursos')
param tags object = {}

// Nombre de Key Vault: máx 24 caracteres, alfanumérico + guiones, único globalmente.
var keyVaultName = take('${replace(namePrefix, '-', '')}kv${uniqueString(resourceGroup().id)}', 24)

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    // RBAC en vez de access policies legacy, tal como exige el ejercicio.
    enableRbacAuthorization: true
    accessPolicies: []
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    // Esta suscripción exige purge protection habilitada en todo Key Vault
    // nuevo (el deploy falla con BadRequest si se intenta enablePurgeProtection:
    // false). Implica que si se borra el stack y se redespliega, el nombre
    // determinístico del vault puede chocar con uno soft-deleted durante la
    // ventana de retención — ver README > "Recrear el entorno".
    enablePurgeProtection: true
    // Acceso público habilitado a propósito: es un vault de demo sin Private
    // Endpoint (fuera de alcance para un POC de $5/mes). El acceso real está
    // protegido por RBAC (enableRbacAuthorization) más abajo, no por red.
    publicNetworkAccess: 'Enabled'
  }
}

resource sshPublicKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'ssh-public-key'
  properties: {
    value: sshPublicKey
    contentType: 'ssh-public-key'
  }
}

// Permiso mínimo: el pipeline solo puede LEER secretos de este vault puntual,
// no administrar el vault ni acceder a otros recursos.
resource pipelineSecretsUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(pipelinePrincipalId)) {
  scope: keyVault
  name: guid(keyVault.id, pipelinePrincipalId, 'KeyVaultSecretsUser')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: pipelinePrincipalId
    principalType: 'ServicePrincipal'
  }
}

output keyVaultName string = keyVault.name
output keyVaultId string = keyVault.id
