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
Write-Host "[OK] Install aria2"
New-Item -ItemType Directory -Path "C:\Tools\aria2" -Force | Out-Null
$zip = "C:\Tools\aria2\aria2.zip"
Invoke-WebRequest `
  -Uri "https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip" `
  -OutFile $zip
Expand-Archive -Path $zip -DestinationPath "C:\Tools\aria2" -Force
$ariaPath = "C:\Tools\aria2\aria2-1.37.0-win-64bit-build1"
[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path","Machine") + ";$ariaPath", "Machine")
Write-Host "aria2 installed. Close & reopen PowerShell to use aria2c"
exit
