param(
  [string]$DevelopmentRoot = 'D:\Development',
  [string]$JdkDirectory = 'D:\Android\jbr',
  [switch]$CaptureIntroPreviews
)
$ErrorActionPreference = 'Stop'
if ($DevelopmentRoot -notmatch '^D:\\' -or $JdkDirectory -notmatch '^D:\\') {
  throw 'Flutter, JDK, Android SDK and caches must be on drive D.'
}
$projectDirectory = Split-Path -Parent $PSScriptRoot
$env:FLUTTER_ROOT = Join-Path $DevelopmentRoot 'flutter'
$env:JAVA_HOME = $JdkDirectory
$cache = Join-Path $DevelopmentRoot 'cache'
$env:PUB_CACHE = Join-Path $cache 'pub'
$env:GRADLE_USER_HOME = Join-Path $cache 'gradle'
$env:ANDROID_HOME = Join-Path $DevelopmentRoot 'Android\Sdk'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:ANDROID_USER_HOME = Join-Path $cache 'android'
$env:ANDROID_AVD_HOME = Join-Path $DevelopmentRoot 'Android\Avd'
$env:ANALYZER_STATE_LOCATION_OVERRIDE = Join-Path $cache 'analyzer'
$env:XDG_CONFIG_HOME = Join-Path $cache 'config'
$env:XDG_CACHE_HOME = $cache
$env:TEMP = Join-Path $cache 'tmp'
$env:TMP = $env:TEMP
$env:npm_config_cache = Join-Path $cache 'npm'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
$env:DEBUG = ''
$env:Path = "$env:FLUTTER_ROOT\bin;$env:JAVA_HOME\bin;$env:ANDROID_HOME\platform-tools;$env:Path"
New-Item -ItemType Directory -Path $env:TEMP -Force | Out-Null
if (-not (Test-Path -LiteralPath (Join-Path $JdkDirectory 'release')) -or
    (Get-Content -LiteralPath (Join-Path $JdkDirectory 'release') -Raw) -notmatch 'JAVA_VERSION="21\.') {
  throw 'Use a JDK 21 installation.'
}
function Invoke-Gradle([string[]]$GradleArgs) {
  Push-Location (Join-Path $projectDirectory 'android')
  try {
    & .\gradlew.bat @GradleArgs --console=plain --quiet
    if ($LASTEXITCODE -ne 0) { throw 'Gradle verification failed.' }
  } finally { Pop-Location }
}
Push-Location $projectDirectory
try {
  if (-not (Test-Path -LiteralPath 'android\key.properties')) { throw 'Configure a private release key first.' }
  if (-not (Test-Path -LiteralPath 'node_modules\@electric-sql\pglite')) { throw 'Run npm ci --ignore-scripts before verification.' }
  $flutter = Join-Path $env:FLUTTER_ROOT 'bin\flutter.bat'
  & $flutter --suppress-analytics pub get --enforce-lockfile
  if ($LASTEXITCODE -ne 0) { throw 'Dependency lockfile verification failed.' }
  & $flutter --suppress-analytics analyze --no-pub
  if ($LASTEXITCODE -ne 0) { throw 'Dart analysis failed.' }
  $testArgs = @('--suppress-analytics','test','--no-pub','--concurrency=1','--reporter','expanded')
  if ($CaptureIntroPreviews) { $testArgs += '--dart-define=CAPTURE_INTRO_PREVIEWS=true' }
  & $flutter @testArgs
  if ($LASTEXITCODE -ne 0) { throw 'Flutter tests failed.' }
  node supabase\tests\security.mjs
  if ($LASTEXITCODE -ne 0) { throw 'Database security tests failed.' }
  node scripts\scan_source_secrets.mjs
  if ($LASTEXITCODE -ne 0) { throw 'Source secret scan failed.' }
  $lockHash = (Get-FileHash -LiteralPath 'pubspec.lock' -Algorithm SHA256).Hash
  $versionMatch = [regex]::Match((Get-Content -LiteralPath 'pubspec.yaml' -Raw), '(?m)^version:\s*(\d+\.\d+\.\d+)\+\d+\s*$')
  if (-not $versionMatch.Success) { throw 'Cannot determine the release version.' }
  $symbols = Join-Path $DevelopmentRoot ('symbols\cpns-' + $versionMatch.Groups[1].Value)
  # Pub must be enabled here to regenerate release registrants after tests.
  & $flutter --suppress-analytics build apk --release --target-platform android-arm64 --split-per-abi --obfuscate "--split-debug-info=$symbols"
  if ($LASTEXITCODE -ne 0) { throw 'Release build failed.' }
  if ((Get-FileHash -LiteralPath 'pubspec.lock' -Algorithm SHA256).Hash -ne $lockHash) { throw 'Dependencies changed during build; repeat the audit.' }
  # Flutter writes unescaped drive colons; normalize its local Windows paths
  # before Android Lint without disabling PropertyEscape or hiding errors.
  $localProperties = Get-Content -LiteralPath 'android\local.properties' -Raw
  $localProperties = [regex]::Replace($localProperties, '(?m)^([^=\r\n]+=)([A-Za-z]):', '$1$2\:')
  [IO.File]::WriteAllText((Join-Path $projectDirectory 'android\local.properties'), $localProperties, [Text.Encoding]::ASCII)
  Invoke-Gradle -GradleArgs @(':app:lintRelease')
  Invoke-Gradle -GradleArgs @('-I','..\scripts\security_dependencies.init.gradle',':app:securityDependencyInventory')
  node scripts\audit_dependencies.mjs
  if ($LASTEXITCODE -ne 0) { throw 'Dependency advisory audit failed.' }
  & .\scripts\verify_release_apk.ps1 -SdkRoot $env:ANDROID_HOME
  & .\scripts\verify_ui_release_assets.ps1 -SdkRoot $env:ANDROID_HOME
} finally { Pop-Location }
