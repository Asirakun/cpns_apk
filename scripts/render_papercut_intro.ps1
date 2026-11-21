param([switch]$InstallDependencies)
$ErrorActionPreference = 'Stop'
$projectDirectory = Split-Path -Parent $PSScriptRoot
$introDirectory = Join-Path $projectDirectory 'tools/papercut_intro'
function Invoke-Checked([string]$Executable, [string[]]$Arguments) {
  & $Executable @Arguments
  if ($LASTEXITCODE -ne 0) { throw "Intro tool failed: $Executable ($LASTEXITCODE)" }
}
Push-Location $introDirectory
try {
  if ($InstallDependencies) { Invoke-Checked 'npm.cmd' @('ci') }
  if (-not (Test-Path -LiteralPath 'node_modules/@remotion/cli/remotion-cli.js')) {
    throw 'Run this script with -InstallDependencies first (Node 22+ required).'
  }
  New-Item -ItemType Directory -Path 'public','out/hd','../../docs/design/v1.2.1/intro' -Force | Out-Null
  Copy-Item -LiteralPath '../../assets/brand/logo.png' -Destination 'public/logo.png'
  Copy-Item -LiteralPath '../../assets/fonts/PlusJakartaSans.ttf' -Destination 'public/PlusJakartaSans.ttf'
  Invoke-Checked 'npx.cmd' @('tsc','--noEmit')
  Invoke-Checked 'node' @('export-provided.mjs')
  Invoke-Checked 'node' @('render-provided.mjs')
  Invoke-Checked 'node' @('verify-provided.mjs')
  Write-Output 'Provided cpns-intro rendered with original SFX on RTX 3050/NVENC; original visual background omitted. Inspect the v1.2.2 preview and Flutter screenshots.'
} finally { Pop-Location }
