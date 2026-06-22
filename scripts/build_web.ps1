param(
  [string]$EnvFile = ".env"
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

& "$PSScriptRoot/prepare_env.ps1" -EnvFile $EnvFile

Write-Host "Building Flutter web..."
flutter build web --release --dart-define-from-file=env.json

# Restaura index.html sem chave real (placeholder seguro para o repo)
Copy-Item "web/index.template.html" "web/index.html" -Force

Write-Host "Build concluído em build/web"
