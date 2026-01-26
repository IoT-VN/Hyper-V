Write-Host "==============================="
Write-Host " Enable Share LAN (VM LOCAL)   "
Write-Host "==============================="
Write-Host ""

# STEP 0: Check admin
Write-Host "[STEP 0] Check Administrator rights"
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] Please run PowerShell as Administrator" -ForegroundColor Red
    pause
    exit
}
Write-Host "MM2512-[OK] Running as Administrator"

Write-Host ""

# STEP 1: Ask user for share path
$share = Read-Host "MM2512-Nhap UNC share (VD: \\192.168.88.10)"

if (-not $share.StartsWith("\\")) {
    Write-Host "MM2512-[ERROR] Share path phai bat dau bang \\\\" -ForegroundColor Red
    pause
    exit
}

Write-Host "MM2512-[INFO] Share path: $share"

Write-Host ""
Write-Host "MM2512-[STEP 2] Enable insecure guest logons (Lanman Workstation)"

try {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation" -Force | Out-Null
    Set-ItemProperty `
      -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation" `
      -Name "AllowInsecureGuestAuth" `
      -Type DWord `
      -Value 1

    Write-Host "MM2512-[OK] Registry set"
} catch {
    Write-Host "MM2512-[ERROR] Failed to set registry" -ForegroundColor Red
    Write-Host $_
    pause
    exit
}

Write-Host ""
Write-Host "MM2512-[STEP 3] Apply policy"
gpupdate /force

Write-Host ""
Write-Host "MM2512-[STEP 4] Restart LanmanWorkstation service"
try {
    Restart-Service LanmanWorkstation -Force
    Write-Host "MM2512-[OK] Service restarted"
} catch {
    Write-Host "MM2512-[ERROR] Failed to restart service" -ForegroundColor Red
    Write-Host $_
    pause
    exit
}

Write-Host ""
Write-Host "MM2512-[STEP 5] Open share path"
try {
    Start-Process explorer.exe $share
    Write-Host "MM2512-[OK] Share opened: $share"
} catch {
    Write-Host "MM2512-[ERROR] Failed to open share" -ForegroundColor Red
    Write-Host $_
    pause
    exit
}

Write-Host ""
Write-Host "MM2512-[STEP 6] Create DRIVER folder + shortcuts on Desktop"

try {
    $desktop = [Environment]::GetFolderPath("Desktop")
    $driverDir = Join-Path $desktop "DRIVER"

    if (-not (Test-Path $driverDir)) {
        New-Item -ItemType Directory -Path $driverDir | Out-Null
        Write-Host "MM2512-[OK] Created folder: $driverDir"
    } else {
        Write-Host "MM2512-[INFO] Folder DRIVER already exists"
    }

    $wsh = New-Object -ComObject WScript.Shell

    # Shortcut 1: DriverStore\FileRepository
    $sc1 = $wsh.CreateShortcut((Join-Path $driverDir "FileRepository.lnk"))
    $sc1.TargetPath = "C:\Windows\System32\DriverStore\FileRepository"
    $sc1.WorkingDirectory = "C:\Windows\System32\DriverStore"
    $sc1.Save()

    # Shortcut 2: System32
    $sc2 = $wsh.CreateShortcut((Join-Path $driverDir "System32.lnk"))
    $sc2.TargetPath = "C:\Windows\System32"
    $sc2.WorkingDirectory = "C:\Windows"
    $sc2.Save()

    Write-Host "MM2512-[OK] Shortcuts created in DRIVER folder"
} catch {
    Write-Host "MM2512-[ERROR] Failed to create shortcuts" -ForegroundColor Red
    Write-Host $_
    pause
    exit
}

Write-Host ""
Write-Host "==============================="
Write-Host "MM2512-[SUCCESS] DONE" -ForegroundColor Green
Write-Host "==============================="
pause
