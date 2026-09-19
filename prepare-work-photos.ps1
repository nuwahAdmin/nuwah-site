# Nuwah Interiors — prepare portfolio work photos
# Reads the reviewed selection below, resizes into assets\web\work-NN.jpg and writes
# _review\gallery-snippet.html with the <figure> markup for portfolio.html.
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$src  = "C:\Users\ITX-Station\Projects\Nuwah Site\Essentials\Sample Work Photos"
$rev  = "C:\Users\ITX-Station\Projects\Nuwah Site\_review"
$out  = Join-Path $root "assets\web"
New-Item -ItemType Directory -Force -Path $out | Out-Null

$maxEdge = 1600; $quality = 80
$manifest = Import-Csv (Join-Path $rev "manifest.csv")
$byIdx = @{}; foreach ($m in $manifest) { $byIdx[[int]$m.idx] = $m.name }

# Reviewed selection (index in manifest) by category. Near-duplicate angles left out.
$sel = [ordered]@{
  living  = @(9,22,98,3,1,51,35,64,109,88,44,4,5,18,25,29,34,36,37,38,45,48,52,53,54,56,59,61,65,67,72,75,76,78,81,86,89,90,91,99,103,112)
  bedroom = @(11,74,92,26,79,0,2,16,20,24,31,32,39,43,49,50,55,60,68,70,80,95,104)
  dining  = @(7,21,69,102,8,19,27,62,71,77,87,93,97,105,106,110)
  details = @(23,28,40,42,15,107,108)
}
$captions = @{ living = "Living"; bedroom = "Bedroom"; dining = "Dining &amp; kitchen"; details = "Details" }

$codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
$ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
$ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]$quality)

$html = New-Object System.Text.StringBuilder
$n = 0
foreach ($cat in $sel.Keys) {
  foreach ($idx in $sel[$cat]) {
    $n++
    $name = "work-{0:d2}.jpg" -f $n
    $in = Join-Path $src $byIdx[$idx]
    if (-not (Test-Path $in)) { Write-Warning "Missing idx $idx : $($byIdx[$idx])"; continue }
    $img = [System.Drawing.Image]::FromFile($in)
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
    $bmp.Save((Join-Path $out $name), $codec, $ep)
    $g.Dispose(); $bmp.Dispose(); $img.Dispose()
    $orient = if ($w -gt $h) { " wide" } else { "" }
    [void]$html.AppendLine(('      <figure class="{0}{1}" data-cat="{0}"><img src="assets/web/{2}" alt="{3} {5} furnished by Nuwah Interiors" loading="lazy" /><figcaption>{3}</figcaption></figure>' -f $cat, $orient, $name, $captions[$cat], $null, [string][char]0x2014))
    Write-Host ("{0,3}  {1}  {2}x{3}  <- {4}" -f $n, $name, $w, $h, $byIdx[$idx])
  }
}
[IO.File]::WriteAllText((Join-Path $rev "gallery-snippet.html"), $html.ToString())
Write-Host "`nDone: $n photos in assets\web\, markup in _review\gallery-snippet.html"
