using 'main.bicep'

param location = 'centralindia'
param namePrefix = 'poc-entrevista'
param resourceGroupName = 'POC-Entrevista'

// ─────────────────────────────────────────────────────────────────────────
// ÚNICO VALOR QUE DEBES COMPLETAR A MANO ANTES DE DESPLEGAR:
// Tu IP pública actual, en formato CIDR. Obténla con:
//   curl -s ifconfig.me
// y arma el CIDR como "<esa-ip>/32" (un solo host).
// ─────────────────────────────────────────────────────────────────────────
param sshSourceIp = '179.60.78.233/32'

// ─────────────────────────────────────────────────────────────────────────
// La SSH public key NUNCA se escribe en texto plano en este repo ni en
// GitHub. Se resuelve en tiempo de despliegue desde un Key Vault de
// "bootstrap" que debe existir ANTES de correr el stack (ver README >
// "Bootstrap del Key Vault"), usando la función az.getSecret() de Bicep.
// Reemplaza los 3 placeholders por los valores de tu suscripción/entorno
// (son de configuración, no secretos).
// ─────────────────────────────────────────────────────────────────────────
param sshPublicKey = az.getSecret(
  '033be5a6-17cf-401b-aa8a-a69fb3a90304',
  'poc-entrevista-bootstrap',
  'poc-entrevista-boot-kv',
  'ssh-public-key'
)

param vmSize = 'Standard_B1s'
param adminUsername = 'azureuser'

param budgetAmount = 5
param budgetThresholdPercentage = 80
param contactEmails = [
  'lvasqvera@gmail.com'
]

// Object ID (no el Application/Client ID) del Service Principal OIDC del
// pipeline. Se recomienda pasarlo por override en CI (--parameters
// pipelinePrincipalId=...) en vez de hardcodearlo aquí. Ver README > "OIDC".
param pipelinePrincipalId = ''
