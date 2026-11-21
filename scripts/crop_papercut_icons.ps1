param([Parameter(Mandatory=$true)][string]$AtlasPath)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$outputDirectory = Join-Path (Split-Path -Parent $PSScriptRoot) 'assets\papercut'
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$atlas = [Drawing.Bitmap]::FromFile((Resolve-Path -LiteralPath $AtlasPath).Path)
$names = @('book','checklist','route','home','target','graduation','documents','calendar','bell','medal','sprout','flashcards','avatar','shield','clock','balloon')
try {
  for ($index = 0; $index -lt $names.Count; $index++) {
    $left = [int][math]::Floor(($index % 4) * $atlas.Width / 4)
    $top = [int][math]::Floor([math]::Floor($index / 4) * $atlas.Height / 4)
    $cellWidth = [int][math]::Floor($atlas.Width / 4)
    $cellHeight = [int][math]::Floor($atlas.Height / 4)
    $bounds = [Drawing.Rectangle]::new($left,$top,$cellWidth,$cellHeight)
    $cell = $atlas.Clone($bounds,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $output = [Drawing.Bitmap]::new(320,320,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [Drawing.Graphics]::FromImage($output)
    try {
      $graphics.Clear([Drawing.Color]::Transparent)
      $graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
      $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
      $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
      $graphics.DrawImage($cell,[Drawing.Rectangle]::new(0,0,320,320))
      $output.Save((Join-Path $outputDirectory ($names[$index] + '.png')),[Drawing.Imaging.ImageFormat]::Png)
    } finally { $graphics.Dispose(); $output.Dispose(); $cell.Dispose() }
  }
} finally { $atlas.Dispose() }
Write-Output 'Cropped 16 icons from the 4 by 4 atlas, preserving alpha.'
