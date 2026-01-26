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
        Write-Host "[INFO] Loading QUYVM.ps1..."
        iwr -UseBasicParsing https://raw.githubusercontent.com/IoT-VN/Hyper-V/refs/heads/main/QUYVM.ps1 | iex
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