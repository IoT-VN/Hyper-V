# ===============================
# STEP 0: ADMIN CHECK
# ===============================
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] Please run PowerShell as Administrator" -ForegroundColor Red
    pause
    exit
}
Write-Host "[OK] Running as Administrator"
Write-Host ""

# ===============================
# STEP 1: CHECK PYTHON 3.10 (USER MODE)
# ===============================
$py = "$env:LOCALAPPDATA\Programs\Python\Python310\python.exe"

if (-not (Test-Path $py)) {
    Write-Host "[STEP] Installing Python 3.10 (per-user)..."

    $pythonUrl = "https://www.python.org/ftp/python/3.10.0/python-3.10.0-amd64.exe"
    $installer = "$env:TEMP\python310.exe"

    Invoke-WebRequest $pythonUrl -OutFile $installer

    Start-Process $installer -Wait -ArgumentList `
        "/quiet InstallAllUsers=0 PrependPath=0 Include_pip=1"

    if (-not (Test-Path $py)) {
        Write-Host "[ERROR] Python install failed" -ForegroundColor Red
        pause
        exit
    }

    Write-Host "[OK] Python installed"
} else {
    Write-Host "[OK] Python already installed"
}

& $py --version
Write-Host ""

# ===============================
# STEP 2: CHECK gdown
# ===============================
if (-not (& $py -m pip show gdown 2>$null)) {
    Write-Host "[STEP] Installing gdown..."
    & $py -m ensurepip --upgrade
    & $py -m pip install --upgrade pip
    & $py -m pip install --upgrade gdown
    Write-Host "[OK] gdown installed"
} else {
    Write-Host "[OK] gdown already installed"
}

Write-Host ""

# ===============================
# STEP 3: PREPARE C:\WIN
# ===============================
$winDir = "C:\WIN"
$vhdx   = "$winDir\QUY.vhdx"
$expectHash = "89f78895c638219c270fe6dfd87174eea7e901880d6596dd2fa8a84c357ca784"

if (-not (Test-Path $winDir)) {
    New-Item -ItemType Directory -Path $winDir | Out-Null
    Write-Host "[OK] Created C:\WIN"
}

# ===============================
# STEP 4: CHECK EXISTING VHDX HASH
# ===============================
$needDownload = $true

if (Test-Path $vhdx) {
    Write-Host "[INFO] QUY.vhdx exists, checking SHA256..."

    $currentHash = (certutil -hashfile $vhdx SHA256 |
        Select-String -Pattern "^[0-9a-fA-F]{64}" |
        ForEach-Object { $_.Line }).ToLower()

    Write-Host "[INFO] Current SHA256: $currentHash"

    if ($currentHash -eq $expectHash) {
        Write-Host "[OK] SHA256 match. Skip download."
        $needDownload = $false
    } else {
        Write-Host "[WARN] SHA256 mismatch. Will re-download."
        Remove-Item $vhdx -Force
    }
}

# ===============================
# STEP 5: DOWNLOAD IF NEEDED
# ===============================
if ($needDownload) {
    Write-Host "[STEP] Downloading QUY.vhdx..."

    & $py -m gdown `
      "https://drive.google.com/uc?id=15CnSmXmjwAWuSCZmn66i6EXb4Mq86voc" `
      -O $vhdx

    Write-Host "[OK] Download completed"
}

Write-Host ""
Write-Host "[SUCCESS] DONE"
pause
