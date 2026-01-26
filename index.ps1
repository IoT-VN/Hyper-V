Clear-Host
Write-Host "==============================="
Write-Host "  HYPER-V TWEAK MENU BY MM2512 "
Write-Host "==============================="
Write-Host ""
Write-Host "1. VM"
Write-Host "2. HOST"
Write-Host ""
$choice = Read-Host "Chon (1-2)"

switch ($choice) {
    "1" {
        Write-Host "[VM] Running QUYVM setup..."

        # ===============================
        # STEP 1: RUN QUYVM_SETUP.ps1
        # ===============================
        iwr -UseBasicParsing `
          https://raw.githubusercontent.com/IoT-VN/Hyper-V/refs/heads/main/QUYSETUP.ps1 `
          | iex

        # ===============================
        # STEP 2: DOWNLOAD QUYVM_USER.ps1
        # ===============================
        $userScript = "C:\QUYVM_USER.ps1"

        Write-Host "[VM] Downloading QUYVM_USER.ps1 -> $userScript"

        iwr -UseBasicParsing `
          https://raw.githubusercontent.com/IoT-VN/Hyper-V/refs/heads/main/QUYUSER.ps1 `
          -OutFile $userScript

        # ===============================
        # STEP 3: CREATE SCHEDULED TASK
        # ===============================
        Write-Host "[VM] Creating Scheduled Task for user liza"

        $action = New-ScheduledTaskAction `
          -Execute "powershell.exe" `
          -Argument "-ExecutionPolicy Bypass -File `"$userScript`""

        $trigger = New-ScheduledTaskTrigger -AtLogOn

        $principal = New-ScheduledTaskPrincipal `
          -UserId "liza" `
          -LogonType Interactive `
          -RunLevel Highest

        Register-ScheduledTask `
          -TaskName "QUYVM-UserInit" `
          -Action $action `
          -Trigger $trigger `
          -Principal $principal `
          -Force

        Write-Host ""
        Write-Host "[VM] Setup complete"
        Write-Host "[VM] User init will run at next logon (liza)"
        Write-Host "[VM] Rebooting now..."
        Restart-Computer -Force
    }
    "2" {
        Write-Host "[INFO] Loading QUYHOST.ps1..."
        iwr -UseBasicParsing https://raw.githubusercontent.com/IoT-VN/Hyper-V/refs/heads/main/QUYHOST.ps1 | iex
    }
    default {
        Write-Host "[ERROR] Lua chon khong hop le" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "==============================="
Write-Host "            DONE               "

Write-Host "==============================="
