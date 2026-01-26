Write-Host "==============================="
Write-Host " Enable Share LAN (VM LOCAL)   "
Write-Host "==============================="
Write-Host ""

# ===============================
# STEP 0: CHECK ADMIN
# ===============================
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

# ===============================
# STEP 1: ASK SHARE
# ===============================
$share = Read-Host "MM2512-Nhap UNC share (VD: \\192.168.88.10)"
if (-not $share.StartsWith("\\")) {
    Write-Host "MM2512-[ERROR] Share path phai bat dau bang \\\\" -ForegroundColor Red
    pause
    exit
}
Write-Host "MM2512-[INFO] Share path: $share"
Write-Host ""

# ===============================
# STEP 2: ENABLE INSECURE GUEST
# ===============================
Write-Host "MM2512-[STEP 2] Enable insecure guest logons"

New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation" -Force | Out-Null
Set-ItemProperty `
  -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation" `
  -Name "AllowInsecureGuestAuth" `
  -Type DWord `
  -Value 1

Write-Host "MM2512-[OK] Registry set"
Write-Host ""

# ===============================
# STEP 3: APPLY POLICY
# ===============================
Write-Host "MM2512-[STEP 3] Apply policy"
gpupdate /force
Write-Host ""

# ===============================
# STEP 4: RESTART SERVICE
# ===============================
Write-Host "MM2512-[STEP 4] Restart LanmanWorkstation"
Restart-Service LanmanWorkstation -Force
Write-Host "MM2512-[OK] Service restarted"
Write-Host ""

# ===============================
# STEP 5: OPEN SHARE
# ===============================
Write-Host "MM2512-[STEP 5] Open share path"
Start-Process explorer.exe $share
Write-Host "MM2512-[OK] Share opened"
Write-Host ""

# ===============================
# STEP 6: CREATE DRIVER SHORTCUT
# ===============================
Write-Host "MM2512-[STEP 6] Create DRIVER shortcuts"

$desktop = [Environment]::GetFolderPath("Desktop")
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

$shareDir = Join-Path $desktop "MAY_SHARE"
if (-not (Test-Path $shareDir)) {
    New-Item -ItemType Directory -Path $shareDir | Out-Null
}

$wsh2 = New-Object -ComObject WScript.Shell
$scc1 = $wsh2.CreateShortcut((Join-Path $shareDir "MAY_SHARE.lnk"))
$scc1.TargetPath = $share
$scc1.Save()


Write-Host "MM2512-[OK] Shortcuts created"
Write-Host ""

# ===============================
# STEP 7: AUTO LOGIN SETUP
# ===============================
# ===============================
# STEP 7: AUTO LOGIN (BLANK PASS USER)
# ===============================
Write-Host "MM2512-[STEP 7] Setup Blank-password Auto Login (Server 2022)"

# -------- SECURITY POLICY --------
secedit /export /cfg C:\secpol.cfg > $null

(Get-Content C:\secpol.cfg) `
 -replace "MinimumPasswordLength = \d+", "MinimumPasswordLength = 0" `
 -replace "PasswordComplexity = 1", "PasswordComplexity = 0" `
 | Set-Content C:\secpol.cfg

secedit /configure /db secedit.sdb /cfg C:\secpol.cfg /areas SECURITYPOLICY
Remove-Item C:\secpol.cfg -Force

# Disable Ctrl+Alt+Del
Set-ItemProperty `
 "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
 DisableCAD 1

# -------- USER 1: AUTO LOGIN (NO PASSWORD) --------
$AutoUser = "liza"

# tạo user nếu chưa tồn tại
if (-not (Get-LocalUser -Name $AutoUser -ErrorAction SilentlyContinue)) {
    net user $AutoUser /add
    net localgroup Users $AutoUser /add
    Write-Host "MM2512-[OK] Created auto-login user: liza (blank password)"
} else {
    Write-Host "MM2512-[INFO] User liza already exists"
}

# -------- AUTO LOGIN CONFIG --------
$reg = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

Set-ItemProperty $reg AutoAdminLogon "1"
Set-ItemProperty $reg DefaultUserName $AutoUser
Set-ItemProperty $reg DefaultDomainName $env:COMPUTERNAME

# ⚠️ KHÔNG set DefaultPassword (password rỗng)

# -------- DISABLE LOCK SCREEN --------
New-Item `
 "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" `
 -Force | Out-Null

Set-ItemProperty `
 "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" `
 NoLockScreen 1

Write-Host ""
Write-Host "MM2512-[SUCCESS] Auto-login blank user configured"
Write-Host " - Auto user : liza (NO PASSWORD)"
Write-Host "Rebooting VM now..."


Write-Host ""
Write-Host "MM2512-[SUCCESS] ALL CONFIG DONE"
Write-Host "MM2512-[INFO] Rebooting VM now..."

# ===============================
# STEP 8: REBOOT IMMEDIATELY
# ===============================
Restart-Computer -Force
