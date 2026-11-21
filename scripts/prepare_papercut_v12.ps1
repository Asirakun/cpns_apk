param(
  [string]$AtlasPath = 'docs/design/v1.2.0/function-icons-atlas-clean.png',
  [string]$LogoPath = 'docs/design/v1.2.0/logo-source.png'
)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path -Parent $PSScriptRoot
function Save-Png([Drawing.Image]$Source,[Drawing.Rectangle]$SourceBounds,[int]$Size,[string]$Path,[double]$Fill=0.9,[bool]$Opaque=$false) {
 $canvas=[Drawing.Bitmap]::new($Size,$Size,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
 $g=[Drawing.Graphics]::FromImage($canvas)
 try {
  $g.Clear($(if($Opaque){[Drawing.Color]::FromArgb(255,10,38,62)}else{[Drawing.Color]::Transparent}))
  $g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $scale=$Size*$Fill/[math]::Max($SourceBounds.Width,$SourceBounds.Height)
  $width=[int]($SourceBounds.Width*$scale);$height=[int]($SourceBounds.Height*$scale)
  $destination=[Drawing.Rectangle]::new([int](($Size-$width)/2),[int](($Size-$height)/2),$width,$height)
  $g.DrawImage($Source,$destination,$SourceBounds,[Drawing.GraphicsUnit]::Pixel)
  $canvas.Save($Path,[Drawing.Imaging.ImageFormat]::Png)
 } finally {$g.Dispose();$canvas.Dispose()}
}
function Visible-Bounds([Drawing.Bitmap]$Bitmap) {
 $left=$Bitmap.Width;$top=$Bitmap.Height;$right=0;$bottom=0
 for($y=0;$y -lt $Bitmap.Height;$y++){for($x=0;$x -lt $Bitmap.Width;$x++){
  if($Bitmap.GetPixel($x,$y).A -gt 100){$left=[math]::Min($left,$x);$top=[math]::Min($top,$y);$right=[math]::Max($right,$x);$bottom=[math]::Max($bottom,$y)}
 }}
 $left=[math]::Max(0,$left-4);$top=[math]::Max(0,$top-4)
 $right=[math]::Min($Bitmap.Width-1,$right+4);$bottom=[math]::Min($Bitmap.Height-1,$bottom+4)
 return [Drawing.Rectangle]::FromLTRB($left,$top,$right+1,$bottom+1)
}
$output=Join-Path $root 'assets/papercut_functions'
New-Item -ItemType Directory -Path $output -Force | Out-Null
$names=@('cloudSync','backup','privacy','sources','settings','formation','announcements','results','briefcase','wallet','analytics','review','logout','search','download','device','moon','help','plan','verified')
$atlas=[Drawing.Bitmap]::FromFile((Resolve-Path -LiteralPath $AtlasPath).Path)
try {for($i=0;$i -lt $names.Count;$i++){
 $left=[int][math]::Floor(($i%5)*$atlas.Width/5);$right=[int][math]::Floor((($i%5)+1)*$atlas.Width/5)
 $top=[int][math]::Floor([math]::Floor($i/5)*$atlas.Height/4);$bottom=[int][math]::Floor(([math]::Floor($i/5)+1)*$atlas.Height/4)
 $cell=$atlas.Clone([Drawing.Rectangle]::FromLTRB($left,$top,$right,$bottom),[Drawing.Imaging.PixelFormat]::Format32bppArgb)
 try {Save-Png $cell (Visible-Bounds $cell) 256 (Join-Path $output ($names[$i]+'.png')) 0.9} finally {$cell.Dispose()}
}} finally {$atlas.Dispose()}
$brand=Join-Path $root 'assets/brand'
New-Item -ItemType Directory -Path $brand -Force | Out-Null
$logo=[Drawing.Bitmap]::FromFile((Resolve-Path -LiteralPath $LogoPath).Path)
try {
 $bounds=Visible-Bounds $logo
 Save-Png $logo $bounds 512 (Join-Path $brand 'logo.png') 0.89
 foreach($entry in @(@('mdpi',48,108),@('hdpi',72,162),@('xhdpi',96,216),@('xxhdpi',144,324),@('xxxhdpi',192,432))){
  $dir=Join-Path $root ('android/app/src/main/res/mipmap-'+$entry[0]);New-Item -ItemType Directory -Path $dir -Force | Out-Null
  Save-Png $logo $bounds $entry[1] (Join-Path $dir 'ic_launcher.png') 0.82 $true
  Save-Png $logo $bounds $entry[2] (Join-Path $dir 'ic_launcher_foreground.png') 0.58
 }
} finally {$logo.Dispose()}
Write-Output 'Prepared 20 distinct function icons, brand logo, and five launcher/adaptive densities.'
