$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $projectRoot '.env'
if (Test-Path -LiteralPath $configPath) { Write-Output '.env ya existe. Se conserva su configuración.'; exit 0 }
function New-Secret {
  $secretBytes = [byte[]]::new(24)
  [System.Security.Cryptography.RandomNumberGenerator]::Fill($secretBytes)
  return [Convert]::ToHexString($secretBytes)
}
$configText = "HEALTH_BASE_DOMAIN=health.localhost`nHEALTH_PUBLIC_ORIGIN=http://health.localhost:8080`nBOOTSTRAP_ADMIN_EMAIL=admin@health.localhost`nMYSQL_ROOT_PASSWORD=$(New-Secret)`nDATABASE_PASSWORD=$(New-Secret)`nBOOTSTRAP_ADMIN_PASSWORD=$(New-Secret)`n"
[System.IO.File]::WriteAllText($configPath, $configText, [System.Text.UTF8Encoding]::new($false))
Write-Output 'Configuración local generada en .env. Las contraseñas se guardan allí y no se imprimen.'
