# ===== STEP 0: ADMIN CHECK =====
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] Please run PowerShell as Administrator" -ForegroundColor Red
    pause
    exit
}
Write-Host "[OK] Running as Administrator"
Write-Host ""
Write-Host "[OK] Install python"
# Download the latest version of Python from the official website
$pythonUrl = "https://www.python.org/ftp/python/3.10.0/python-3.10.0-amd64.exe"
$pythonInstaller = "$($env:TEMP)\python.exe"
Invoke-WebRequest -Uri $pythonUrl -OutFile $pythonInstaller

# Install Python with default settings
Start-Process -FilePath $pythonInstaller -ArgumentList "/quiet" -Wait

# Add Python to the PATH environment variable
$pythonPath = Join-Path $env:ProgramFiles "Python310"
[System.Environment]::SetEnvironmentVariable("Path", "$($env:Path);$pythonPath", "User")

# Verify the installation
python --version
pip install --upgrade gdown
pause



