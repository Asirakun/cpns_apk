param(
  [string]$ApkPath = 'build/app/outputs/flutter-apk/app-arm64-v8a-release.apk',
  [string]$SdkRoot = 'D:\Development\Android\Sdk',
  [string]$ReportPath = 'work/ui-assets.json'
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Drawing
$apk = (Resolve-Path -LiteralPath $ApkPath).Path
$aapt = Join-Path $SdkRoot 'build-tools/36.0.0/aapt.exe'
$checks = [Collections.Generic.List[object]]::new()
function Assert-UI([string]$Name, [bool]$Passed) {
  $checks.Add([ordered]@{check=$Name;passed=$Passed})
  if (-not $Passed) { throw "UI asset verification failed: $Name" }
}
$resources = (& $aapt dump --values resources $apk) -join "`n"
if ($LASTEXITCODE -ne 0) { throw 'Cannot read APK resources.' }
$zip = [IO.Compression.ZipFile]::OpenRead($apk)
try {
  $assets = @(Get-ChildItem -LiteralPath 'assets/papercut','assets/papercut_home','assets/papercut_functions','assets/brand','assets/intro' -File)
  foreach ($asset in $assets) {
    $relative = $asset.FullName.Substring((Get-Location).Path.Length+1).Replace('\','/')
    $entry = $zip.GetEntry('assets/flutter_assets/'+$relative)
    Assert-UI "Packaged asset exists: $relative" ($null -ne $entry)
    $stream = $entry.Open(); $sha = [Security.Cryptography.SHA256]::Create()
    try { $actual = ([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-','').ToLowerInvariant() }
    finally { $sha.Dispose(); $stream.Dispose() }
    Assert-UI "Packaged asset matches reviewed source: $relative" ($actual -eq (Get-FileHash -LiteralPath $asset.FullName -Algorithm SHA256).Hash.ToLowerInvariant())
  }
  foreach ($kind in @('ic_launcher','ic_launcher_foreground')) {
    $pattern = '(?m)^\s+resource 0x[0-9a-f]+ [^\r\n]+:mipmap/'+$kind+':[^\r\n]*\r?\n\s+\(string(?:8|16)\) "([^"]+)"'
    $compiled = @([regex]::Matches($resources,$pattern) | ForEach-Object {$_.Groups[1].Value} | Select-Object -Unique)
    $pngs = @($compiled | Where-Object {$_ -like '*.png'})
    Assert-UI "Five compiled PNG densities for $kind" ($pngs.Count -eq 5)
    foreach ($resource in $pngs) {
      $stream = $zip.GetEntry($resource).Open()
      $image = [Drawing.Bitmap]::FromStream($stream)
      try {
        $size = $image.Width
        $density = if ($kind -eq 'ic_launcher') { @{48='mdpi';72='hdpi';96='xhdpi';144='xxhdpi';192='xxxhdpi'}[$size] }
          else { @{108='mdpi';162='hdpi';216='xhdpi';324='xxhdpi';432='xxxhdpi'}[$size] }
        Assert-UI "Expected compiled dimensions $kind ${size}px" ($null -ne $density -and $image.Height -eq $size)
        $source = [Drawing.Bitmap]::FromFile((Join-Path (Get-Location) "android/app/src/main/res/mipmap-$density/$kind.png"))
        try {
          $same = $true
          for ($y=0; $y -lt $size -and $same; $y++) {
            for ($x=0; $x -lt $size; $x++) {
              $actualPixel=$image.GetPixel($x,$y);$sourcePixel=$source.GetPixel($x,$y)
              # PNG optimizers may change invisible RGB at alpha=0.
              if ($actualPixel.A -ne $sourcePixel.A -or ($actualPixel.A -gt 0 -and $actualPixel.ToArgb() -ne $sourcePixel.ToArgb())) { $same=$false; break }
            }
          }
          Assert-UI "Compiled $kind $density visible pixels match generated logo" $same
        } finally { $source.Dispose() }
      } finally { $image.Dispose(); $stream.Dispose() }
    }
    if ($kind -eq 'ic_launcher') {
      $adaptive = @($compiled | Where-Object {$_ -like '*.xml'})
      Assert-UI 'Adaptive launcher XML is packaged' ($adaptive.Count -ge 1)
      $tree = (& $aapt dump xmltree $apk $adaptive[0]) -join "`n"
      Assert-UI 'Adaptive launcher references foreground and background resources' ($LASTEXITCODE -eq 0 -and $tree -match 'E: adaptive-icon' -and $tree -match 'E: foreground' -and $tree -match 'E: background')
      Assert-UI 'Adaptive launcher includes a themed monochrome layer' ($tree -match 'E: monochrome')
    }
  }
  Assert-UI 'No raw design atlas, preview video or Remotion tooling in APK' (-not ($zip.Entries.FullName -match 'function-icons-atlas|logo-source|papercut-intro\.mp4|tools/papercut_intro|node_modules'))
  Assert-UI 'Obsolete compressed intro and optional WebP previews are absent' (-not ($zip.Entries.FullName -match '^assets/flutter_assets/assets/intro/.*\.webp$'))
  $sound = $zip.GetEntry('assets/flutter_assets/assets/intro/intro-sfx.wav')
  Assert-UI 'Intro SFX WAV is stored uncompressed for Android asset file descriptor playback' ($null -ne $sound -and $sound.Length -eq $sound.CompressedLength)
} finally { $zip.Dispose() }
$report = [ordered]@{checkedAt=[DateTime]::UtcNow.ToString('o');apk=$apk;sha256=(Get-FileHash -LiteralPath $apk -Algorithm SHA256).Hash.ToLowerInvariant();reviewedFlutterAssets=$assets.Count;checks=$checks;scope='Packaged UI source bytes and compiled launcher pixel verification; not a device launcher/playback test.'}
$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $ReportPath -Encoding UTF8
Write-Output "Passed $($checks.Count) UI asset checks for $($assets.Count) Flutter assets and legacy/adaptive launcher."
