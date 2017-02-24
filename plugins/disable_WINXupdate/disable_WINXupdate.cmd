@REM Disable Windows 10 Forced Upgrade

SETLOCAL

@REM Configuration. 
SET PLUGINNAME=disable_WINXUpdate
SET PLUGINVERSION=1.2
SET PLUGINDIR=%SCRIPTDIR%\%PLUGINNAME%
SET TASKFILE=%DATADIR%\%PLUGINNAME%\disable_MSGWX.tasks.lst
SET WINXDIR=%SYSTEMDRIVE%\$windows.~bt

@REM Dependencies
IF NOT "%APPNAME%"=="Ancile" (
	ECHO ERROR: %PLUGINNAME% is meant to be launched by Ancile, and will not run as a stand alone script.
	ECHO Press any key to exit ...
	PAUSE >nul 2>&1
	EXIT
)

@REM Header
ECHO [%DATE% %TIME%] BEGIN DISABLE WINDOWS 10 FORCED UPGRADE >> "%LOGFILE%"
ECHO * Disabling Windows 10 Upgrade ... 

SETLOCAL EnableDelayedExpansion

@REM Main
IF "%DISABLEWINXUPDATE%"=="N" (
	ECHO Skipping Disable Windows 10 Upgrade >> "%LOGFILE%"
	ECHO   Skipping GWX Upgrade
) ELSE (
	@REM Make sure we're running on the correct OS version
	SET oscheck=0
	IF "%OSVERSION%"=="6.3" SET oscheck=1
	IF "%OSVERSION%"=="6.2" SET oscheck=1
	IF "%OSVERSION%"=="6.1" SET oscheck=1

	IF !oscheck! EQU 0 (
		ECHO %PLUGINNAME% %PLUGINVERSION% can only be run unders Windows 7, 8, or 8.1 >> "%LOGFILE%"
		ECHO   Skipping %PLUGINNAME%. OS not supported
	) ELSE (
		@REM Kill Windows 10 uprade processes
		ECHO Killing Get Windows 10 processes: >> "%LOGFILE%"
		ECHO   Stopping GWX process
		
		tasklist 2>&1 | findstr /I gwx.exe >> "%LOGFILE%" 2>&1 && taskkill /F /IM gwx.exe /T >> "%LOGFILE%" 2>&1
		tasklist 2>&1 | findstr /I gwxux.exe >> "%LOGFILE%" 2>&1 && taskkill /F /IM gwxux.exe /T >> "%LOGFILE%" 2>&1

		@REM Disable Windows 10 upgrade tasks
		ECHO Disabling Get Windows 10 Task: >> "%LOGFILE%"
		ECHO   Disabling GWX Task
		
		CALL modifytasks.cmd DISABLE "%TASKFILE%"
		
		@REM Disable Windows 10 upgrade
		ECHO Adding registry keys: >> "%LOGFILE%"
		ECHO   Disabling GWX Update
		
		SET rkey=HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\GWX
		IF "%DEBUG%"=="Y" ECHO Setting "!rkey!" >> "%LOGFILE%"
		reg ADD "!rkey!" /f /t reg_dword /v DisableGWX /d 1 >> "%LOGFILE%" 2>&1
		
		SET rkey=HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Windowsupdate
		IF "%DEBUG%"=="Y" ECHO Setting "!rkey!" >> "%LOGFILE%"
		reg ADD "!rkey!" /f /t reg_dword /v DisableOSUpgrade /d 1 >> "%LOGFILE%" 2>&1 

		@REM Disable the windows 10 download
		ECHO Locking Windows 10 download directory: >> "%LOGFILE%"
		ECHO   Disabling GWX Download
		
		IF EXIST "%WINXDIR%" (
			takeown /F "%WINXDIR%" /A /R >> "%LOGFILE%" 2>&1
			RMDIR /Q /S "%WINXDIR%" >> "%LOGFILE%" 2>&1
		)
		
		MKDIR "%WINXDIR%" >> "%LOGFILE%" 2>&1
		attrib +h "%WINXDIR%" >> "%LOGFILE%" 2>&1
		takeown /F "%WINXDIR%" /A /R >> "%LOGFILE%" 2>&1
		icacls "%WINXDIR%" /grant:r *S-1-5-32-544:F /T /C >> "%LOGFILE%" 2>&1
	)
)

SETLOCAL DisableDelayedExpansion

@REM Footer
ECHO [%DATE% %TIME%] END DISABLE WIN 10 FORCED UPGRADE >> "%LOGFILE%"
ECHO   DONE

ENDLOCAL
