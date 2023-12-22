@echo off
TITLE Windows Optimizer 1.2 by wifislax 
SETLOCAL ENABLEDELAYEDEXPANSION
color 0a

REM banner
echo -------------------------
echo   Windows Optimizer 1.2
echo -------------------------
echo.

REM Go to informational 
set /p choice_information= "[?] Press enter to run optimizing tasks or type "n" to go to performance information?: "
IF "%choice_information%"=="n" (
	goto :information
)

echo.
echo ###### SELECTING PARAMETERS #######
echo.

REM Check if a more thorough OS Scan is needed
set /p choice_scan= "[?] Do you want to run a more thorough Windows OS Integrity Scan?(y/n): "
echo.

REM Check if cleanmgr /sageset:0 has been ran

echo [+] Check if cleaning parameters have been set...
for /f "tokens=4" %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches" /s /f "StateFlags0000"') do (
	set var=%%a
)

IF "%var%"=="0" (
	echo [-] Cleaning parameters have not been set.
	echo [+] Select cleaning choice.
	cleanmgr /sageset:0
) ELSE (
	echo [+] Cleaning parameters have been set.
	set /p choice= "[?] Do you want to modify them?(y/n): "
	IF /I "!choice!"=="y" (
		cleanmgr /sageset:0
	)
)
echo.

REM Check if we will obtimize all drives
echo [+] Drives found on the system:
powershell.exe -c "Get-PhysicalDisk | Sort-Object DeviceId | ForEach-Object {$physicalDisk = $_; $physicalDisk | Get-Disk | Get-Partition | Where-Object DriveLetter | Get-Volume | Select-Object DriveLetter, FileSystemLabel, @{n='MediaType';e={ $physicalDisk.MediaType }}}"
set /p choice_drives= "[?] Do you want to optimize all drives?(y/n): "
echo.

echo ###### RUNNING TASKS ########
echo.

echo [+] Checking the integrity of the Operating System...
DISM /Online /Cleanup-Image /CheckHealth
if "%choice_scan%"=="y" (
	echo [+] Running a superior OS Scan. This can take some time.
	sfc /scannow
)
echo.

SET count=0
FOR /F "skip=3 tokens=1-2" %%a IN ('powershell.exe -c "Get-PhysicalDisk | Sort-Object DeviceId | ForEach-Object {$physicalDisk = $_; $physicalDisk | Get-Disk | Get-Partition | Where-Object DriveLetter | Select-Object DriveLetter, @{n='MediaType';e={ $physicalDisk.MediaType }}}"') DO (
	REM SET disk!count!=%%a:
	set disk=%%a:

	REM repair disks
	echo [+] Scanning disk !disk! for errors...
	Powershell.exe -Command "Repair-Volume -DriveLetter %%a -Verbose"
	echo.
	
	REM Clean drive C
	IF "!disk!"=="C:" (
		echo [+] Cleaning drives...
		cleanmgr /sagerun:0
		echo [+] Done.
		echo.
	)
	

	echo [+] Analysing and Optimizing drive !disk!...
	echo.

  	REM SET disk!count!type=%%b

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
	 		echo [+] drive !disk! needs defragging
			defrag !disk! /H /Defrag /U
		) ELSE (
	 		echo [-] drive !disk! does not need defragging.
		)
	) ELSE (
		echo [-] Drive !disk! does not support optimization, likely a Thumb drive.
	)

	echo.

	IF "!count!"=="0" (
		REM set /p choice= "Optimize more drives?(Y/N): "
		IF /I "%choice_drives%"=="n" (
			goto end
		)
	)

	set /a count=!count!+1
)

:end
echo.
echo [-] Finished tasks.

:information
echo.
echo ######### PERFORMANCE INFORMATION ##########

REM Check CPU usage
echo [+] Check CPU usage...

for /f "skip=1 tokens=1" %%p in ('wmic cpu get loadpercentage') do (
	set cpu=%%p%%	
	goto :continue
)

:continue
echo [+] Current CPU percentage: %cpu%
echo.

echo [+] Programs using the most CPU time:
powershell.exe -c "Get-Process | Select ProcessName, CPU, Id | Sort-Object CPU -Descending | where {$_.CPU -gt 100.0}"

REM Check uptime.
echo [+] Checking Host uptime...
set count=1
for /f "skip=2 tokens=3" %%a in ('powershell.exe -c "(Get-Date) - [System.Management.ManagementDateTimeconverter]::ToDateTime((Get-WmiObject -Class Win32_OperatingSystem).Lastbootuptime)"') do (
	if !count!==4 (
		goto end
	)
	set var!count!=%%a
	set /a count=!count!+1
)

:end
echo [+] Host Uptime is: %var1% days, %var2% hours, %var3% minutes
if %var1% geq 7 (
	echo [*] Computer's uptime is greater than a week. It is recommended to reboot.
	set /p input= "[+] Reboot?(y/n): "
	if "!input!"=="y" (
		ENDLOCAL
		shutdown /r /t 3
	)
) else (
	echo [+] The uptime is optimal.
)

echo.
echo [+] Finished all tasks.

ENDLOCAL
pause
