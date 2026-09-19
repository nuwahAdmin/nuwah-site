# Nuwah Interiors — prepare web images
# Run once from the nuwah-site folder:  .\prepare-images.ps1
# Copies + resizes source photos into assets\web\ with clean names. Originals are untouched.

Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$src  = Join-Path $root "assets"
$out  = Join-Path $root "assets\web"
New-Item -ItemType Directory -Force -Path $out | Out-Null

$maxEdge = 1800   # px on the long edge
$quality = 82     # JPEG quality

$map = @{
  "WhatsApp Image 2026-09-07 at 22.57.20.jpeg"     = "space-01.jpg"
  "WhatsApp Image 2026-09-07 at 22.57.20 (1).jpeg" = "space-02.jpg"
  "WhatsApp Image 2026-09-07 at 22.57.20 (2).jpeg" = "space-03.jpg"
  "WhatsApp Image 2026-09-07 at 22.57.21.jpeg"     = "space-04.jpg"
  "WhatsApp Image 2026-09-07 at 22.57.21 (1).jpeg" = "space-05.jpg"
  "WhatsApp Image 2026-09-07 at 22.57.21 (2).jpeg" = "space-06.jpg"
  "WhatsApp Image 2026-09-07 at 22.57.22.jpeg"     = "space-07.jpg"
  "WhatsApp Image 2026-09-07 at 22.57.22 (1).jpeg" = "space-08.jpg"
  "WhatsApp Image 2026-09-07 at 22.57.22 (2).jpeg" = "space-09.jpg"
  "WhatsApp Image 2026-09-07 at 22.57.23.jpeg"     = "space-10.jpg"
  "WhatsApp Image 2026-09-07 at 22.57.23 (1).jpeg" = "space-11.jpg"
  "WhatsApp Image 2026-09-07 at 22.57.24.jpeg"     = "space-12.jpg"
  "WhatsApp Image 2026-09-05 at 11.08.44.jpeg"     = "factory-01.jpg"
  "WhatsApp Image 2026-09-05 at 11.08.45.jpeg"     = "factory-02.jpg"
  "WhatsApp Image 2026-09-05 at 11.08.45 (1).jpeg" = "factory-03.jpg"
  "WhatsApp Image 2026-09-05 at 11.08.46.jpeg"     = "factory-04.jpg"
  "WhatsApp Image 2026-09-05 at 11.08.46 (1).jpeg" = "factory-05.jpg"
  "WhatsApp Image 2026-09-05 at 11.08.47.jpeg"     = "factory-06.jpg"
}

$codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
$encParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
$encParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]$quality)

foreach ($k in $map.Keys) {
  $in = Join-Path $src $k
  if (-not (Test-Path $in)) { Write-Warning "Missing: $k"; continue }
  $img = [System.Drawing.Image]::FromFile($in)

  # Respect EXIF orientation (phone photos)
  if ($img.PropertyIdList -contains 0x0112) {
    $o = $img.GetPropertyItem(0x0112).Value[0]
    switch ($o) {
      3 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone) }
      6 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone) }
      8 { $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone) }
    }
  }

  $scale = [Math]::Min(1.0, [double]$maxEdge / [Math]::Max($img.Width, $img.Height))
  $w = [int]($img.Width * $scale); $h = [int]($img.Height * $scale)
  $bmp = New-Object System.Drawing.Bitmap($w, $h)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.DrawImage($img, 0, 0, $w, $h)
  $bmp.Save((Join-Path $out $map[$k]), $codec, $encParams)
  $g.Dispose(); $bmp.Dispose(); $img.Dispose()
  Write-Host ("{0}  ->  {1}  ({2}x{3})" -f $k, $map[$k], $w, $h)
}
Write-Host "`nDone. Web images are in assets\web\"
