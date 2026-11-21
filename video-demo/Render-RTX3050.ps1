$ErrorActionPreference = 'Stop'
$projectPath = $PSScriptRoot
$env:TEMP = Join-Path $projectPath 'tools\temp'
$env:TMP = $env:TEMP
$env:npm_config_cache = 'D:\Development\cache\npm'
New-Item -ItemType Directory -Force -Path $env:TEMP | Out-Null
Push-Location -LiteralPath $projectPath
try {
    Push-Location -LiteralPath (Join-Path $projectPath 'remotion-video')
    try {
        node render-v2.mjs final
        if ($LASTEXITCODE -ne 0) { throw 'Render gagal. Periksa pesan di atas.' }
    } finally { Pop-Location }
    node qa-v2.mjs
    if ($LASTEXITCODE -ne 0) { throw 'Pemeriksaan video gagal. Lihat out\remotion-v2\qa-report.json.' }
    Write-Host ''
    Write-Host 'Render RTX 3050 selesai dan pemeriksaan video lulus.'
    Write-Host (Join-Path $projectPath 'out\remotion-v2\CPNS_JOURNEY_REMOTION_1080p60.mp4')
} finally { Pop-Location }
