param(
  [string]$EnvFile = ".env",
  [switch]$HostingOnly,
  [switch]$RulesOnly
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

if ($RulesOnly) {
  & "$PSScriptRoot/prepare_env.ps1" -EnvFile $EnvFile
  firebase deploy --only firestore:rules,firestore:indexes
  exit $LASTEXITCODE
}

if (-not $HostingOnly) {
  & "$PSScriptRoot/build_web.ps1" -EnvFile $EnvFile
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} else {
  & "$PSScriptRoot/prepare_env.ps1" -EnvFile $EnvFile
}

Write-Host "Deploy Firebase..."
if ($HostingOnly) {
  firebase deploy --only hosting
} else {
  firebase deploy --only hosting,firestore:rules,firestore:indexes
}

Write-Host "Deploy concluído."
