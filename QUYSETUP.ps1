# 1. Enable insecure guest
New-Item HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation -Force | Out-Null
Set-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation AllowInsecureGuestAuth 1

# 2. Security policy
secedit /export /cfg C:\secpol.cfg > $null
(Get-Content C:\secpol.cfg) `
 -replace "MinimumPasswordLength = \d+", "MinimumPasswordLength = 0" `
 -replace "PasswordComplexity = 1", "PasswordComplexity = 0" `
 | Set-Content C:\secpol.cfg
secedit /configure /db secedit.sdb /cfg C:\secpol.cfg /areas SECURITYPOLICY
Remove-Item C:\secpol.cfg -Force

# 3. Create auto-login user
if (-not (Get-LocalUser liza -ErrorAction SilentlyContinue)) {
    net user liza 1 /add
    net localgroup Users liza /add
}

# 4. Auto login registry
$reg = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty $reg AutoAdminLogon 1
Set-ItemProperty $reg DefaultUserName "liza"
Set-ItemProperty $reg DefaultPassword "1"
Set-ItemProperty $reg DefaultDomainName $env:COMPUTERNAME

# 5. Disable CAD + lock screen
Set-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System DisableCAD 1
New-Item HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization -Force | Out-Null
Set-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization NoLockScreen 1

Restart-Computer -Force
