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
Function Add-VMGpuPartitionAdapterFiles {
param(
    [string]$hostname = $ENV:COMPUTERNAME,
    [string]$TargetRoot = "C:\DRIVER_GPU_COPY",
    [string]$GPUName = "AUTO"
)

Write-Host "INFO   : Copying GPU driver files to $TargetRoot (HOST ONLY)"

# Detect GPU
if ($GPUName -eq "AUTO") {
    $PartitionableGPUList = Get-WmiObject -Class "Msvm_PartitionableGpu" -Namespace "ROOT\virtualization\v2"
    $DevicePathName = $PartitionableGPUList.Name | Select-Object -First 1
    $GPU = Get-PnpDevice | Where-Object {
        ($_.DeviceID -like "*$($DevicePathName.Substring(8,16))*") -and ($_.Status -eq "OK")
    } | Select-Object -First 1

    $GPUName = $GPU.FriendlyName
    $GPUServiceName = $GPU.Service
}
else {
    $GPU = Get-PnpDevice | Where-Object {
        ($_.Name -eq $GPUName) -and ($_.Status -eq "OK")
    } | Select-Object -First 1

    $GPUServiceName = $GPU.Service
}

Write-Host "INFO   : GPU detected: $GPUName"
Write-Host "INFO   : GPU service : $GPUServiceName"

# Prepare folders
New-Item -ItemType Directory -Path "$TargetRoot\Windows\System32\HostDriverStore" -Force | Out-Null
New-Item -ItemType Directory -Path "$TargetRoot\Windows\System32\drivers" -Force | Out-Null

# Copy service driver directory
$servicePath = (Get-WmiObject Win32_SystemDriver | Where-Object {$_.Name -eq $GPUServiceName}).Pathname
$ServiceDriverDir = $servicePath.Split('\')[0..5] -join('\')
$ServiceDriverDest = Join-Path $TargetRoot ($servicePath.Split('\')[1..5] -join('\'))
$ServiceDriverDest = $ServiceDriverDest.Replace("DriverStore","HostDriverStore")

if (!(Test-Path $ServiceDriverDest)) {
    Copy-Item -Path $ServiceDriverDir -Destination $ServiceDriverDest -Recurse
}

# Get signed drivers
$Drivers = Get-WmiObject Win32_PNPSignedDriver | Where-Object { $_.DeviceName -eq $GPUName }

foreach ($d in $Drivers) {

    $ModifiedDeviceID = $d.DeviceID -replace "\\", "\\"
    $Antecedent = "\\" + $hostname + "\ROOT\cimv2:Win32_PNPSignedDriver.DeviceID=""$ModifiedDeviceID"""

    $DriverFiles = Get-WmiObject Win32_PNPSignedDriverCIMDataFile |
        Where-Object { $_.Antecedent -eq $Antecedent }

    foreach ($i in $DriverFiles) {
        $path = $i.Dependent.Split("=")[1] -replace '\\\\','\'
        $path2 = $path.Substring(1,$path.Length-2)

        if ($path2 -like "c:\windows\system32\driverstore\*") {
            $DriverDir = $path2.Split('\')[0..5] -join('\')
            $DriverDest = Join-Path $TargetRoot ($path2.Split('\')[1..5] -join('\'))
            $DriverDest = $DriverDest.Replace("driverstore","HostDriverStore")

            if (!(Test-Path $DriverDest)) {
                Copy-Item -Path $DriverDir -Destination $DriverDest -Recurse
            }
        }
        else {
            $Dest = Join-Path $TargetRoot ($path2.Substring(3))
            $DestDir = Split-Path $Dest

            if (!(Test-Path $DestDir)) {
                New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
            }

            Copy-Item $path2 -Destination $Dest -Force
        }
    }
}

Write-Host "SUCCESS: GPU driver copied to $TargetRoot"
}

Write-Host "[SUCCESS] GPU driver copied to $TargetRoot"

Add-VMGpuPartitionAdapterFiles -GPUName "AUTO"

Start-Process explorer.exe "C:\DRIVER_GPU_COPY"


Write-Host ""
Write-Host "==============================="
Write-Host "[SUCCESS] ALL DONE" -ForegroundColor Green
Write-Host "==============================="
pause
