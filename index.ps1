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
        Write-Host ""
        Write-Host "[INFO] Loading VM script (QUYVM.ps1)..."
        try {
            irm https://hyperv.mm2512.com/QUYVM.ps1 | iex
        } catch {
            Write-Host "[ERROR] Failed to load QUYVM.ps1" -ForegroundColor Red
            Write-Host $_
        }
    }
    "2" {
        Write-Host ""
        Write-Host "[INFO] Loading HOST script (QUYHOST.ps1)..."
        try {
            irm https://hyperv.mm2512.com/QUYHOST.ps1 | iex
        } catch {
            Write-Host "[ERROR] Failed to load QUYHOST.ps1" -ForegroundColor Red
            Write-Host $_
        }
    }
    default {
        Write-Host "[ERROR] Lua chon khong hop le" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "==============================="
Write-Host "            DONE               "
Write-Host "==============================="