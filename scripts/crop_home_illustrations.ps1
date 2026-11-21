param([Parameter(Mandatory=$true)][string]$AtlasPath)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
public static class HomeIllustrationBounds {
  public static Rectangle Find(Bitmap image) {
    int left=image.Width, top=image.Height, right=-1, bottom=-1;
    for (int y=0; y<image.Height; y++) for (int x=0; x<image.Width; x++) {
      if (image.GetPixel(x,y).A > 32) { left=Math.Min(left,x); top=Math.Min(top,y); right=Math.Max(right,x); bottom=Math.Max(bottom,y); }
    }
    if (right<left) throw new InvalidOperationException("Empty illustration cell.");
    left=Math.Max(0,left-8); top=Math.Max(0,top-8); right=Math.Min(image.Width-1,right+8); bottom=Math.Min(image.Height-1,bottom+8);
    return Rectangle.FromLTRB(left,top,right+1,bottom+1);
  }
}
'@
$outputDirectory = Join-Path (Split-Path -Parent $PSScriptRoot) 'assets\papercut_home'
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$atlas = [Drawing.Bitmap]::FromFile((Resolve-Path -LiteralPath $AtlasPath).Path)
try {
  $names = @('welcome','focus')
  for ($index=0; $index -lt 2; $index++) {
    $width = [int][math]::Floor($atlas.Width/2)
    $cell = $atlas.Clone([Drawing.Rectangle]::new($index*$width,0,$width,$atlas.Height),[Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
      $cropped = $cell.Clone([HomeIllustrationBounds]::Find($cell),[Drawing.Imaging.PixelFormat]::Format32bppArgb)
      try { $cropped.Save((Join-Path $outputDirectory ($names[$index]+'.png')),[Drawing.Imaging.ImageFormat]::Png) } finally { $cropped.Dispose() }
    } finally { $cell.Dispose() }
  }
} finally { $atlas.Dispose() }
Write-Output 'Cropped welcome and focus illustrations; original alpha and colors preserved.'
