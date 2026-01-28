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
# 1. Enable insecure guest
New-Item HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation -Force | Out-Null
Set-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation AllowInsecureGuestAuth 1
# 3. Create user
net user liza 1 /add

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

$wsh2 = New-Object -ComObject WScript.Shell
$scShare = $wsh2.CreateShortcut((Join-Path $desktop "MAY_SHARE.lnk"))
$scShare.TargetPath = $share
$scShare.Save()

Write-Host "[OK] MAY_SHARE shortcut created"
Write-Host ""


Function RemoveShortcut {
param(
    [string]$ShortcutName = "MM2512.lnk"
)
	$DesktopPath = [Environment]::GetFolderPath("Desktop")
	$PublicDesktopPath = [Environment]::GetFolderPath("CommonDesktopDirectory")

	# Try to remove from the current user's desktop
	if (Test-Path "$DesktopPath\$ShortcutName") {
		Remove-Item "$DesktopPath\$ShortcutName" -Force
		Write-Host "Removed $ShortcutName from current user desktop."
	}

	# Try to remove from the public desktop
	if (Test-Path "$PublicDesktopPath\$ShortcutName") {
		Remove-Item "$PublicDesktopPath\$ShortcutName" -Force
		Write-Host "Removed $ShortcutName from public desktop."
	}
}

Function RenameShortcut {
param(
    [string]$oldName = "MM2512.lnk",
	[string]$newName = "MM2512.lnk"
)
	$desktopPath = [Environment]::GetFolderPath("Desktop")
	$PublicDesktopPath = [Environment]::GetFolderPath("CommonDesktopDirectory")

	$oldPath = Join-Path -Path $desktopPath -ChildPath $oldName
	$newPath = Join-Path -Path $desktopPath -ChildPath $newName
	
	$oldPathPublic = Join-Path -Path $PublicDesktopPath -ChildPath $oldName
	$newPathPublic = Join-Path -Path $PublicDesktopPath -ChildPath $newName
	
	
	if (Test-Path -Path $oldPath) {
		Rename-Item -Path $oldPath -NewName $newName
			Write-Host "Shortcut '$oldName' renamed to '$newName'."
	}
	
	if (Test-Path -Path $oldPathPublic) {
		Rename-Item -Path $oldPathPublic -NewName $newPathPublic
			Write-Host "Shortcut '$oldName' renamed to '$newName'."
	}
}
RemoveShortcut -ShortcutName "browse host.lnk"
RemoveShortcut -ShortcutName "soft.lnk"
RemoveShortcut -ShortcutName "ExileAgent.lnk"
RemoveShortcut -ShortcutName "Start TD.lnk"
RemoveShortcut -ShortcutName "limited.lnk"
RemoveShortcut -ShortcutName "poehelper.lnk"
RenameShortcut -oldName "memreduct - Run me once to enable.lnk" -newName "RAM-BOOST.lnk"
RemoveShortcut -ShortcutName "update TC HUD from host.cmd"
$desktopPath = 'HKCU:\Software\Microsoft\Windows\Shell\Bags\1\Desktop'

# 1075839520: Auto Arrange OFF and Align to Grid OFF
# 1075839521: Auto Arrange ON and Align to Grid OFF
# 1075839524: Auto Arrange OFF and Align to Grid ON
#1075839525
$autoArrangeOnValue = 1075839521
Set-ItemProperty -Path $desktopPath -Name 'FFlags' -Value $autoArrangeOnValue
Get-Process explorer | Stop-Process -Force
Start-Sleep 2
$autoArrangeOnValue = 1075839520
Set-ItemProperty -Path $desktopPath -Name 'FFlags' -Value $autoArrangeOnValue
Get-Process explorer | Stop-Process -Force

# Kill explorer
Stop-Process -Name explorer -Force

# Force solid color mode
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers" `
    -Name BackgroundType -Type DWord -Value 1

# Clear wallpaper path
Set-ItemProperty "HKCU:\Control Panel\Desktop" -Name WallPaper -Value ""

# Set background color = black
Set-ItemProperty "HKCU:\Control Panel\Colors" -Name Background -Value "0 0 0"

# Delete cached wallpaper
Remove-Item "$env:APPDATA\Microsoft\Windows\Themes\TranscodedWallpaper" -ErrorAction SilentlyContinue
Remove-Item "$env:APPDATA\Microsoft\Windows\Themes\CachedFiles" -Recurse -Force -ErrorAction SilentlyContinue

# Apply system parameters (QUAN TRỌNG)
rundll32.exe user32.dll,UpdatePerUserSystemParameters

# Restart explorer
Start-Process explorer
Restart-Computer -Force


