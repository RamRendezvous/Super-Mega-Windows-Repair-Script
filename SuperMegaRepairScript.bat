
@echo off
:: Super Mega Repair Script - The Ultimate Windows Repair Toolkit
:: WARNING: Run as Administrator to unleash full power!
:: Detailed log output saved for every action.

set logfile=%~dp0mega_repair_log.txt
set backupdir=%~dp0backup
set tempdir=%~dp0temp

echo Starting Super Mega Repair Script... > "%logfile%"
echo =========================================== >> "%logfile%"

:: STEP 1: CREATE BACKUPS
echo Creating critical backups before proceeding... >> "%logfile%"
mkdir "%backupdir%" >> "%logfile%"
mkdir "%tempdir%" >> "%logfile%"

:: Backup Boot Configuration Data (BCD) and Registry
bcdedit /export "%backupdir%\BCD_Backup.bcd" >> "%logfile%"
reg save HKLM\SYSTEM "%backupdir%\SYSTEM_Backup.reg" /y >> "%logfile%"
reg save HKLM\SOFTWARE "%backupdir%\SOFTWARE_Backup.reg" /y >> "%logfile%"

:: System Restore Point (if available)
powershell.exe -Command "Checkpoint-Computer -Description 'MegaRepairScript Backup' -RestorePointType MODIFY_SETTINGS" >> "%logfile%"

:: STEP 2: SYSTEM FILE AND IMAGE REPAIR
echo Repairing system files and Windows image... >> "%logfile%"
sfc /scannow >> "%logfile%"
dism /online /cleanup-image /scanhealth >> "%logfile%"
dism /online /cleanup-image /restorehealth >> "%logfile%"
dism /online /cleanup-image /startcomponentcleanup /resetbase >> "%logfile%"

:: STEP 3: HARDWARE AND DRIVER VALIDATION
echo Validating and repairing hardware drivers... >> "%logfile%"
pnputil /enum-devices /problem >> "%logfile%"
for /f "tokens=2 delims=: " %%A in ('pnputil /enum-devices /problem ^| find "Device Instance ID"') do (
    echo Fixing driver issue for: %%A >> "%logfile%"
    pnputil /delete-driver %%A /uninstall /force >> "%logfile%"
    pnputil /add-driver %%A /install >> "%logfile%"
)

:: STEP 4: NETWORK FIXES
echo Resetting and optimizing network configurations... >> "%logfile%"
netsh winsock reset >> "%logfile%"
netsh int ip reset >> "%logfile%"
ipconfig /release >> "%logfile%"
ipconfig /renew >> "%logfile%"
ipconfig /flushdns >> "%logfile%"

:: STEP 5: ADVANCED DISK CHECKS
echo Running CHKDSK on all drives... >> "%logfile%"
for %%d in (C: D: E:) do (
    echo Checking drive %%d... >> "%logfile%"
    chkdsk %%d /f /r /x >> "%logfile%"
)

:: STEP 6: REMOVE TEMP FILES AND CACHE
echo Cleaning temporary files and cache... >> "%logfile%"
del /s /q %temp%\*.* >> "%logfile%"
rd /s /q %temp% >> "%logfile%"
del /q /f %windir%\Prefetch\*.* >> "%logfile%"
del /s /f /q "%localappdata%\Microsoft\Windows\Explorer\thumbcache_*.db" >> "%logfile%"

:: STEP 7: FIREWALL AND POLICY RESET
echo Resetting Windows Firewall and Group Policies... >> "%logfile%"
netsh advfirewall reset >> "%logfile%"
netsh advfirewall set allprofiles state on >> "%logfile%"
rd /s /q "%windir%\System32\GroupPolicy" >> "%logfile%"
rd /s /q "%windir%\System32\GroupPolicyUsers" >> "%logfile%"
gpupdate /force >> "%logfile%"

:: STEP 8: USER PROFILE REPAIRS
echo Fixing user profile issues... >> "%logfile%"
if exist "%SystemDrive%\Users\TEMP" rd /s /q "%SystemDrive%\Users\TEMP" >> "%logfile%"
icacls "%SystemDrive%\Users" /reset /t /c /q >> "%logfile%"

:: STEP 9: OPTIMIZATION AND POWER TUNING
echo Optimizing system performance... >> "%logfile%"
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >> "%logfile%"
powercfg /hibernate off >> "%logfile%"
defrag C: /O /V >> "%logfile%"

:: STEP 10: SCHEDULED MAINTENANCE
echo Scheduling weekly automatic repairs... >> "%logfile%"
schtasks /create /tn "MegaRepairWeekly" /tr "%~dp0mega_repair.bat" /sc weekly /d SUN /st 02:00 /ru SYSTEM >> "%logfile%"

:: STEP 11: REBUILD RECOVERY ENVIRONMENT
echo Rebuilding Windows Recovery Environment (WinRE)... >> "%logfile%"
reagentc /disable >> "%logfile%"
reagentc /enable >> "%logfile%"
reagentc /info >> "%logfile%"

:: STEP 12: FINAL CHECKS AND REPORT
echo Running final checks and generating report... >> "%logfile%"
sfc /scannow >> "%logfile%"
perfmon /report >> "%logfile%"

:: COMPLETION
echo =========================================== >> "%logfile%"
echo Super Mega Repair Script completed! Check %logfile% for detailed logs. >> "%logfile%"
pause
exit
