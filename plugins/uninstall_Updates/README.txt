Uninstall Updates

ABOUT
Uninstall the Windows updates listed in the Uninstall Updates data directory.

	
CONFIGURATION
The following options can be added to config.ini

	UNINSTALLUPDATES (Boolean) - Enable or disable the uninstalling and hiding of updates
		Y	- Enable Unistall Updates(DEFAULT).
		N	- Disable Uninstall Updates.

A complete list of updates that will be uninstalled can be found in the Uninstall 
Updates data directory located in "<ancile>\data\uninstall_updates\"


DETAILS
* This plugin uninstalls specific Windows updates listed in the data directory.


NOTE
Disabling this script will not re-install or unhide updates. If you want hidden
updates installed, you will have to manually unhide and install them.


VERSION
1.0		Initial Creation