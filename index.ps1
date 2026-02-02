Clear-Host
Write-Host "==============================="
Write-Host "  HYPER-V TWEAK MENU BY MM2512 "
Write-Host "==============================="
Write-Host ""
Write-Host "1. VM"
Write-Host "2. HOST"
Write-Host "3.DOWNLOAD FILE STEP1"
Write-Host "4.DOWNLOAD FILE STEP2"
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
     "3" {
        Write-Host "[INFO] Loading DOWNLOAD FILE STEP1..."
        iwr -UseBasicParsing https://raw.githubusercontent.com/IoT-VN/Hyper-V/refs/heads/main/ARIA2.ps1 | iex
    }
    "4" {
        Write-Host "[INFO] Loading DOWNLOAD FILE STEP2..."
        iwr -UseBasicParsing https://raw.githubusercontent.com/IoT-VN/Hyper-V/refs/heads/main/GG.ps1 | iex
    }
}

Write-Host ""
Write-Host "==============================="
Write-Host "            DONE               "

Write-Host "==============================="





