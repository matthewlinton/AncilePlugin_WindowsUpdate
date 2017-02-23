@REM modify_WINUpdate - Modifying Windows Update Behavior

SETLOCAL

@REM Configuration.
SET PLUGINNAME=modify_WINUpdate
SET PLUGINVERSION=1.1
SET PLUGINDIR=%SCRIPTDIR%\%PLUGINNAME%

@REM Dependencies
IF NOT "%APPNAME%"=="Ancile" (
	ECHO ERROR: %PLUGINNAME% is meant to be launched by Ancile, and will not run as a stand alone script.
	ECHO Press any key to exit ...
	PAUSE >nul 2>&1
	EXIT
)

@REM Header
ECHO [%DATE% %TIME%] BEGIN MODIFY WINDOWS UPDATE >> "%LOGFILE%"
ECHO * Modifing Windows Update ...

SETLOCAL EnableDelayedExpansion

@REM Main
IF "%MODIFYWINUPDATE%"=="N" (
	ECHO Windows Update modification Skipped: >> "%LOGFILE%"
	ECHO   Skipping Windows Update modification
	
) ELSE (
	SET rkey=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update
	reg ADD "!rkey!" /f /t reg_dword /v enablefeaturedsoftware /d 0  >> "%LOGFILE%" 2>&1
	reg ADD "!rkey!" /f /t reg_dword /v includerecommendedupdates /d 0  >> "%LOGFILE%" 2>&1
	
	IF "%DISABLEWINUPDATE%"=="Y" (
		@REM Completely disable Windows Update
		ECHO Disabling Automatic Updates >> "%LOGFILE%"
		ECHO   Disabling Automatic Updates
		
		reg ADD "!rkey!" /f /t reg_dword /v AUOptions /d 1 >> "%LOGFILE%" 2>&1
		sc config wuauserv start= disabled >> "%LOGFILE%" 2>&1
	) ELSE (
		@REM Switch Windows update to check for updates. DO NOT download. DO NOT Install.
		ECHO Modifying Automatic Updates >> "%LOGFILE%"
		ECHO   Modifying Automatic Updates
		
		reg ADD "!rkey!" /f /t reg_dword /v AUOptions /d 2 >> "%LOGFILE%" 2>&1
		sc config wuauserv start= delayed-auto >> "%LOGFILE%" 2>&1
	)
	
	@REM Restart Windows Update services
	ECHO Restarting Windows Updates Service: >> "%LOGFILE%"
	ECHO   Restarting Windows Update
	
	sc query wuauserv 2>&1 | findstr /I RUNNING >nul 2>&1 && net stop wuauserv >> "%LOGFILE%" 2>&1
	sc query bits 2>&1 | findstr /I RUNNING >nul 2>&1 && net stop bits >> "%LOGFILE%" 2>&1
	sc qc bits 2>&1 | findstr /I AUTO_START >nul 2>&1 && net start bits >> "%LOGFILE%" 2>&1
	sc qc wuauserv 2>&1 | findstr /I AUTO_START >nul 2>&1 && net start wuauserv >> "%LOGFILE%" 2>&1
)

SETLOCAL DisableDelayedExpansion

@REM Footer
ECHO [%DATE% %TIME%] END MODIFY WINDOWS UPDATE >> "%LOGFILE%"
ECHO   DONE

ENDLOCAL
