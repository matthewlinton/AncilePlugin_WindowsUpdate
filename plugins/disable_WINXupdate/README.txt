Disable Windows 10 Upgrade

ABOUT
This script will disable all known methods of forcing Windows 10 upgrade on
Windows 7 and 8 systems.

	
CONFIGURATION
The following options can be added to config.ini

	DISABLEWINXUPDATE (Boolean) - Enable or this plugin
		Y	- Enable (DEFAULT).
		N	- Disable.

DETAILS
* The following tasks are stopped
	- gwx.exe (Get Windows 10)
	- gwxux.exe (Get Windows 10 User Experience)
	
* The following Registry Keys are modified
	- HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\GWX
	- HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Windowsupdate

* The following folders are modified
	- %SYSTEMDRIVE%\$windows.~bt

NOTE
Disabling this plugin will not revert any changes made when this script was 
last run. DISABLEWINX only effects the running of the script.

VERSION
1.0		Initial Creation