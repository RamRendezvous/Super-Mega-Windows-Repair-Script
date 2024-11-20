# Super Mega Windows Repair Script (PowerShell Version)
# WARNING: Run as Administrator to unleash full power!

# Define paths
$logfile = "$PSScriptRoot\mega_repair_log.txt"
$backupdir = "$PSScriptRoot\backup"
$tempdir = "$PSScriptRoot\temp"

# Logging function
function Write-Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logfile -Value "$timestamp - $message"
}

Write-Log "Starting Super Mega Windows Repair Script..."

# STEP 1: CREATE BACKUPS
Write-Log "Creating critical backups before proceeding..."
New-Item -ItemType Directory -Force -Path $backupdir, $tempdir | Out-Null

# Backup Boot Configuration Data (BCD) and Registry
Write-Log "Backing up Boot Configuration Data (BCD)..."
bcdedit /export "$backupdir\BCD_Backup.bcd"

Write-Log "Backing up registry hives..."
reg.exe save HKLM\SYSTEM "$backupdir\SYSTEM_Backup.reg" /y
reg.exe save HKLM\SOFTWARE "$backupdir\SOFTWARE_Backup.reg" /y

# Create a System Restore Point
Write-Log "Creating a System Restore Point..."
Checkpoint-Computer -Description "MegaRepairScript Backup" -RestorePointType MODIFY_SETTINGS

# STEP 2: SYSTEM FILE AND IMAGE REPAIR
Write-Log "Repairing system files and Windows image..."
sfc /scannow | Out-String | Write-Log
dism /online /cleanup-image /scanhealth | Out-String | Write-Log
dism /online /cleanup-image /restorehealth | Out-String | Write-Log
dism /online /cleanup-image /startcomponentcleanup /resetbase | Out-String | Write-Log

# STEP 3: HARDWARE AND DRIVER VALIDATION
Write-Log "Validating and repairing hardware drivers..."
$drivers = pnputil /enum-devices /problem
if ($drivers) {
    foreach ($driver in $drivers) {
        Write-Log "Fixing driver issue for: $driver"
        pnputil /delete-driver $driver /uninstall /force | Out-String | Write-Log
        pnputil /add-driver $driver /install | Out-String | Write-Log
    }
}

# STEP 4: NETWORK FIXES
Write-Log "Resetting and optimizing network configurations..."
netsh winsock reset | Out-String | Write-Log
netsh int ip reset | Out-String | Write-Log
ipconfig /release | Out-String | Write-Log
ipconfig /renew | Out-String | Write-Log
ipconfig /flushdns | Out-String | Write-Log

# STEP 5: ADVANCED DISK CHECKS
Write-Log "Running CHKDSK on all drives..."
$drives = Get-PSDrive -PSProvider FileSystem
foreach ($drive in $drives) {
    Write-Log "Checking drive $($drive.Name)..."
    chkdsk "$($drive.Name):" /f /r /x | Out-String | Write-Log
}

# STEP 6: REMOVE TEMP FILES AND CACHE
Write-Log "Cleaning temporary files and cache..."
Remove-Item -Path $env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Recurse -Force -ErrorAction SilentlyContinue

# STEP 7: FIREWALL AND POLICY RESET
Write-Log "Resetting Windows Firewall and Group Policies..."
netsh advfirewall reset | Out-String | Write-Log
Remove-Item -Path "$env:windir\System32\GroupPolicy", "$env:windir\System32\GroupPolicyUsers" -Recurse -Force -ErrorAction SilentlyContinue
gpupdate /force | Out-String | Write-Log

# STEP 8: USER PROFILE REPAIRS
Write-Log "Fixing user profile issues..."
Remove-Item -Path "$env:SystemDrive\Users\TEMP" -Recurse -Force -ErrorAction SilentlyContinue
icacls "$env:SystemDrive\Users" /reset /t /c /q | Out-String | Write-Log

# STEP 9: OPTIMIZATION AND POWER TUNING
Write-Log "Optimizing system performance..."
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-String | Write-Log
powercfg /hibernate off | Out-String | Write-Log
Optimize-Volume -DriveLetter C -Defrag | Out-String | Write-Log

# STEP 10: SCHEDULED MAINTENANCE
Write-Log "Scheduling weekly automatic repairs..."
schtasks /create /tn "MegaRepairWeekly" /tr "$PSScriptRoot\SuperMegaRepair.ps1" /sc weekly /d SUN /st 02:00 /ru SYSTEM | Out-String | Write-Log

# STEP 11: REBUILD RECOVERY ENVIRONMENT
Write-Log "Rebuilding Windows Recovery Environment (WinRE)..."
reagentc /disable | Out-String | Write-Log
reagentc /enable | Out-String | Write-Log
reagentc /info | Out-String | Write-Log

# STEP 12: FINAL CHECKS AND REPORT
Write-Log "Running final checks and generating report..."
sfc /scannow | Out-String | Write-Log
perfmon /report | Out-String | Write-Log

Write-Log "Super Mega Windows Repair Script completed!"
