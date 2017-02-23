@REM uninstall_Updates - uninstall and hide unwanted Windows updates.

SETLOCAL

@REM Configuration
SET PLUGINNAME=uninstall_Updates
SET PLUGINVERSION=1.1
SET PLUGINDIR=%SCRIPTDIR%\%PLUGINNAME%

SET UPDTDISABLE=%PLUGINDIR%\UninstallAndHideUpdates.ps1
SET UPDATEDIR=%DATADIR%\%PLUGINNAME%
SET UPDATELISTS=%UPDATEDIR%\*.lst

@REM Dependencies
IF NOT "%APPNAME%"=="Ancile" (
	ECHO ERROR: %PLUGINNAME% is meant to be launched by Ancile, and will not run as a stand alone script.
	ECHO Press any key to exit ...
	PAUSE >nul 2>&1
	EXIT
)

@REM Header
ECHO [%DATE% %TIME%] BEGIN UNINSTALL WINDOWS UPDATES >> "%LOGFILE%"
ECHO * Uninstalling Windows Updates ... 
ECHO   This may take a long time. Please be patient.

@REM Main
IF "%UNINSTALLUPDATES%"=="N" (
	ECHO Skipping Uninstall of Windows Updates >> "%LOGFILE%"
	ECHO   Skipping Uninstall Windows Updates
) ELSE (
	@REM Collect Windows Update Information
	IF "%DEBUG%"=="Y" (
		ECHO Collecting debug information >> "%LOGFILE%"
		ECHO   Collecting debug information
		sc query wuauserv  >> "%LOGFILE%" 2>&1
		sc qc wuauserv >> "%LOGFILE%" 2>&1
		sc query bits >> "%LOGFILE%" 2>&1
		sc qc bits >> "%LOGFILE%" 2>&1
	)
	
	@REM Uninstall Windows updates.
	ECHO Uninstalling and Hiding Windows Updates: >> "%LOGFILE%"
	ECHO   Uninstalling Updates
	
	FOR /F "tokens=*" %%i IN ('DIR /B "%UPDATELISTS%" 2^>^> "%LOGFILE%"') DO (
		ECHO %UPDATEDIR%\%%i >> "%LOGFILE%" 2>&1
		IF "%DEBUG%"=="Y" (
			sc query wuauserv >> "%LOGFILE%" 2>&1
			sc query wuauserv 2>&1 | findstr /I RUNNING >nul 2>&1 && powershell -executionpolicy remotesigned -File "%UPDTDISABLE%" -KBFile "%UPDATEDIR%\%%i" >> "%LOGFILE%" 2>&1
		) ELSE (
			sc query wuauserv 2>&1 | findstr /I RUNNING >nul 2>&1 && powershell -executionpolicy remotesigned -File "%UPDTDISABLE%" -KBFile "%UPDATEDIR%\%%i" >nul 2>&1
		)
	)

	@REM Restart Windows Update services
	ECHO Restarting Windows Updates Service: >> "%LOGFILE%"
	ECHO   Restarting Windows Update
	
	IF "%DEBUG%"=="Y" (
		sc query wuauserv 2>&1 | findstr /I RUNNING >nul 2>&1 && net stop wuauserv >> "%LOGFILE%" 2>&1
		sc query bits 2>&1 | findstr /I RUNNING >nul 2>&1 && net stop bits >> "%LOGFILE%" 2>&1
		sc qc bits 2>&1 | findstr /I AUTO_START >nul 2>&1 && net start bits >> "%LOGFILE%" 2>&1
		sc qc wuauserv 2>&1 | findstr /I AUTO_START >nul 2>&1 && net start wuauserv >> "%LOGFILE%" 2>&1
	) ELSE (
		sc query wuauserv 2>&1 | findstr /I RUNNING >nul 2>&1 && net stop wuauserv >nul 2>&1
		sc query bits 2>&1 | findstr /I RUNNING >nul 2>&1 && net stop bits >nul 2>&1
		sc qc bits 2>&1 | findstr /I AUTO_START >nul 2>&1 && net start bits >nul 2>&1
		sc qc wuauserv 2>&1 | findstr /I AUTO_START >nul 2>&1 && net start wuauserv >nul 2>&1
	)
)

@REM Footer
ECHO [%DATE% %TIME%] END UNINSTALL WINDOWS UPDATES >> "%LOGFILE%"
ECHO   DONE

ENDLOCAL
