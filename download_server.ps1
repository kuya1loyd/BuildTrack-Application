$port = 8080
$apkPath = Join-Path $PSScriptRoot "BuildTrack.apk"
$logoPath = Join-Path $PSScriptRoot "flutter\assets\images\logo.png"

if (-not (Test-Path $apkPath)) {
    Write-Warning "BuildTrack.apk not found in $PSScriptRoot"
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://*:$port/")

try {
    $listener.Start()
} catch {
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:$port/")
    $listener.Start()
}

$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -like "*Wi-Fi*" -or $_.InterfaceAlias -like "*Ethernet*" } | Select-Object -First 1).IPAddress
if (-not $ip) { $ip = "192.168.254.104" }

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " BuildTrack APK Download Server Running" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "On your PC (Browser):" -ForegroundColor Yellow
Write-Host "  http://localhost:$port/" -ForegroundColor White
Write-Host "On your Cellphone (Browser on same Wi-Fi):" -ForegroundColor Yellow
Write-Host "  http://$($ip):$port/" -ForegroundColor White
Write-Host "Direct APK download link:" -ForegroundColor Yellow
Write-Host "  http://$($ip):$port/download" -ForegroundColor White
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop the server." -ForegroundColor Gray

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    $url = $request.RawUrl

    if ($url -eq "/logo.png" -and (Test-Path $logoPath)) {
        $bytes = [System.IO.File]::ReadAllBytes($logoPath)
        $response.ContentType = "image/png"
        $response.ContentLength64 = $bytes.Length
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
        $response.Close()
        continue
    }

    if ($url -eq "/download" -or $url -eq "/BuildTrack.apk") {
        if (Test-Path $apkPath) {
            $response.ContentType = "application/vnd.android.package-archive"
            $response.AddHeader("Content-Disposition", 'attachment; filename="BuildTrack.apk"')
            $fileStream = [System.IO.File]::OpenRead($apkPath)
            $response.ContentLength64 = $fileStream.Length
            $fileStream.CopyTo($response.OutputStream)
            $fileStream.Close()
        } else {
            $response.StatusCode = 404
        }
        $response.Close()
        continue
    }

    # Default: HTML page
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Download BuildTrack</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
    body { background: #0b1120; color: #fff; min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 24px; text-align: center; }
    .card { background: #1e293b; border: 1px solid #334155; border-radius: 28px; padding: 36px 24px; max-width: 380px; width: 100%; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.6); }
    .logo-img { width: 96px; height: 96px; border-radius: 24px; margin: 0 auto 18px; display: block; box-shadow: 0 12px 28px rgba(0,0,0,0.45); }
    h1 { font-size: 24px; font-weight: 800; margin-bottom: 8px; letter-spacing: -0.3px; }
    p { color: #94a3b8; font-size: 14px; margin-bottom: 28px; line-height: 1.5; }
    .btn { display: block; background: #f59e0b; color: #000; text-decoration: none; font-weight: 700; font-size: 16px; padding: 16px; border-radius: 14px; transition: transform 0.1s; }
    .btn:active { transform: scale(0.98); background: #eab308; }
    .meta { margin-top: 16px; color: #64748b; font-size: 13px; }
    .steps { margin-top: 24px; padding-top: 20px; border-top: 1px solid #334155; text-align: left; font-size: 12px; color: #94a3b8; line-height: 1.6; }
    .steps strong { color: #fff; }
  </style>
</head>
<body>
  <div class="card">
    <img src="/logo.png" alt="BuildTrack Logo" class="logo-img">
    <h1>BuildTrack</h1>
    <p>Tap the button below to download the app directly to your phone.</p>
    <a class="btn" href="/download" download="BuildTrack.apk">📥 Download BuildTrack APK</a>
    <div class="meta">Official Release • Size: ~54 MB</div>
    <div class="steps">
      <strong>Next step:</strong> When downloaded, open your notification or Downloads folder, tap <strong>BuildTrack.apk</strong>, and tap <strong>Install</strong>.
    </div>
  </div>
</body>
</html>
"@
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
    $response.ContentType = "text/html; charset=utf-8"
    $response.ContentLength64 = $buffer.Length
    $response.OutputStream.Write($buffer, 0, $buffer.Length)
    $response.Close()
}
