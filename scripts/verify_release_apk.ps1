param(
  [string]$ApkPath = 'build\app\outputs\flutter-apk\app-arm64-v8a-release.apk',
  [string]$SdkRoot = 'D:\Development\Android\Sdk',
  [string]$ReportPath = 'work\release-security.json'
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$apk = (Resolve-Path -LiteralPath $ApkPath).Path
$aapt = Join-Path $SdkRoot 'build-tools\36.0.0\aapt.exe'
$signer = Join-Path $SdkRoot 'build-tools\36.0.0\apksigner.bat'
$checks = [Collections.Generic.List[object]]::new()
function Assert-Security([string]$name, [bool]$passed) {
  $checks.Add([pscustomobject]@{check=$name;passed=$passed})
  if (-not $passed) { throw "APK security verification failed: $name" }
}
$badging = (& $aapt dump badging $apk) -join "`n"
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect APK metadata.' }
$manifest = (& $aapt dump xmltree $apk AndroidManifest.xml) -join "`n"
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect packaged manifest.' }
$signature = (& $signer verify --verbose --print-certs $apk) -join "`n"
Assert-Security 'APK cryptographic signature verifies' ($LASTEXITCODE -eq 0)
Assert-Security 'Private release certificate is used' ($signature -match 'Signer #1 certificate DN: CN=CPNS Journey' -and $signature -notmatch 'CN=Android Debug')
$expectedFingerprintPath = 'docs\security\release-certificate.sha256'
Assert-Security 'Expected public signing certificate fingerprint is available' (Test-Path -LiteralPath $expectedFingerprintPath)
$expectedFingerprint = (Get-Content -LiteralPath $expectedFingerprintPath -Raw).Trim().ToLowerInvariant()
Assert-Security 'APK signer matches the recorded private release identity' ($expectedFingerprint -match '^[a-f0-9]{64}$' -and $signature.ToLowerInvariant().Contains("certificate sha-256 digest: $expectedFingerprint"))
Assert-Security 'Only ARM64 native libraries are packaged' ($badging -match "(?m)^native-code: 'arm64-v8a'\s*$")
Assert-Security 'Package ID matches CPNS Journey' ($badging -match "package: name='id.cpnsjourney.app'")
$versionMatch = [regex]::Match((Get-Content -LiteralPath 'pubspec.yaml' -Raw), '(?m)^version:\s*(\d+\.\d+\.\d+)\+\d+\s*$')
Assert-Security 'Release version and Android minimum are correct' ($versionMatch.Success -and $badging.Contains("versionName='$($versionMatch.Groups[1].Value)'") -and $badging -match "sdkVersion:'24'")
Assert-Security 'Debugging is disabled' ($manifest -notmatch 'android:debuggable[^\r\n]*\(type 0x12\)0x(?:ffffffff|1)\b')
Assert-Security 'Automatic backup is disabled' ($manifest -match 'android:allowBackup[^\r\n]*\(type 0x12\)0x0\b')
Assert-Security 'Cleartext traffic is disabled' ($manifest -match 'android:usesCleartextTraffic[^\r\n]*\(type 0x12\)0x0\b')
foreach ($attribute in @('fullBackupContent','dataExtractionRules','networkSecurityConfig')) {
  Assert-Security "Packaged manifest declares $attribute" ($manifest -match "android:$attribute")
}
$permissions = (& $aapt dump permissions $apk) -join "`n"
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect packaged permissions.' }
$allowed = @('android.permission.INTERNET','android.permission.POST_NOTIFICATIONS','android.permission.RECEIVE_BOOT_COMPLETED','android.permission.VIBRATE','id.cpnsjourney.app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION')
foreach ($match in [regex]::Matches($permissions, "uses-permission: name='([^']+)'")) {
  Assert-Security "Declared permission allowed: $($match.Groups[1].Value)" ($allowed -contains $match.Groups[1].Value)
}
$zip = [IO.Compression.ZipFile]::OpenRead($apk)
try {
  $entries = @($zip.Entries | ForEach-Object { $_.FullName })
  Assert-Security 'Release contains compiled Dart AOT code' ($entries -contains 'lib/arm64-v8a/libapp.so')
  Assert-Security 'Debug kernel is absent' (-not ($entries -match 'kernel_blob\.bin$'))
  Assert-Security 'Signing keys, local credentials and env files are absent' (-not ($entries -match '(?i)(^|/)(key\.properties|\.env(?:\.[^/]*)?|[^/]*credentials[^/]*)$|\.(jks|p12|pfx|key)$'))
  $inspectionDirectory = Join-Path (Get-Location) 'work\release-inspection'
  New-Item -ItemType Directory -Path $inspectionDirectory -Force | Out-Null
  $aotPath = Join-Path $inspectionDirectory 'libapp.so'
  $inputStream = $zip.GetEntry('lib/arm64-v8a/libapp.so').Open()
  $outputStream = [IO.File]::Create($aotPath)
  try { $inputStream.CopyTo($outputStream) } finally { $inputStream.Dispose(); $outputStream.Dispose() }
} finally { $zip.Dispose() }
$readelf = Join-Path $SdkRoot 'ndk\28.2.13676358\toolchains\llvm\prebuilt\windows-x86_64\bin\llvm-readelf.exe'
$sections = (& $readelf --sections $aotPath) -join "`n"
Assert-Security 'AOT library can be inspected' ($LASTEXITCODE -eq 0)
Assert-Security 'Packaged AOT library has no DWARF debug sections' ($sections -notmatch '\]\s+\.debug_')

$resourceTrees = @{}
$resources = (& $aapt dump --values resources $apk) -join "`n"
Assert-Security 'Notification icon survives release resource shrinking' ($LASTEXITCODE -eq 0 -and $resources -match 'drawable/ic_notification')
foreach ($resource in @('backup_rules','data_extraction_rules','network_security_config')) {
  # Release resource optimization can rename res/xml/name.xml to res/abc.xml.
  # Resolve the compiled resource table instead of assuming source filenames.
  $resourcePattern = '(?m)^\s+resource (0x[0-9a-f]+) [^\r\n]+:xml/' + [regex]::Escape($resource) + ':[^\r\n]*\r?\n\s+\(string(?:8|16)\) "([^"]+)"'
  $resourceMatch = [regex]::Match($resources, $resourcePattern)
  Assert-Security "Compiled resource $resource is present in the resource table" $resourceMatch.Success
  $attribute = switch ($resource) { 'backup_rules' { 'fullBackupContent' } 'data_extraction_rules' { 'dataExtractionRules' } 'network_security_config' { 'networkSecurityConfig' } }
  Assert-Security "Manifest binds $attribute to the inspected resource" ($manifest -match ("android:$attribute" + '[^\r\n]*@' + [regex]::Escape($resourceMatch.Groups[1].Value)))
  $tree = (& $aapt dump xmltree $apk $resourceMatch.Groups[2].Value) -join "`n"
  Assert-Security "Compiled $resource resource can be inspected" ($LASTEXITCODE -eq 0)
  $resourceTrees[$resource] = $tree
}
Assert-Security 'Network trust uses system CAs and no user CA override' ($resourceTrees.network_security_config -match '"system"' -and $resourceTrees.network_security_config -notmatch '"user"|debug-overrides')
Assert-Security 'Network security config also disables cleartext traffic' ($resourceTrees.network_security_config -match 'cleartextTrafficPermitted[^\r\n]*\(type 0x12\)0x0\b')
Assert-Security 'Legacy backup rules exclude stored app data' ($resourceTrees.backup_rules -match 'full-backup-content' -and ([regex]::Matches($resourceTrees.backup_rules, 'E: exclude')).Count -eq 5)
Assert-Security 'Cloud backup and device transfer both have exclusions' ($resourceTrees.data_extraction_rules -match 'cloud-backup' -and $resourceTrees.data_extraction_rules -match 'device-transfer' -and ([regex]::Matches($resourceTrees.data_extraction_rules, 'E: exclude')).Count -eq 10)
foreach ($domain in @('root','file','database','sharedpref','external')) {
  Assert-Security "Backup extraction excludes $domain in both transfer modes" (([regex]::Matches($resourceTrees.data_extraction_rules, ('A: domain="' + $domain + '"'))).Count -eq 2)
}

$report = [ordered]@{
  checkedAt = [DateTime]::UtcNow.ToString('o')
  apk = $apk
  sizeBytes = (Get-Item -LiteralPath $apk).Length
  sha256 = (Get-FileHash -LiteralPath $apk -Algorithm SHA256).Hash.ToLowerInvariant()
  checks = $checks
  metadata = $badging.Split("`n") | Where-Object { $_ -match '^(package:|sdkVersion:|targetSdkVersion:|native-code:)' }
  signature = $signature
  scope = 'Static verification of this APK. Does not certify runtime behavior, a hosted backend, or absence of malware.'
}
$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $ReportPath -Encoding UTF8
Write-Output "Passed $($checks.Count) APK verification checks."
Write-Output "SHA-256: $($report.sha256)"
Write-Output "Report: $ReportPath"
