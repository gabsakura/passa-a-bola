param(
  [string]$EnvFile = ".env"
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

function Read-EnvFile {
  param([string]$Path)
  $vars = @{}
  if (-not (Test-Path $Path)) {
    throw "Arquivo '$Path' não encontrado. Copie .env.example para .env e preencha os valores."
  }
  Get-Content $Path | ForEach-Object {
    $line = $_.Trim()
    if ($line -eq "" -or $line.StartsWith("#")) { return }
    $eq = $line.IndexOf("=")
    if ($eq -lt 1) { return }
    $key = $line.Substring(0, $eq).Trim()
    $value = $line.Substring($eq + 1).Trim()
    $vars[$key] = $value
  }
  return $vars
}

function Require-Keys {
  param(
    [hashtable]$Vars,
    [string[]]$Keys
  )
  foreach ($key in $Keys) {
    if (-not $Vars.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($Vars[$key])) {
      throw "Variável obrigatória ausente em .env: $key"
    }
  }
}

$envVars = Read-EnvFile -Path $EnvFile

Require-Keys -Vars $envVars -Keys @(
  "FIREBASE_PROJECT_ID",
  "FIREBASE_MESSAGING_SENDER_ID",
  "FIREBASE_STORAGE_BUCKET",
  "FIREBASE_WEB_API_KEY",
  "FIREBASE_WEB_APP_ID",
  "FIREBASE_WEB_AUTH_DOMAIN",
  "FIREBASE_ANDROID_API_KEY",
  "FIREBASE_ANDROID_APP_ID",
  "GOOGLE_MAPS_API_KEY"
)

# env.json para --dart-define-from-file
$dartDefines = [ordered]@{
  FIREBASE_PROJECT_ID            = $envVars["FIREBASE_PROJECT_ID"]
  FIREBASE_MESSAGING_SENDER_ID   = $envVars["FIREBASE_MESSAGING_SENDER_ID"]
  FIREBASE_STORAGE_BUCKET        = $envVars["FIREBASE_STORAGE_BUCKET"]
  FIREBASE_WEB_API_KEY           = $envVars["FIREBASE_WEB_API_KEY"]
  FIREBASE_WEB_APP_ID            = $envVars["FIREBASE_WEB_APP_ID"]
  FIREBASE_WEB_AUTH_DOMAIN       = $envVars["FIREBASE_WEB_AUTH_DOMAIN"]
  FIREBASE_WEB_MEASUREMENT_ID    = $envVars["FIREBASE_WEB_MEASUREMENT_ID"]
  FIREBASE_ANDROID_API_KEY       = $envVars["FIREBASE_ANDROID_API_KEY"]
  FIREBASE_ANDROID_APP_ID        = $envVars["FIREBASE_ANDROID_APP_ID"]
  FIREBASE_IOS_API_KEY           = $envVars["FIREBASE_IOS_API_KEY"]
  FIREBASE_IOS_APP_ID            = $envVars["FIREBASE_IOS_APP_ID"]
  FIREBASE_IOS_BUNDLE_ID         = $envVars["FIREBASE_IOS_BUNDLE_ID"]
  GOOGLE_MAPS_API_KEY            = $envVars["GOOGLE_MAPS_API_KEY"]
  APISPORTS_API_KEY              = $envVars["APISPORTS_API_KEY"]
}

$dartDefines | ConvertTo-Json | Set-Content "env.json" -Encoding utf8

# google-services.json (Android)
$googleServices = Get-Content "android/app/google-services.json.example" -Raw
foreach ($entry in $envVars.GetEnumerator()) {
  $googleServices = $googleServices.Replace($entry.Key, $entry.Value)
}
$googleServices | Set-Content "android/app/google-services.json" -Encoding utf8

# .firebaserc
$alias = if ($envVars.ContainsKey("FIREBASE_PROJECT_ALIAS") -and $envVars["FIREBASE_PROJECT_ALIAS"]) {
  $envVars["FIREBASE_PROJECT_ALIAS"]
} else {
  "default"
}
@{
  projects = @{ $alias = $envVars["FIREBASE_PROJECT_ID"] }
  targets  = @{}
  etags    = @{}
} | ConvertTo-Json | Set-Content ".firebaserc" -Encoding utf8

# web/index.html a partir do template
$mapsKey = $envVars["GOOGLE_MAPS_API_KEY"]
$indexHtml = (Get-Content "web/index.template.html" -Raw).Replace(
  "__GOOGLE_MAPS_API_KEY__",
  $mapsKey
)
[System.IO.File]::WriteAllText("$root/web/index.html", $indexHtml)

Write-Host "Ambiente preparado: env.json, google-services.json, .firebaserc, web/index.html"
