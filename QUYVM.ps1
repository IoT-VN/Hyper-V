Write-Host "==============================="
Write-Host " QUYVM USER INIT (LIZA)        "
Write-Host "==============================="
Write-Host ""

# ===============================
# STEP 1: ASK SHARE
# ===============================
$share = Read-Host "MM2512 - Nhap UNC share (VD: \\192.168.88.10)"

if (-not $share.StartsWith("\\")) {
    Write-Host "[ERROR] Share path phai bat dau bang \\\\" -ForegroundColor Red
    exit
}

Write-Host "[INFO] Share path: $share"
Write-Host ""

# ===============================
# STEP 2: OPEN SHARE
# ===============================
Start-Process explorer.exe $share
Write-Host "[OK] Share opened"
Write-Host ""

# ===============================
# STEP 3: CREATE DRIVER SHORTCUT
# ===============================
Write-Host "[STEP] Create DRIVER shortcuts"

$desktop = [Environment]::GetFolderPath("Desktop")

# DRIVER folder
$driverDir = Join-Path $desktop "DRIVER"
if (-not (Test-Path $driverDir)) {
    New-Item -ItemType Directory -Path $driverDir | Out-Null
}

$wsh = New-Object -ComObject WScript.Shell

$sc1 = $wsh.CreateShortcut((Join-Path $driverDir "FileRepository.lnk"))
$sc1.TargetPath = "C:\Windows\System32\DriverStore\FileRepository"
$sc1.Save()

$sc2 = $wsh.CreateShortcut((Join-Path $driverDir "System32.lnk"))
$sc2.TargetPath = "C:\Windows\System32"
$sc2.Save()

Write-Host "[OK] DRIVER shortcuts created"
Write-Host ""

# ===============================
# STEP 4: CREATE MAY_SHARE SHORTCUT
# ===============================
Write-Host "[STEP] Create MAY_SHARE shortcut"

$shareDir = Join-Path $desktop "MAY_SHARE"
if (-not (Test-Path $shareDir)) {
    New-Item -ItemType Directory -Path $shareDir | Out-Null
}

$scShare = $wsh.CreateShortcut((Join-Path $shareDir "MAY_SHARE.lnk"))
$scShare.TargetPath = $share
$scShare.Save()

Write-Host "[OK] MAY_SHARE shortcut created"
Write-Host ""

# ===============================
# STEP 5: CLEANUP SCHEDULED TASK
# ===============================
Write-Host "[STEP] Cleanup Scheduled Task"

try {
    Unregister-ScheduledTask `
      -TaskName "QUYVM-UserInit" `
      -Confirm:$false
    Write-Host "[OK] Scheduled Task removed"
} catch {
    Write-Host "[WARN] Scheduled Task not found"
}

Write-Host ""
Write-Host "==============================="
Write-Host "[SUCCESS] USER INIT DONE"
Write-Host "==============================="
