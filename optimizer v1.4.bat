@echo off
TITLE Windows Optimizer v1.4 by wifislax 
SETLOCAL ENABLEDELAYEDEXPANSION

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [Alert] You are NOT running with Administrator privileges. Please run as Administrator.
    pause
    exit /b
)

:: banner
echo ==========================
echo = Windows Optimizer v1.4 =
echo ==========================
echo.

:: settings
echo ======= Select Functions =======
echo 1 - Disk Cleanup
echo 2 - Scan OS
echo 3 - Repair OS
echo 4 - Repair and Optimize disks
echo 5 - Performance info
echo 6 - Exit
echo.
echo Enter your choices separated by spaces (e.g. 1 2 3):

set /p choices="> "

:: Check if 4 is in the input
echo %choices% | findstr "\<4\>" >nul
if not errorlevel 1 (
	:: select drives to optimize
	echo [+] Drives found on the system:
	powershell.exe -c "Get-PhysicalDisk | Sort-Object deviceid | ForEach-Object {$drive = $_; $drive | Get-Disk | Get-Partition | where-object driveletter | Get-Volume | Select-Object DriveLetter, FileSystemLabel, @{n='MediaType';e={ $drive.MediaType }}}"
	set /p drives= "Enter drive letters to scan (e.g., C D E): "
)

for %%i in (%choices%) do (
    if "%%i"=="1" call :cleanup
    if "%%i"=="2" call :sfc
    if "%%i"=="3" call :dism
	if "%%i"=="4" call :chkdsk
	if "%%i"=="5" call :information
	if "%%i"=="6" goto end
)
goto end

:: open disk clean up
:cleanup
REM Disk Clean up
echo [+] Launching Disk Cleanup tool...
cleanmgr /d C:
goto :eof

:: system file check
:sfc
REM Scan OS
	echo [+] Scanning for any issues in Windows OS...
	sfc /scannow
	DISM /Online /Cleanup-Image /ScanHealth
goto :eof

:: Run DISM to repair OS
:dism
	echo [+] Repairing the component store...
	DISM /Online /Cleanup-Image /RestoreHealth
goto :eof

:: chkdsk and defrag/trim
:chkdsk
REM Scanning drives for errors and repairing if errors found
for %%i in (%drives%) do (
	set disk=%%i:

	REM repair disks
	echo.
	echo [+] Checking !disk! for errors
	echo.
	for /f "tokens=*" %%A in ('chkdsk !disk! /scan ^| findstr /C:"Windows has scanned the file system and found no problems."') do (
    	set FOUND=noerrors
	)

	if "!FOUND!"=="noerrors" (
    	echo [+] No errors found. No further action needed.
	) else (
    	echo [!] Errors found. Using chkdsk /f /r /x for repairs...
    	chkdsk %DRIVE% /f /r /x
	)

echo.
echo [*] Analysing and Optimizing !disk!

REM Run PowerShell command to get media type
FOR /F "skip=3 tokens=2" %%b IN ('powershell.exe -c "Get-PhysicalDisk | ForEach-Object { $physicalDisk = $_; Get-Disk -Number $physicalDisk.DeviceId | Get-Partition | Where-Object { $_.DriveLetter -eq '%%i' } | Select-Object DriveLetter, @{n='MediaType';e={ $physicalDisk.MediaType }}}"') DO (
	IF "%%b"=="SSD" (
		echo [+] disk !disk! is %%b
		defrag !disk! /H /ReTrim /U
	) ELSE IF "%%b"=="HDD" (
		echo [+] disk !disk! is %%b
		REM Get percentage from analysis
		FOR /F "tokens=5" %%c IN ('defrag !disk! /H /A ^| findstr "%%"') DO (
			SET percentage=%%c
		)
	
		echo [+] drive !disk! fragmentation is: !percentage!
		IF NOT "!percentage!"=="0%%" (
	 		echo [!] drive !disk! needs defragging
			defrag !disk! /H /Defrag /U
		) ELSE (
	 		echo [+] drive !disk! does not need defragging.
		)
	) ELSE (
		echo [!] Drive !disk! does not support optimization, it is likely a Thumb drive.
	)
	)
)
goto :eof

:: Performance info
:information
echo.
echo ===========================
echo = Performance Information =
echo ===========================
echo.

:: Check CPU usage
echo [+] Check CPU usage...

for /f "tokens=1" %%p in ('wmic cpu get loadpercentage ^| findstr /r [0-9]') do ( set cpu=%%p)

echo [+] Current CPU percentage: %cpu%%%
echo.

echo [+] Programs using the most CPU time:
powershell.exe -c "Get-Process | Select ProcessName, CPU, Id | Sort-Object CPU -Descending | where {$_.CPU -gt 100.0}"

:: Check uptime
echo [+] Checking Host uptime...
set count=1
for /f "skip=2 tokens=3" %%a in ('powershell.exe -c "(Get-Date) - [System.Management.ManagementDateTimeconverter]::ToDateTime((Get-WmiObject -Class Win32_OperatingSystem).Lastbootuptime)"') do (
	if not !count!==4 (
		set var!count!=%%a
	)
	set /a count=!count!+1
)

echo [+] Host Uptime is: %var1% days, %var2% hours, %var3% minutes
if %var1% geq 7 (
	echo [!] Computer's uptime is greater than a week. It is recommended to reboot.
	set /p input= "[+] Reboot?(y/n): "
	if "!input!"=="y" (
		ENDLOCAL
		shutdown /r /t 3
	)
) else (
	echo [+] The uptime is optimal.
)
goto :eof

:end
echo.
echo [+] Exiting

ENDLOCAL
pause