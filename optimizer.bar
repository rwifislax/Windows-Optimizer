@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
REM Run cleanmgr /sageset:0 first to set up the cleaning preferences
REM Execute with admin privileges
REM modified for up to two drives

TITLE Optimizer Program by wifislax
echo [-] Scanning drives for errors...

echo [-] Scanning drive C...
Powershell.exe -Command "Repair-Volume -DriveLetter C -Verbose"

REM Identify more volumes (volume D:)

SET count=1
FOR /F "tokens=* USEBACKQ" %%F IN (`wmic logicaldisk get name`) DO (
  SET varia!count!=%%F
  SET /a count=!count!+1
)

REM ECHO !varia3!

IF "%varia3%"=="D:    " (
	echo [+] Drive D: found
	set drived=1
	echo [-] Scanning drive D...
	Powershell.exe -Command "Repair-Volume -DriveLetter D -Verbose"	
)

echo.
echo [-] Checking the integrity of the Operating System...
DISM /Online /Cleanup-Image /CheckHealth
echo.

echo. 
echo [-] Cleaning drives...
cleanmgr /sagerun:0
echo [+] Done.
echo.

echo [-] Analysing and Optimizing drives...
echo.
REM Identify disk drive type

SET count=1
FOR /F "tokens=* USEBACKQ" %%F IN (`powershell.exe -c "(get-physicaldisk).MediaType | Sort-Object -Property Number"`) DO (
  SET vari!count!=%%F
  SET /a count=!count!+1
)

REM ECHO !vari1!
REM ECHO !vari2!

IF "%vari1%"=="SSD" (
	echo [+] disk C: is SSD
	defrag C: /H /Optimize /U
) ELSE (
	echo [+] disk C: is HDD
	REM Identify fragmentation percentage
	SET count=1
	FOR /F "tokens=* USEBACKQ" %%F IN (`defrag C: /H /A`) DO (
  		SET var!count!=%%F
  		SET /a count=!count!+1
	)
	REM Print percentage fragmented
	echo(!var1!
	echo(!var8!
	echo(!var1! > C:\Admin\log.txt
	echo(!var8! >> C:\Admin\log.txt
	REM Get percentage from phrase
	for %%F in (!var8!) do set number1=%%~nxF
	REM echo(!number1!
	REM Calculate if it needs defragging
	IF NOT !number1!==0%% (
	 	echo [+] drive C needs defragging
	 	defrag C: /H /Defrag /U
	) ELSE (
	 	echo [+] drive C does not need defragging
	)
)
REM two true conditions if statement
echo.
IF "%vari2%"=="SSD" IF "%drived%"=="1" (
	echo [+] disk D: is SSD
	defrag C: /H /Optimize /U
) 
IF "%vari2%"=="HDD" IF "%drived%"=="1" (
	echo [+] disk D: is HDD
	SET count=1
	FOR /F "tokens=* USEBACKQ" %%F IN (`defrag D: /H /A`) DO (
		SET var!count!=%%F
  		SET /a count=!count!+1
	)
	REM Print percentage fragmented
	echo(!var1!
	echo(!var8!
	echo(!var1! > C:\Admin\log.txt
	echo(!var8! >> C:\Admin\log.txt
	REM Get number from drive percentage
	for %%F in (!var8!) do set number1=%%~nxF
	REM echo(!number1!
	REM Calculate if it needs defragging
	IF NOT !number1!==0%% (
	 	echo [+] drive D needs defragging
	 	defrag D: /H /Defrag /U
	) ELSE (
	 	echo [+] drive D does not need defragging
	)
)

echo [-] Finished
ENDLOCAL
pause
