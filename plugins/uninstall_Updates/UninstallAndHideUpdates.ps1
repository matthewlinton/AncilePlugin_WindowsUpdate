<#
http://www.mcbsys.com/blog/2015/11/uninstall-and-hide-windows-updates/
.Synopsis
  Check whether an update is installed and if so, uninstall it.
  Check whether the same update is hidden and if not, hide it.
  Note that the check for pending updates can take several minutes.
 
  Copyright (c) 2015 by MCB Systems. All rights reserved.
  Free for personal or commercial use.  May not be sold.
  No warranties.  Use at your own risk.
 
.Notes
    Name:       MCB.AutoUpdate.UninstallAndHideUpdates.ps1
    Author:     Mark Berry, MCB Systems
    Created:    10/11/2015
    Last Edit:  09/14/2016
 
    Adapted from:
    http://techibee.com/powershell/powershell-uninstall-windows-hotfixesupdates/1084
    http://superuser.com/a/922921/171670
 
    Changes:
	09/14/2016 Script now ignores commented (lines starting with "#") and blank lines in files passed to it
	09/09/2016 "IsNullOrWhitespace" is not part of PS v2
	08/12/2016 Modified script to take a file as an argument
			   Added hidden=0 to search results.
    10/12/2015 Handle multiple updates in one execution.
#>
 
param(
  # This parameter takes an array of KB Numbers.  Simply add the numbers
  # separated by commas but no spaces, e.g. 2952664,2976978,3035583.
  [Parameter(Mandatory = $false,
                    #Position = 0,
                    ValueFromPipelineByPropertyName = $true)]
  [String[]]$KBNumbers="",
 
  # This parameter takes a file name (and path) that contain a list of
  # KB numbers. Each line in the file should start with the KB number followed
  # by a newline or a whitespace character. 
  [Parameter(Mandatory = $false,
                    #Position = 0,
                    ValueFromPipelineByPropertyName = $true)]
  [String[]]$KBFile="",
  
  # The following $LogFile parameter is required by LogigNow Remote Management
  # and can be omitted when running the script directly.
  [Parameter(Mandatory = $false,
                    #Position = 1,
                    ValueFromPipelineByPropertyName = $true)]
  [String]$LogFile=""
)
 
[Boolean]$ErrFound = $false
$ComputerName = $env:COMPUTERNAME

if ($KBFile){
	If (Test-Path $KBFile){
		$KBArray = Get-Content "$KBFile"
		foreach ($line in $KBArray | Where { $_ -notmatch '^#.*' -and $_ -notmatch '^\s*$' } ) {
			$fields = $line -split "\s+"
			if (!$KBNumbers) {
				$KBNumbers = $fields[0]
			} else {
				$KBNumbers = $KBNumbers + $fields[0]
			}
		}
	} else {
		"Parameter error:  '$KBFile' not found or is not accessable."
		""
		"Script execution failed"
		$ExitCode = 1001 # Cause script to report failure in GFI dashboard
		""
		"Local Machine Time:  " + (Get-Date -Format G)
		"Exit Code: " + $ExitCode
		Exit $ExitCode
	}
}
 
Foreach ($KBNumber in $KBNumbers) {
  try {
    0 + $KBNumber | Out-Null
  }
  catch{
    "Parameter error:  '$KBNumber' is not allowed. Specify one or more numeric KBNumbers separated by commas but no spaces. Do not precede numbers with 'KB'."
    ""
    "Script execution failed"
    $ExitCode = 1001 # Cause script to report failure in GFI dashboard
    ""
    "Local Machine Time:  " + (Get-Date -Format G)
    "Exit Code: " + $ExitCode
    Exit $ExitCode
  }
}
 
"Computer Name: " + $ComputerName
""
"-------------------------------------------------------------------------------"
"Step 1:  Uninstall update(s)"
"-------------------------------------------------------------------------------"
 
#---------------------------------------------------------------------------------
# Uninstall the update
# Adapted from http://techibee.com/powershell/powershell-uninstall-windows-hotfixesupdates/1084
#---------------------------------------------------------------------------------
# Note that the list returned by wmic includes the "KB" prefix but wusa wants the number only
 
$hotfixes = Get-WmiObject -ComputerName $ComputerName -Class Win32_QuickFixEngineering | select hotfixid            
 
Foreach ($KBNumber in $KBNumbers) {
  "Checking whether update $KBNumber needs to be uninstalled"
  $KBID = "KB"+$KBNumber
  if($hotfixes -match $KBID) {
      Write-host "Found update $KBNumber. Uninstalling."
      $UninstallString = "cmd.exe /c wusa.exe /uninstall /KB:$KBNumber /quiet /norestart"
      "Executing '($UninstallString)'"
      ([WMICLASS]"\\$ComputerName\ROOT\CIMV2:win32_process").Create($UninstallString) | out-null            
 
      while (@(Get-Process wusa -computername $ComputerName -ErrorAction SilentlyContinue).Count -ne 0) {
          Start-Sleep 3
          Write-Host "Waiting for update removal to finish ..."
      }
    Write-Host "Completed the uninstallation of update $KBNumber"
  }
  else {            
    Write-Host "Update $KBNumber not installed so no uninstall needed"
  }            
  "-----------"
} # Foreach $KBNumber
#---------------------------------------------------------------------------------
# Hide (block) the update
# Adapted from http://superuser.com/a/922921/171670.
#---------------------------------------------------------------------------------
""
"-------------------------------------------------------------------------------"
"Step 2:  Hide update(s)"
"-------------------------------------------------------------------------------"
"Searching for updates with IsInstalled=0 and IsHidden=0, including superseded updates"
""
 
try {
  #Get all pending updates in $SearchResult.
  $UpdateSession = New-Object -ComObject Microsoft.Update.Session
  $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
  # If the update has been re-released, it may supersede a previous update.  
  # I had a case where it kept re-showing the new update after hiding it.
  # Including and (re-)hiding superseded updates will hopefully force
  # all updates related to this KBNumber to be hidden.
  $UpdateSearcher.IncludePotentiallySupersededUpdates = $true
  # Available search criteria:  https://msdn.microsoft.com/en-us/library/windows/desktop/aa386526%28v=vs.85%29.aspx
  $SearchResult = $UpdateSearcher.Search("IsInstalled=0 and IsHidden=0")
   
  Foreach ($KBNumber in $KBNumbers) {
    "Checking whether update $KBNumber needs to be hidden"
    [Boolean]$KBListed = $false
    Foreach ($Update in $SearchResult.updates) {
      Foreach ($KBArticleID in $Update.KBArticleIDs) {
        # Next line is for debugging
        # Write-Host "$KBArticleID, $($Update.IsHidden), $($Update.title)"
        if ($KBArticleID -eq $KBNumber) {
          $KBListed = $true
          if ($Update.IsHidden -eq $false) {
            Write-Host "Hiding update $KBNumber (UpdateID $($Update.Identity.UpdateID), deployed $($Update.LastDeploymentChangeTime.ToString('MM/dd/yyyy')))"
             $Update.IsHidden = $true     
          } else {
            Write-Host "Update $KBNumber (UpdateID $($Update.Identity.UpdateID), deployed $($Update.LastDeploymentChangeTime.ToString('MM/dd/yyyy'))) is already hidden"
          } # if $Update.IsHidden
        } # if $KBArticleID -eq $KBNumber
      } # Foreach $KBArticleID
    } # Foreach $Update
 
    if ($KBListed -eq $false) {
      Write-Host "Update $KBNumber was not found searching Windows Update"
    }
    "-----------"
  } # Foreach $KBNumber
 
  ""
  $objAutoUpdateSettings = (New-Object -ComObject "Microsoft.Update.AutoUpdate").Settings
  $objSysInfo = New-Object -ComObject "Microsoft.Update.SystemInfo"
  if ($objSysInfo.RebootRequired) {
    "A reboot is required to complete the process"
  } else {
    "No reboot is required"
  }
 
  ""
  "Script execution succeeded"
  $ExitCode = 0
}
catch {
  ""
  $error[0]
  ""
  "Hiding update(s) failed"
  $ExitCode = 1001 # Cause script to report failure in GFI dashboard
}
 
""
"Local Machine Time:  " + (Get-Date -Format G)
"Exit Code: " + $ExitCode
Exit $ExitCode