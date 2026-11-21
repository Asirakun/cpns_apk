param([string]$DevelopmentRoot = 'D:\Development')
$ErrorActionPreference = 'Stop'
$env:FLUTTER_ROOT = Join-Path $DevelopmentRoot 'flutter'
$env:PUB_CACHE = Join-Path $DevelopmentRoot 'cache\pub'
$env:ANALYZER_STATE_LOCATION_OVERRIDE = Join-Path $DevelopmentRoot 'cache\analyzer'
$env:XDG_CONFIG_HOME = Join-Path $DevelopmentRoot 'cache\config'
$env:XDG_CACHE_HOME = Join-Path $DevelopmentRoot 'cache'
$env:TEMP = Join-Path $DevelopmentRoot 'cache\tmp'
$env:TMP = $env:TEMP
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
Push-Location (Split-Path -Parent $PSScriptRoot)
try {
  foreach ($scenario in @('home','profile','profile-icons','preparation','tryouts','history','priorities','daily','weekly','monthly','category','navigator','light-large')) {
    & "$env:FLUTTER_ROOT\bin\flutter.bat" test test\ui_v12_preview_test.dart --no-pub --dart-define=CAPTURE_PREVIEWS=true "--dart-define=PREVIEW_SCENARIO=$scenario" --reporter expanded
    if ($LASTEXITCODE -ne 0) { throw "Preview render failed: $scenario" }
  }
} finally { Pop-Location }
