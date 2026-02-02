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
# STEP 1: INSTALL PYTHON 3.10
# ===============================
Write-Host "[STEP] Installing Python 3.10..."

$pythonUrl = "https://www.python.org/ftp/python/3.10.0/python-3.10.0-amd64.exe"
$installer = "$env:TEMP\python310.exe"

Invoke-WebRequest $pythonUrl -OutFile $installer

Start-Process $installer -Wait -ArgumentList `
    "/quiet InstallAllUsers=1 PrependPath=1 Include_pip=1"

Write-Host "[OK] Python installed"
Write-Host ""

# Reload PATH (machine + user)
$env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
            [Environment]::GetEnvironmentVariable("Path","User")

# ===============================
# STEP 2: VERIFY PYTHON & PIP
# ===============================
python --version
pip --version

# ===============================
# STEP 3: INSTALL gdown
# ===============================
Write-Host "[STEP] Installing gdown..."
pip install --upgrade gdown

Write-Host ""
Write-Host "[SUCCESS] Python + gdown ready"
pause
