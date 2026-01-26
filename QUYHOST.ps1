Clear-Host
Write-Host "==============================="
Write-Host "   QUY HOST - FULL GPU-PV FLOW "
Write-Host "==============================="
Write-Host ""

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

# ===== STEP 1: ASK VM NAME =====
$vm = Read-Host "Nhap ten VM (VD: QUY1)"
if (-not $vm) {
    Write-Host "[ERROR] VM name khong duoc rong" -ForegroundColor Red
    pause
    exit
}

# ===== STEP 2: CHECK VM =====
try {
    Get-VM -Name $vm -ErrorAction Stop | Out-Null
    Write-Host "[OK] VM found: $vm"
} catch {
    Write-Host "[ERROR] VM not found: $vm" -ForegroundColor Red
    pause
    exit
}

# ===== STEP 3: SHUTDOWN VM =====
Write-Host ""
Write-Host "[STEP] Shutdown VM"
if ((Get-VM -Name $vm).State -ne "Off") {
    Stop-VM -Name $vm -Force
    while ((Get-VM -Name $vm).State -ne "Off") {
        Write-Host "[INFO] Waiting VM to power off..."
        Start-Sleep 2
    }
}
Write-Host "[OK] VM is OFF"

# ===== STEP 4: REMOVE OLD GPU-PV =====
if (Get-VMGpuPartitionAdapter -VMName $vm -ErrorAction SilentlyContinue) {
    Remove-VMGpuPartitionAdapter -VMName $vm
    Write-Host "[OK] Old GPU-PV removed"
}

# ===== STEP 5: ADD + CONFIG GPU-PV =====
Add-VMGpuPartitionAdapter -VMName $vm

Set-VMGpuPartitionAdapter -VMName $vm `
 -MinPartitionVRAM 80000000 `
 -MaxPartitionVRAM 100000000 `
 -OptimalPartitionVRAM 100000000 `
 -MinPartitionEncode 80000000 `
 -MaxPartitionEncode 100000000 `
 -OptimalPartitionEncode 100000000 `
 -MinPartitionDecode 80000000 `
 -MaxPartitionDecode 100000000 `
 -OptimalPartitionDecode 100000000 `
 -MinPartitionCompute 80000000 `
 -MaxPartitionCompute 100000000 `
 -OptimalPartitionCompute 100000000

Set-VM -VMName $vm -GuestControlledCacheTypes $true
Set-VM -VMName $vm -LowMemoryMappedIoSpace 1GB
Set-VM -VMName $vm -HighMemoryMappedIoSpace 32GB

Write-Host "[OK] GPU-PV configured"

# ===== STEP 6: START VM =====
Write-Host ""
Write-Host "[STEP] Starting VM"
Start-VM -Name $vm

while ((Get-VM -Name $vm).State -ne "Running") {
    Write-Host "[INFO] Waiting VM to boot..."
    Start-Sleep 2
}
Write-Host "[OK] VM is RUNNING"

# ===== WAIT VM READY =====
Write-Host "[INFO] Waiting 15s for Windows boot..."
Start-Sleep 15

# ===== STEP 7: ENABLE INTEGRATION =====
Get-VM -Name $vm | Get-VMIntegrationService |
Where-Object { -not($_.Enabled) } |
Enable-VMIntegrationService | Out-Null

# ===== STEP 8: COPY NVIDIA DRIVER =====
$systemPath = "C:\Windows\System32\"
$driverPath = "C:\Windows\System32\DriverStore\FileRepository\"

$localDriverFolder = ""
Get-ChildItem $driverPath -Recurse |
Where-Object { $_.PSIsContainer -and $_.Name -match "nv_dispi.inf_amd64_.*" } |
Sort-Object LastWriteTime -Descending |
Select-Object -First 1 |
ForEach-Object { $localDriverFolder = $_.Name }

Write-Host "[INFO] Using driver folder: $localDriverFolder"

Get-ChildItem ($driverPath + $localDriverFolder) -Recurse |
Where-Object { -not $_.PSIsContainer } |
ForEach-Object {
    $dst = $_.FullName -replace "^C\:\\Windows\\System32\\DriverStore\\", "C:\Temp\System32\HostDriverStore\"
    Copy-VMFile $vm $_.FullName $dst -Force -CreateFullPath -FileSource Host
}

Get-ChildItem $systemPath | Where-Object { $_.Name -like "NV*" } |
ForEach-Object {
    $dst = $_.FullName -replace "^C\:\\Windows\\System32\\", "C:\Temp\System32\"
    Copy-VMFile $vm $_.FullName $dst -Force -CreateFullPath -FileSource Host
}

Write-Host "[OK] Driver copied to C:\Temp"

# ===== STEP 9: OPEN FOLDER IN VM =====
Write-Host "[STEP] Opening C:\Temp"
Start-Process explorer.exe "C:\Temp"

Write-Host ""
Write-Host "==============================="
Write-Host "[SUCCESS] ALL DONE" -ForegroundColor Green
Write-Host "==============================="
pause
