param(
  [string]$EnvFile = ".env",
  [string]$Device = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

& "$PSScriptRoot/prepare_env.ps1" -EnvFile $EnvFile

if ([string]::IsNullOrWhiteSpace($Device)) {
  $devicesOutput = flutter devices 2>&1 | Out-String
  if ($devicesOutput -match '\bchrome\b') {
    $Device = "chrome"
  } elseif ($devicesOutput -match '\bedge\b') {
    $Device = "edge"
  } else {
    $Device = "windows"
  }
  Write-Host "Usando dispositivo: $Device"
}

flutter run -d $Device --dart-define-from-file=env.json
