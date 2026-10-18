Add-Type -AssemblyName System.Drawing
$sourcePath = 'C:\Users\galit\BuildTrack\flutter\assets\images\logo.png'
$src = [System.Drawing.Image]::FromFile($sourcePath)

function Resize-Image($img, $width, $height, $outPath) {
    $destRect = New-Object System.Drawing.Rectangle(0, 0, $width, $height)
    $destImage = New-Object System.Drawing.Bitmap($width, $height)
    $destImage.SetResolution($img.HorizontalResolution, $img.VerticalResolution)
    $graphics = [System.Drawing.Graphics]::FromImage($destImage)
    $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.DrawImage($img, $destRect, 0, 0, $img.Width, $img.Height, [System.Drawing.GraphicsUnit]::Pixel)
    $graphics.Dispose()
    $destImage.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $destImage.Dispose()
    Write-Host "Generated: $outPath ($width x $height)"
}

function Generate-Foreground($img, $canvasSize, $logoSize, $outPath) {
    $offset = [int](($canvasSize - $logoSize) / 2)
    $destRect = New-Object System.Drawing.Rectangle($offset, $offset, $logoSize, $logoSize)
    $destImage = New-Object System.Drawing.Bitmap($canvasSize, $canvasSize)
    $destImage.SetResolution($img.HorizontalResolution, $img.VerticalResolution)
    $graphics = [System.Drawing.Graphics]::FromImage($destImage)
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.DrawImage($img, $destRect, 0, 0, $img.Width, $img.Height, [System.Drawing.GraphicsUnit]::Pixel)
    $graphics.Dispose()
    $destImage.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $destImage.Dispose()
    Write-Host "Generated Foreground: $outPath ($canvasSize x $canvasSize)"
}

# Android mipmap launcher icons (Standard)
Resize-Image $src 48 48 'C:\Users\galit\BuildTrack\flutter\android\app\src\main\res\mipmap-mdpi\ic_launcher.png'
Resize-Image $src 72 72 'C:\Users\galit\BuildTrack\flutter\android\app\src\main\res\mipmap-hdpi\ic_launcher.png'
Resize-Image $src 96 96 'C:\Users\galit\BuildTrack\flutter\android\app\src\main\res\mipmap-xhdpi\ic_launcher.png'
Resize-Image $src 144 144 'C:\Users\galit\BuildTrack\flutter\android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png'
Resize-Image $src 192 192 'C:\Users\galit\BuildTrack\flutter\android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png'

# Android mipmap round icons (For Pixel / Samsung launchers)
Resize-Image $src 48 48 'C:\Users\galit\BuildTrack\flutter\android\app\src\main\res\mipmap-mdpi\ic_launcher_round.png'
Resize-Image $src 72 72 'C:\Users\galit\BuildTrack\flutter\android\app\src\main\res\mipmap-hdpi\ic_launcher_round.png'
Resize-Image $src 96 96 'C:\Users\galit\BuildTrack\flutter\android\app\src\main\res\mipmap-xhdpi\ic_launcher_round.png'
Resize-Image $src 144 144 'C:\Users\galit\BuildTrack\flutter\android\app\src\main\res\mipmap-xxhdpi\ic_launcher_round.png'
Resize-Image $src 192 192 'C:\Users\galit\BuildTrack\flutter\android\app\src\main\res\mipmap-xxxhdpi\ic_launcher_round.png'

# Android Adaptive Icon Foregrounds
Generate-Foreground $src 108 72 'C:\Users\galit\BuildTrack\flutter\android\app\src\main\res\mipmap-mdpi\ic_launcher_foreground.png'
Generate-Foreground $src 162 108 'C:\Users\galit\BuildTrack\flutter\android\app\src\main\res\mipmap-hdpi\ic_launcher_foreground.png'
Generate-Foreground $src 216 144 'C:\Users\galit\BuildTrack\flutter\android\app\src\main\res\mipmap-xhdpi\ic_launcher_foreground.png'
Generate-Foreground $src 324 216 'C:\Users\galit\BuildTrack\flutter\android\app\src\main\res\mipmap-xxhdpi\ic_launcher_foreground.png'
Generate-Foreground $src 432 288 'C:\Users\galit\BuildTrack\flutter\android\app\src\main\res\mipmap-xxxhdpi\ic_launcher_foreground.png'

# Web icons
Resize-Image $src 32 32 'C:\Users\galit\BuildTrack\flutter\web\favicon.png'
Resize-Image $src 192 192 'C:\Users\galit\BuildTrack\flutter\web\icons\Icon-192.png'
Resize-Image $src 512 512 'C:\Users\galit\BuildTrack\flutter\web\icons\Icon-512.png'
Resize-Image $src 192 192 'C:\Users\galit\BuildTrack\flutter\web\icons\Icon-maskable-192.png'
Resize-Image $src 512 512 'C:\Users\galit\BuildTrack\flutter\web\icons\Icon-maskable-512.png'

$src.Dispose()
Write-Host "All Android & Web icons generated successfully!"
