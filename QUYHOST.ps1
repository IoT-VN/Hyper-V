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
$TargetRoot = "C:\DRIVER_GPU_COPY"
$hostname = $ENV:COMPUTERNAME

Write-Host "[INFO] Detecting GPU via PartitionableGpu..."

# ===== DETECT GPU =====
$PartitionableGPUList = Get-WmiObject -Class "Msvm_PartitionableGpu" -Namespace "ROOT\virtualization\v2"
$DevicePathName = $PartitionableGPUList.Name | Select-Object -First 1

$GPU = Get-PnpDevice | Where-Object {
    ($_.DeviceID -like "*$($DevicePathName.Substring(8,16))*") -and ($_.Status -eq "OK")
} | Select-Object -First 1

if (-not $GPU) {
    Write-Host "[ERROR] Cannot detect GPU" -ForegroundColor Red
    exit
}

$GPUName = $GPU.FriendlyName
$GPUServiceName = $GPU.Service

Write-Host "INFO : GPU detected : $GPUName"
Write-Host "INFO : GPU service  : $GPUServiceName"

# ===== PREPARE TARGET =====
if (!(Test-Path $TargetRoot)) {
    New-Item -ItemType Directory -Path $TargetRoot | Out-Null
}

# ===== FIND NVIDIA DRIVERSTORE FOLDER (FINAL, DCH SAFE) =====
$DriverStoreRoot = "C:\Windows\System32\DriverStore\FileRepository"

$InfFolderObj = Get-ChildItem $DriverStoreRoot -Directory |
Where-Object {
    Test-Path (Join-Path $_.FullName "nvlddmkm.sys")
} |
Sort-Object LastWriteTime -Descending |
Select-Object -First 1

if (-not $InfFolderObj) {
    Write-Host "[ERROR] NVIDIA DriverStore folder not found (nvlddmkm.sys)" -ForegroundColor Red
    exit
}

$InfFolder     = $InfFolderObj.FullName
$InfFolderName = $InfFolderObj.Name

Write-Host "[OK] NVIDIA DriverStore folder detected:"
Write-Host "     $InfFolderName"


# ===== COPY INF FOLDER =====
$DestInf = Join-Path $TargetRoot $InfFolderName
if (!(Test-Path $DestInf)) {
    Copy-Item -Path $InfFolder -Destination $DestInf -Recurse
}

# ===== COPY REQUIRED DLL (nvapi64.dll example) =====
# NOTE: lấy DLL từ DriverFiles cho đúng GPU, không hardcode
foreach ($d in $Drivers) {
    $ModifiedDeviceID = $d.DeviceID -replace "\\", "\\"
    $Antecedent = "\\" + $hostname + "\ROOT\cimv2:Win32_PNPSignedDriver.DeviceID=""$ModifiedDeviceID"""

    Get-WmiObject Win32_PNPSignedDriverCIMDataFile |
        Where-Object { $_.Antecedent -eq $Antecedent } |
        ForEach-Object {
            $path = $_.Dependent.Split("=")[1] -replace '\\\\','\'
            $path2 = $path.Substring(1,$path.Length-2)

            if ($path2 -match "nvapi64\.dll$") {
                Copy-Item $path2 -Destination $TargetRoot -Force
                Write-Host "[OK] Copied nvapi64.dll"
            }
        }
}

# ===== DONE =====
Write-Host ""
Write-Host "==============================="
Write-Host "[SUCCESS] GPU DRIVER READY" -ForegroundColor Green
Write-Host "==============================="
Write-Host "Path: $TargetRoot"

Start-Process explorer.exe $TargetRoot


Start-Process explorer.exe "C:\DRIVER_GPU_COPY"


Write-Host ""
Write-Host "==============================="
Write-Host "[SUCCESS] ALL DONE" -ForegroundColor Green
Write-Host "==============================="
pause

