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
# STEP 1: INSTALL PYTHON 3.10 (USER MODE)
# ===============================
Write-Host "[STEP] Installing Python 3.10 (per-user)..."

$pythonUrl = "https://www.python.org/ftp/python/3.10.0/python-3.10.0-amd64.exe"
$installer = "$env:TEMP\python310.exe"

Invoke-WebRequest $pythonUrl -OutFile $installer

Start-Process $installer -Wait -ArgumentList `
    "/quiet InstallAllUsers=0 PrependPath=0 Include_pip=1"

Write-Host "[OK] Python installed (user scope)"
Write-Host ""

# ===============================
# STEP 2: DETECT PYTHON PATH (AUTO)
# ===============================
$py = "$env:LOCALAPPDATA\Programs\Python\Python310\python.exe"

if (Test-Path $py) {
    Write-Host "[OK] Python binary found:"
    Write-Host "     $py"
} else {
    Write-Host "[ERROR] Python NOT found at user path!" -ForegroundColor Red
    pause
    exit
}

# ===============================
# STEP 3: VERIFY PYTHON (NO PATH)
# ===============================
& $py --version

# ===============================
# STEP 4: INSTALL pip + gdown (SAFE WAY)
# ===============================
Write-Host "[STEP] Installing pip & gdown..."

& $py -m ensurepip --upgrade
& $py -m pip install --upgrade pip
& $py -m pip install --upgrade gdown

Write-Host ""
Write-Host "[SUCCESS] Python + gdown ready (user-safe)"

$winDir = "C:\WIN"

if (Test-Path $winDir) {
    Write-Host "[INFO] C:\WIN exists, cleaning contents..."
    Get-ChildItem $winDir -Force | Remove-Item -Recurse -Force
} else {
    Write-Host "[INFO] C:\WIN not found, creating..."
    New-Item -ItemType Directory -Path $winDir | Out-Null
}

Write-Host "[OK] C:\WIN is ready"


& "$env:LOCALAPPDATA\Programs\Python\Python310\python.exe" -m gdown `
  "https://drive.google.com/uc?export=download&id=15CnSmXmjwAWuSCZmn66i6EXb4Mq86voc" `
  -O C:\WIN\QUY.vhdx

pause


