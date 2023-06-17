<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2023 v5.8.223
	 Created on:   	2023-06-15 23:04
	 Created by:   	Andrew Rathbun
	===========================================================================
	.DESCRIPTION
		This is a PowerShell 5 adaptation of Yamamoto Security's YamatoSecurityConfigureWinEventLogs.bat which can be found below

	.LINK
		https://github.com/Yamato-Security/EnableWindowsLogSettings/blob/main/YamatoSecurityConfigureWinEventLogs.bat

	.FEATURES
		Logging to a file on disk
		Confirmation that values set were actually set before telling the end user they were set.
		Messages that indicate values weren't set successfully
		Sections of the original batch file have been organized into PowerShell functions for ease of readability and maintainability

	.CHANGELOG
		v1.0 - June 16, 2023 - Initial release/adapation to PowerShell 5
#>

# This script requires admin privileges to run properly
# Checking if the current user is an admin, if not, it will request elevation
$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin -eq $false)
{
	# Relaunch script with admin privileges
	$scriptPath = $MyInvocation.MyCommand.Path
	Start-Process powershell.exe -Verb RunAs -ArgumentList "-File `"$scriptPath`""
	exit
}

# Set the location for the log file in a variable
$logFile = "$PSScriptRoot\ConfigureWindowsEventLogs.log"

function Get-TimeStamp
{
    <#
        .SYNOPSIS
            This function returns the current time in the format of YYYY/MM/dd HH:mm:ss
    #>
	return "[{0:yyyy/MM/dd} {0:HH:mm:ss}]" -f (Get-Date)
}

function Log
{
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 1,
				   HelpMessage = 'Please specify the log file to append to')]
		[string]$logFile,
		[Parameter(Mandatory = $true,
				   Position = 2,
				   HelpMessage = 'Please specify the message to write to host and the specified log file')]
		[string]$msg,
		[Parameter(Mandatory = $false,
				   Position = 3,
				   HelpMessage = 'Please specify the level of the log message')]
		[ValidateSet("Info", "Warning", "Error")]
		[string]$level = "Info"
	)
	
	$timestamp = Get-TimeStamp
	$logMessage = "$timestamp | $level | $msg"
	
	# Write message to log file
	Add-Content -Path $logFile -Value $logMessage -Encoding ASCII
	
	# Display message based on log level
	switch ($level)
	{
		'Info'    { Write-Host $logMessage -ForegroundColor Cyan }
		'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
		'Error'   { Write-Host $logMessage -ForegroundColor Red }
	}
	# Log -logFile $logFile -msg "----- Beginning of Session -----" -level "Info"
	# Log -logFile $logFile -msg "FYI: no CSVs were located in the specified folder path" -level "Warning"
	# Log -logFile $logFile -msg "Something went wrong" -level "Error"
}

Log -logFile $logFile -msg "----- Beginning of Session -----" -level "Info"

# Increase or decrease the log sizes as you see fit (in bytes of 64kb blocks):
# Using technical terms here: 1 mebibyte = 1024 kibibytes | 1 megabyte = 1000 kilobytes
$2GB = '2147483648' # 2147483648 bytes = 2048 mebibytes = 2 gibibytes
$1GB = '1073741824' # 1073741824 bytes = 1024 mebibytes = 1 gibibyte
$512MB = '536870912' # 536870912 bytes = 512 mebibytes = .5 gibibyte
$256MB = '268435456' # 268435456 bytes = 256 mebibytes = .25 gibibyte
$128MB = '134217728' # 134217728 bytes = 128 mebibytes = .125 gibibyte

$2GBCommand = '/ms:' + $2GB
$1GBCommand = '/ms:' + $1GB
$512MBCommand = '/ms:' + $512MB
$256MBCommand = '/ms:' + $256MB
$128MBCommand = '/ms:' + $128MB

function Expand-EventLogSize
{
	[CmdletBinding()]
	param ()
	
	Log -logFile $logFile -msg "------- Increase Event Log MaxSize Values -------" -level "Info"
	
	# Set Security, Sysmon, and PowerShell-related logs' maximum file size to 1 GB 
	$1gbLogNames = "Security", "Microsoft-Windows-PowerShell/Operational", "Windows PowerShell", "PowerShellCore/Operational", "Microsoft-Windows-Sysmon/Operational"
	
	# Get a list of all log names
	$allLogNames = (Get-WinEvent -ListLog *).LogName
	
	# List to store names of non-existent logs
	$nonExistent1GBLogs = @()
	
	foreach ($1gbLogName in $1gbLogNames)
	{
		# Check if the log exists
		if ($allLogNames -contains $1gbLogName)
		{
			Log -logFile $logFile -msg "Modifying the maximum size for the ${1gbLogName} event log"
			
			# Fetch the current maximum size
			$currentMaxSizeBytes = ((wevtutil gl $1gbLogName) -like "*maxSize:*").Split(':')[1].Trim()
			
			# Convert to KB and MB
			$currentMaxSizeKB = [math]::Round(($currentMaxSizeBytes / 1KB), 2)
			$currentMaxSizeMB = [math]::Round(($currentMaxSizeBytes / 1MB), 2)
			
			# Inform the user about the current maximum size
			Log -logFile $logFile -msg "Current maximum size of ${1gbLogName}: $currentMaxSizeBytes bytes | $currentMaxSizeKB KB | $currentMaxSizeMB MB"
			
			# Define the command string
			$commandString = "wevtutil sl `"$1gbLogName`" $1GBCommand"
			
			# Inform the user about the command that will be executed
			Log -logFile $logFile -msg "Running command: $commandString"
			
			# Execute the command
			Invoke-Expression -Command $commandString
			
			# Fetch the updated maximum size
			$updatedMaxSizeBytes = ((wevtutil gl $1gbLogName) -like "*maxSize:*").Split(':')[1].Trim()
			
			# Convert to KB and MB
			$updatedMaxSizeKB = [math]::Round(($updatedMaxSizeBytes / 1KB), 2)
			$updatedMaxSizeMB = [math]::Round(($updatedMaxSizeBytes / 1MB), 2)
			
			# Inform the user about the updated maximum size
			Log -logFile $logFile -msg "Updated maximum size of ${1gbLogName}: $updatedMaxSizeBytes bytes | $updatedMaxSizeKB KB | $updatedMaxSizeMB MB"
		}
		else
		{
			# Add to non-existent logs list
			$nonExistent1GBLogs += $1gbLogName
		}
	}
	
	# Output non-existent logs
	if ($nonExistent1GBLogs.Count -gt 0)
	{
		$nonExistent1GBLogsString = $nonExistent1GBLogs -join ', '
		Log -logFile $logFile -msg "The following logs were attempted but do not currently exist: $nonExistent1GBLogsString"
	}
	
	# Define the 128 MB log names
	$128mblogNames = "System", "Application", "Microsoft-Windows-Windows Defender/Operational", "Microsoft-Windows-Bits-Client/Operational",
	"Microsoft-Windows-Windows Firewall With Advanced Security/Firewall", "Microsoft-Windows-NTLM/Operational",
	"Microsoft-Windows-Security-Mitigations/KernelMode", "Microsoft-Windows-Security-Mitigations/UserMode",
	"Microsoft-Windows-PrintService/Admin", "Microsoft-Windows-Security-Mitigations/UserMode",
	"Microsoft-Windows-PrintService/Operational", "Microsoft-Windows-SmbClient/Security",
	"Microsoft-Windows-AppLocker/MSI and Script", "Microsoft-Windows-AppLocker/EXE and DLL",
	"Microsoft-Windows-AppLocker/Packaged app-Deployment", "Microsoft-Windows-AppLocker/Packaged app-Execution",
	"Microsoft-Windows-CodeIntegrity/Operational", "Microsoft-Windows-Diagnosis-Scripted/Operational",
	"Microsoft-Windows-DriverFrameworks-UserMode/Operational", "Microsoft-Windows-WMI-Activity/Operational",
	"Microsoft-Windows-TerminalServices-LocalSessionManager/Operational", "Microsoft-Windows-TaskScheduler/Operational"
	
	# Define the list for non-existent logs
	$nonExistent128MBLogs = @()
	
	foreach ($128mblogName in $128mblogNames)
	{
		# Check if the log exists
		if ($allLogNames -contains $128mblogName)
		{
			# Fetch the current maximum size
			$currentMaxSizeBytes = ((wevtutil gl $128mblogName) -like "*maxSize:*").Split(':')[1].Trim()
			
			# Convert to KB and MB
			$currentMaxSizeKB = [math]::Round(($currentMaxSizeBytes / 1KB), 2)
			$currentMaxSizeMB = [math]::Round(($currentMaxSizeBytes / 1MB), 2)
			
			# Inform the user about the current maximum size
			Log -logFile $logFile -msg "Current maximum size of ${128mblogName}: $currentMaxSizeBytes bytes | $currentMaxSizeKB KB | $currentMaxSizeMB MB"
			
			# Define the command string
			$commandString = "wevtutil sl `"$128mblogName`" $128MBCommand"
			
			# Inform the user about the command that will be executed
			Log -logFile $logFile -msg "Running command: $commandString"
			
			# Execute the command
			Invoke-Expression -Command $commandString
			
			# Fetch the updated maximum size
			$updatedMaxSizeBytes = ((wevtutil gl $128mblogName) -like "*maxSize:*").Split(':')[1].Trim()
			
			# Convert to KB and MB
			$updatedMaxSizeKB = [math]::Round(($updatedMaxSizeBytes / 1KB), 2)
			$updatedMaxSizeMB = [math]::Round(($updatedMaxSizeBytes / 1MB), 2)
			
			# Inform the user about the updated maximum size
			Log -logFile $logFile -msg "Updated maximum size of ${128mblogName}: $updatedMaxSizeBytes bytes | $updatedMaxSizeKB KB | $updatedMaxSizeMB MB"
		}
		else
		{
			# Add the log name to the non-existent logs list
			$nonExistent128MBLogs += $128mblogName
		}
	}
	
	# Inform the user if any logs did not exist
	if ($nonExistent128MBLogs.Count -gt 0)
	{
		$nonExistent128MBLogsString = $nonExistent128MBLogs -join ', '
		Log -logFile $logFile -msg "The following logs were attempted but do not currently exist: $nonExistent128MBLogsString"
	}
}

function Expand-PowerShellLogging
{
	[CmdletBinding()]
	param ()
	
	Log -logFile $logFile -msg "------- Enable PowerShell Logging -------" -level "Info"
	
	$powerShellModuleLoggingPath = 'HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ModuleLogging'
	$powerShellModuleLoggingValueName = 'EnableModuleLogging'
	
	Log -logFile $logFile -msg "Checking if $powerShellModuleLoggingPath has the $powerShellModuleLoggingValueName value"
	
	# Check if the path exists before trying to modify it
	if (Test-Path $powerShellModuleLoggingPath)
	{
		# Check if ModuleLogging is enabled
		if ((Get-ItemProperty -Path "$powerShellModuleLoggingPath").$powerShellModuleLoggingValueName -eq 1)
		{
			Log -logFile $logFile -msg "PowerShell Module logging ($powerShellModuleLoggingValueName) is already enabled"
		}
		else
		{
			# Enable PowerShell Module logging
			Set-ItemProperty -Path "$powerShellModuleLoggingPath" -Name "$powerShellModuleLoggingValueName" -Value 1 -ErrorAction Stop
		}
	}
	else
	{
		Log -logFile $logFile -msg "Registry path $powerShellModuleLoggingPath does not currently exist"
		# Enable PowerShell Module logging
		Set-ItemProperty -Path "$powerShellModuleLoggingPath" -Name "$powerShellModuleLoggingValueName" -Value 1 -ErrorAction Stop
		Log -logFile $logFile -msg "PowerShell Module logging enabled"
	}
	
	$powerShellModuleLoggingModuleNamesPath = 'HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ModuleLogging\ModuleNames'
	
	# Check if the path exists before trying to modify it
	if (Test-Path $powerShellModuleLoggingModuleNamesPath)
	{
		# Check if all modules are now logged
		if ((Get-ItemProperty -Path "$powerShellModuleLoggingModuleNamesPath").'*' -eq "*")
		{
			Log -logFile $logFile -msg "All modules are now logged in PowerShell Module logging"
		}
		else
		{
			Log -logFile $logFile -msg "Failed to log all modules in PowerShell Module logging"
		}
	}
	else
	{
		Log -logFile $logFile -msg "Registry path $powerShellModuleLoggingModuleNamesPath does not currently exist"
		Set-ItemProperty -Path "$powerShellModuleLoggingModuleNamesPath" -Name "*" -Value "*"
		Log -logFile $logFile -msg "All modules are now logged in PowerShell Module logging"
		
		#TODO add validation
	}
	
	$powerShellScriptBlockLoggingPath = 'HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging'
	$powerShellScriptBlockLoggingValueName = 'EnableScriptBlockLogging'
	
	if (Test-Path $powerShellScriptBlockLoggingPath)
	{
		# Enable PowerShell Script Block logging
		Set-ItemProperty -Path "$powerShellScriptBlockLoggingPath" -Name "$powerShellScriptBlockLoggingValueName" -Value 1 -ErrorAction Stop
		
		# Check if ScriptBlockLogging is enabled
		if ((Get-ItemProperty -Path "$powerShellScriptBlockLoggingPath").$powerShellScriptBlockLoggingValueName -eq 1)
		{
			Log -logFile $logFile -msg "PowerShell Script Block logging enabled"
		}
		else
		{
			Log -logFile $logFile -msg "Failed to enable PowerShell Script Block logging"
		}
	}
	else
	{
		Log -logFile $logFile -msg "Registry path $powerShellScriptBlockLoggingPath does not exist"
	}
}

function Enable-EventLogs
{
	[CmdletBinding()]
	param ()
	
	Log -logFile $logFile -msg "------- Enable Event Logs -------" -level "Info"
	
	# Define an array with the log names
	$logs = @("Microsoft-Windows-TaskScheduler/Operational", "Microsoft-Windows-DriverFrameworks-UserMode/Operational")
	
	# Loop over each log name
	foreach ($log in $logs)
	{
		# Enable the log
		& wevtutil sl $log /e:true
		
		# Check if the log was enabled
		$isEnabled = & wevtutil gl $log | Select-String -Pattern "enabled:"
		if ($isEnabled -match "true")
		{
			Log -logFile $logFile -msg "Log $log enabled"
		}
		else
		{
			Log -logFile $logFile -msg "Failed to enable log $log"
		}
	}
}

function Enable-CommandLineAuditing
{
	[CmdletBinding()]
	param ()
	
	Log -logFile $logFile -msg "------- Enable Command Line Auditing -------" -level "Info"
	
	$commandLineAuditingPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit'
	$commandLineAuditingValueName = 'ProcessCreationIncludeCmdLine_Enabled'
	
	# Enable command line auditing
	Set-ItemProperty -Path "$commandLineAuditingPath" -Name "$commandLineAuditingValueName" -Value 1 -Type DWord -Force
	
	# Check if command line auditing was enabled
	if ((Get-ItemProperty -Path "$commandLineAuditingPath").$commandLineAuditingValueName -eq 1)
	{
		Log -logFile $logFile -msg "Command line auditing enabled successfully"
	}
	else
	{
		Log -logFile $logFile -msg "Failed to enable command line auditing"
	}
}

function Enable-AuditPolicies
{
	[CmdletBinding()]
	param ()
	
	Log -logFile $logFile -msg "------- Enable Audit Policies -------" -level "Info"
	
	# Define a hashtable for each category, with the GUIDs as the keys and the category names as the values
	$AccountLogon = @{
		"0CCE923F-69AE-11D9-BED3-505054503030" = "Credential Validation"
		"0CCE9242-69AE-11D9-BED3-505054503030" = "Kerberos Authentication Service"
		"0CCE9240-69AE-11D9-BED3-505054503030" = "Kerberos Service Ticket Operations"
	}
	
	$AccountManagement = @{
		"0CCE9236-69AE-11D9-BED3-505054503030" = "Computer Account Management"
		"0CCE923A-69AE-11D9-BED3-505054503030" = "Other Account Management Events"
		"0CCE9237-69AE-11D9-BED3-505054503030" = "Security Group Management"
		"0CCE9235-69AE-11D9-BED3-505054503030" = "User Account Management"
	}
	
	$DetailedTracking = @{
		'0cce9248-69ae-11d9-bed3-505054503030' = 'Plug and Play';
		'0CCE922B-69AE-11D9-BED3-505054503030' = 'Process Creation';
		# '0CCE922C-69AE-11D9-BED3-505054503030' = 'Process Termination'; # disabled by default
		'0CCE922E-69AE-11D9-BED3-505054503030' = 'RPC Events';
		# '0CCE924A-69AE-11D9-BED3-505054503030' = 'Audit Token Right Adjustments'; # disabled by default
	}
	
	$DSAccess = @{
		'0CCE923B-69AE-11D9-BED3-505054503030' = 'Directory Service Access';
		'0CCE923C-69AE-11D9-BED3-505054503030' = 'Directory Service Changes';
	}
	
	$LogonLogoff = @{
		'0CCE9217-69AE-11D9-BED3-505054503030' = 'Account Lockout';
		# '0CCE9249-69AE-11D9-BED3-505054503030' = 'Group Membership'; # disabled by default
		'0CCE9216-69AE-11D9-BED3-505054503030' = 'Logoff';
		'0CCE9215-69AE-11D9-BED3-505054503030' = 'Logon';
		# '0CCE9243-69AE-11D9-BED3-505054503030' = 'Network Policy Server'; # disabled by default
		'0CCE921C-69AE-11D9-BED3-505054503030' = 'Other Logon/Logoff Events';
		'0CCE921B-69AE-11D9-BED3-505054503030' = 'Special Logon';
	}
	
	$ObjectAccess = @{
		# '0CCE9222-69AE-11D9-BED3-505054503030' = 'Application Generated'; # currently disabled while testing
		'0CCE9221-69AE-11D9-BED3-505054503030' = 'Certification Services'; # disable for client OSes
		# '0CCE9244-69AE-11D9-BED3-505054503030' = 'Detailed File Share'; # disabled by default
		'0CCE9224-69AE-11D9-BED3-505054503030' = 'File Share'; # disable if too noisy
		# '0CCE921D-69AE-11D9-BED3-505054503030' = 'File System'; # disabled by default
		'0CCE9226-69AE-11D9-BED3-505054503030' = 'Filtering Platform Connection'; # disable if too noisy
		# '0CCE9225-69AE-11D9-BED3-505054503030' = 'Filtering Platform Packet Drop'; # disabled due to noise
		# '0CCE921F-69AE-11D9-BED3-505054503030' = 'Kernel Object'; # disabled due to noise
		'0CCE9227-69AE-11D9-BED3-505054503030' = 'Other Object Access Events';
		# '0CCE921E-69AE-11D9-BED3-505054503030' = 'Registry'; # disabled due to noise
		'0CCE9245-69AE-11D9-BED3-505054503030' = 'Removable Storage';
		'0CCE9220-69AE-11D9-BED3-505054503030' = 'SAM';
	}
	
	$PolicyChange = @{
		'0CCE922F-69AE-11D9-BED3-505054503030' = 'Audit Policy Change';
		'0CCE9230-69AE-11D9-BED3-505054503030' = 'Authentication Policy Change';
		# '0CCE9231-69AE-11D9-BED3-505054503030' = 'Authorization Policy Change'; # currently disabled while testing
		# '0CCE9233-69AE-11D9-BED3-505054503030' = 'Filtering Platform Policy Change'; # currently disabled while testing
		# '0CCE9232-69AE-11D9-BED3-505054503030' = 'MPSSVC Rule-Level Policy Change'; # currently disabled while testing
		'0CCE9234-69AE-11D9-BED3-505054503030' = 'Other Policy Change Events';
	}
	
	$PrivilegeUse = @{
		'0CCE9228-69AE-11D9-BED3-505054503030' = 'Sensitive Privilege Use'; # disable if too noisy
	}
	
	$System = @{
		'0CCE9214-69AE-11D9-BED3-505054503030' = 'Other System Events'; # needs testing
		'0CCE9210-69AE-11D9-BED3-505054503030' = 'Security State Change';
		'0CCE9211-69AE-11D9-BED3-505054503030' = 'Security System Extension';
		'0CCE9212-69AE-11D9-BED3-505054503030' = 'System Integrity';
	}
	
	# Combine all categories into one array
	$allCategories = @{
		'AccountLogon'	    = $AccountLogon
		'AccountManagement' = $AccountManagement
		'DetailedTracking'  = $DetailedTracking
		'DSAccess'		    = $DSAccess
		'LogonLogoff'	    = $LogonLogoff
		'ObjectAccess'	    = $ObjectAccess
		'PolicyChange'	    = $PolicyChange
		'PrivilegeUse'	    = $PrivilegeUse
		'System'		    = $System
	}
	
	foreach ($categoryName in $allCategories.Keys)
	{
		$category = $allCategories[$categoryName]
		
		Log -logFile $logFile -msg "Category: $categoryName"
		
		foreach ($subcategory in $category.Keys)
		{
			$subcategoryName = $category[$subcategory]
			
			Log -logFile $logFile -msg "Subcategory: $subcategory"
			Log -logFile $logFile -msg "Subcategory Name: $subcategoryName"
			
			try
			{
				# Prepare auditpol set command
				$auditpolCommand = "/c auditpol /set /subcategory:`"{${subcategory}}`" /success:enable /failure:enable"
				# Output the command to be run
				Log -logFile $logFile -msg "Running command: cmd $auditpolCommand"
				# Run the command
				cmd $auditpolCommand
				
				# Prepare auditpol get command for validation
				$validationCommand = "/c auditpol /get /subcategory:`"{${subcategory}}`" /r"
				# Output the command to be run
				Log -logFile $logFile -msg "Running validation command: cmd $validationCommand"
				# Run validation command
				$validationResult = cmd $validationCommand
				
				# Ensure the command output is an array, even if it only contains one line
				if ($validationResult -isnot [array]) { $validationResult = @($validationResult) }
				
				# Check if there are at least three lines
				if ($validationResult.Count -gt 2)
				{
					# Extract the "Inclusion Setting" from the third line of the output
					$thirdLine = $validationResult[2]
					$inclusionSetting = ($thirdLine -split ',')[4].Trim()
					
					Log -logFile $logFile -msg "Inclusion Setting for $($subcategoryName): $inclusionSetting"
					
					if ($inclusionSetting -eq "Success and Failure")
					{
						Log -logFile $logFile -msg "Both successful and failure events are now being audited for the $($subcategoryName) subcategory"
					}
					else
					{
						Log -logFile $logFile -msg "Failed to enable auditing for the $($subcategoryName) subcategory"
					}
				}
				else
				{
					Log -logFile $logFile -msg "Failed to retrieve auditing settings for the $($subcategoryName) subcategory"
				}
			}
			catch
			{
				Log -logFile $logFile -msg "An error occurred while enabling auditing for the $($subcategoryName) subcategory: $_"
			}
		}
	}
}

try
{
	# Code block to be executed within the try block
	Expand-EventLogSize
	Expand-PowerShellLogging
	Enable-EventLogs
	Enable-CommandLineAuditing
	Enable-AuditPolicies
}
catch [System.IO.IOException] {
	# Handle specific IOException related to file operations
	Log -logFile $logFile -msg "IOException occurred: $($_.Message)" -level "Error"
}
catch [System.Exception] {
	# Handle any other exception that may have occurred
	Log -logFile $logFile -msg "Exception occurred: $($_.Exception.Message)" -level "Error"
}
finally
{
	# This block will always run, even if there was an exception
	Log -logFile $logFile -msg "------- End of Session -------" -level "Info"
}

# SIG # Begin signature block
# MIIviwYJKoZIhvcNAQcCoIIvfDCCL3gCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB+SFclYAjwS/va
# HPbfs9KrpNejdexaoKKvHWnbN+xUSqCCKJAwggQyMIIDGqADAgECAgEBMA0GCSqG
# SIb3DQEBBQUAMHsxCzAJBgNVBAYTAkdCMRswGQYDVQQIDBJHcmVhdGVyIE1hbmNo
# ZXN0ZXIxEDAOBgNVBAcMB1NhbGZvcmQxGjAYBgNVBAoMEUNvbW9kbyBDQSBMaW1p
# dGVkMSEwHwYDVQQDDBhBQUEgQ2VydGlmaWNhdGUgU2VydmljZXMwHhcNMDQwMTAx
# MDAwMDAwWhcNMjgxMjMxMjM1OTU5WjB7MQswCQYDVQQGEwJHQjEbMBkGA1UECAwS
# R3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHDAdTYWxmb3JkMRowGAYDVQQKDBFD
# b21vZG8gQ0EgTGltaXRlZDEhMB8GA1UEAwwYQUFBIENlcnRpZmljYXRlIFNlcnZp
# Y2VzMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvkCd9G7h6naHHE1F
# RI6+RsiDBp3BKv4YH47kAvrzq11QihYxC5oG0MVwIs1JLVRjzLZuaEYLU+rLTCTA
# vHJO6vEVrvRUmhIKw3qyM2Di2olV8yJY897cz++DhqKMlE+faPKYkEaEJ8d2v+PM
# NSyLXgdkZYLASLCokflhn3YgUKiRx2a163hiA1bwihoT6jGjHqCZ/Tj29icyWG8H
# 9Wu4+xQrr7eqzNZjX3OM2gWZqDioyxd4NlGs6Z70eDqNzw/ZQuKYDKsvnw4B3u+f
# mUnxLd+sdE0bmLVHxeUp0fmQGMdinL6DxyZ7Poolx8DdneY1aBAgnY/Y3tLDhJwN
# XugvyQIDAQABo4HAMIG9MB0GA1UdDgQWBBSgEQojPpbxB+zirynvgqV/0DCktDAO
# BgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUwAwEB/zB7BgNVHR8EdDByMDigNqA0
# hjJodHRwOi8vY3JsLmNvbW9kb2NhLmNvbS9BQUFDZXJ0aWZpY2F0ZVNlcnZpY2Vz
# LmNybDA2oDSgMoYwaHR0cDovL2NybC5jb21vZG8ubmV0L0FBQUNlcnRpZmljYXRl
# U2VydmljZXMuY3JsMA0GCSqGSIb3DQEBBQUAA4IBAQAIVvwC8Jvo/6T61nvGRIDO
# T8TF9gBYzKa2vBRJaAR26ObuXewCD2DWjVAYTyZOAePmsKXuv7x0VEG//fwSuMdP
# WvSJYAV/YLcFSvP28cK/xLl0hrYtfWvM0vNG3S/G4GrDwzQDLH2W3VrCDqcKmcEF
# i6sML/NcOs9sN1UJh95TQGxY7/y2q2VuBPYb3DzgWhXGntnxWUgwIWUDbOzpIXPs
# mwOh4DetoBUYj/q6As6nLKkQEyzU5QgmqyKXYPiQXnTUoppTvfKpaOCibsLXbLGj
# D56/62jnVvKu8uMrODoJgbVrhde+Le0/GreyY+L1YiyC1GoAQVDxOYOflek2lphu
# MIIFbzCCBFegAwIBAgIQSPyTtGBVlI02p8mKidaUFjANBgkqhkiG9w0BAQwFADB7
# MQswCQYDVQQGEwJHQjEbMBkGA1UECAwSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYD
# VQQHDAdTYWxmb3JkMRowGAYDVQQKDBFDb21vZG8gQ0EgTGltaXRlZDEhMB8GA1UE
# AwwYQUFBIENlcnRpZmljYXRlIFNlcnZpY2VzMB4XDTIxMDUyNTAwMDAwMFoXDTI4
# MTIzMTIzNTk1OVowVjELMAkGA1UEBhMCR0IxGDAWBgNVBAoTD1NlY3RpZ28gTGlt
# aXRlZDEtMCsGA1UEAxMkU2VjdGlnbyBQdWJsaWMgQ29kZSBTaWduaW5nIFJvb3Qg
# UjQ2MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAjeeUEiIEJHQu/xYj
# ApKKtq42haxH1CORKz7cfeIxoFFvrISR41KKteKW3tCHYySJiv/vEpM7fbu2ir29
# BX8nm2tl06UMabG8STma8W1uquSggyfamg0rUOlLW7O4ZDakfko9qXGrYbNzszwL
# DO/bM1flvjQ345cbXf0fEj2CA3bm+z9m0pQxafptszSswXp43JJQ8mTHqi0Eq8Nq
# 6uAvp6fcbtfo/9ohq0C/ue4NnsbZnpnvxt4fqQx2sycgoda6/YDnAdLv64IplXCN
# /7sVz/7RDzaiLk8ykHRGa0c1E3cFM09jLrgt4b9lpwRrGNhx+swI8m2JmRCxrds+
# LOSqGLDGBwF1Z95t6WNjHjZ/aYm+qkU+blpfj6Fby50whjDoA7NAxg0POM1nqFOI
# +rgwZfpvx+cdsYN0aT6sxGg7seZnM5q2COCABUhA7vaCZEao9XOwBpXybGWfv1Vb
# HJxXGsd4RnxwqpQbghesh+m2yQ6BHEDWFhcp/FycGCvqRfXvvdVnTyheBe6QTHrn
# xvTQ/PrNPjJGEyA2igTqt6oHRpwNkzoJZplYXCmjuQymMDg80EY2NXycuu7D1fkK
# dvp+BRtAypI16dV60bV/AK6pkKrFfwGcELEW/MxuGNxvYv6mUKe4e7idFT/+IAx1
# yCJaE5UZkADpGtXChvHjjuxf9OUCAwEAAaOCARIwggEOMB8GA1UdIwQYMBaAFKAR
# CiM+lvEH7OKvKe+CpX/QMKS0MB0GA1UdDgQWBBQy65Ka/zWWSC8oQEJwIDaRXBeF
# 5jAOBgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zATBgNVHSUEDDAKBggr
# BgEFBQcDAzAbBgNVHSAEFDASMAYGBFUdIAAwCAYGZ4EMAQQBMEMGA1UdHwQ8MDow
# OKA2oDSGMmh0dHA6Ly9jcmwuY29tb2RvY2EuY29tL0FBQUNlcnRpZmljYXRlU2Vy
# dmljZXMuY3JsMDQGCCsGAQUFBwEBBCgwJjAkBggrBgEFBQcwAYYYaHR0cDovL29j
# c3AuY29tb2RvY2EuY29tMA0GCSqGSIb3DQEBDAUAA4IBAQASv6Hvi3SamES4aUa1
# qyQKDKSKZ7g6gb9Fin1SB6iNH04hhTmja14tIIa/ELiueTtTzbT72ES+BtlcY2fU
# QBaHRIZyKtYyFfUSg8L54V0RQGf2QidyxSPiAjgaTCDi2wH3zUZPJqJ8ZsBRNraJ
# AlTH/Fj7bADu/pimLpWhDFMpH2/YGaZPnvesCepdgsaLr4CnvYFIUoQx2jLsFeSm
# TD1sOXPUC4U5IOCFGmjhp0g4qdE2JXfBjRkWxYhMZn0vY86Y6GnfrDyoXZ3JHFuu
# 2PMvdM+4fvbXg50RlmKarkUT2n/cR/vfw1Kf5gZV6Z2M8jpiUbzsJA8p1FiAhORF
# e1rYMIIFgzCCA2ugAwIBAgIORea7A4Mzw4VlSOb/RVEwDQYJKoZIhvcNAQEMBQAw
# TDEgMB4GA1UECxMXR2xvYmFsU2lnbiBSb290IENBIC0gUjYxEzARBgNVBAoTCkds
# b2JhbFNpZ24xEzARBgNVBAMTCkdsb2JhbFNpZ24wHhcNMTQxMjEwMDAwMDAwWhcN
# MzQxMjEwMDAwMDAwWjBMMSAwHgYDVQQLExdHbG9iYWxTaWduIFJvb3QgQ0EgLSBS
# NjETMBEGA1UEChMKR2xvYmFsU2lnbjETMBEGA1UEAxMKR2xvYmFsU2lnbjCCAiIw
# DQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAJUH6HPKZvnsFMp7PPcNCPG0RQss
# grRIxutbPK6DuEGSMxSkb3/pKszGsIhrxbaJ0cay/xTOURQh7ErdG1rG1ofuTToV
# Bu1kZguSgMpE3nOUTvOniX9PeGMIyBJQbUJmL025eShNUhqKGoC3GYEOfsSKvGRM
# IRxDaNc9PIrFsmbVkJq3MQbFvuJtMgamHvm566qjuL++gmNQ0PAYid/kD3n16qIf
# KtJwLnvnvJO7bVPiSHyMEAc4/2ayd2F+4OqMPKq0pPbzlUoSB239jLKJz9CgYXfI
# WHSw1CM69106yqLbnQneXUQtkPGBzVeS+n68UARjNN9rkxi+azayOeSsJDa38O+2
# HBNXk7besvjihbdzorg1qkXy4J02oW9UivFyVm4uiMVRQkQVlO6jxTiWm05OWgtH
# 8wY2SXcwvHE35absIQh1/OZhFj931dmRl4QKbNQCTXTAFO39OfuD8l4UoQSwC+n+
# 7o/hbguyCLNhZglqsQY6ZZZZwPA1/cnaKI0aEYdwgQqomnUdnjqGBQCe24DWJfnc
# BZ4nWUx2OVvq+aWh2IMP0f/fMBH5hc8zSPXKbWQULHpYT9NLCEnFlWQaYw55PfWz
# jMpYrZxCRXluDocZXFSxZba/jJvcE+kNb7gu3GduyYsRtYQUigAZcIN5kZeR1Bon
# vzceMgfYFGM8KEyvAgMBAAGjYzBhMA4GA1UdDwEB/wQEAwIBBjAPBgNVHRMBAf8E
# BTADAQH/MB0GA1UdDgQWBBSubAWjkxPioufi1xzWx/B/yGdToDAfBgNVHSMEGDAW
# gBSubAWjkxPioufi1xzWx/B/yGdToDANBgkqhkiG9w0BAQwFAAOCAgEAgyXt6NH9
# lVLNnsAEoJFp5lzQhN7craJP6Ed41mWYqVuoPId8AorRbrcWc+ZfwFSY1XS+wc3i
# EZGtIxg93eFyRJa0lV7Ae46ZeBZDE1ZXs6KzO7V33EByrKPrmzU+sQghoefEQzd5
# Mr6155wsTLxDKZmOMNOsIeDjHfrYBzN2VAAiKrlNIC5waNrlU/yDXNOd8v9EDERm
# 8tLjvUYAGm0CuiVdjaExUd1URhxN25mW7xocBFymFe944Hn+Xds+qkxV/ZoVqW/h
# pvvfcDDpw+5CRu3CkwWJ+n1jez/QcYF8AOiYrg54NMMl+68KnyBr3TsTjxKM4kEa
# SHpzoHdpx7Zcf4LIHv5YGygrqGytXm3ABdJ7t+uA/iU3/gKbaKxCXcPu9czc8FB1
# 0jZpnOZ7BN9uBmm23goJSFmH63sUYHpkqmlD75HHTOwY3WzvUy2MmeFe8nI+z1TI
# vWfspA9MRf/TuTAjB0yPEL+GltmZWrSZVxykzLsViVO6LAUP5MSeGbEYNNVMnbrt
# 9x+vJJUEeKgDu+6B5dpffItKoZB0JaezPkvILFa9x8jvOOJckvB595yEunQtYQEg
# fn7R8k8HWV+LLUNS60YMlOH1Zkd5d9VUWx+tJDfLRVpOoERIyNiwmcUVhAn21klJ
# wGW45hpxbqCo8YLoRT5s1gLXCmeDBVrJpBAwggYaMIIEAqADAgECAhBiHW0MUgGe
# O5B5FSCJIRwKMA0GCSqGSIb3DQEBDAUAMFYxCzAJBgNVBAYTAkdCMRgwFgYDVQQK
# Ew9TZWN0aWdvIExpbWl0ZWQxLTArBgNVBAMTJFNlY3RpZ28gUHVibGljIENvZGUg
# U2lnbmluZyBSb290IFI0NjAeFw0yMTAzMjIwMDAwMDBaFw0zNjAzMjEyMzU5NTla
# MFQxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxKzApBgNV
# BAMTIlNlY3RpZ28gUHVibGljIENvZGUgU2lnbmluZyBDQSBSMzYwggGiMA0GCSqG
# SIb3DQEBAQUAA4IBjwAwggGKAoIBgQCbK51T+jU/jmAGQ2rAz/V/9shTUxjIztNs
# fvxYB5UXeWUzCxEeAEZGbEN4QMgCsJLZUKhWThj/yPqy0iSZhXkZ6Pg2A2NVDgFi
# gOMYzB2OKhdqfWGVoYW3haT29PSTahYkwmMv0b/83nbeECbiMXhSOtbam+/36F09
# fy1tsB8je/RV0mIk8XL/tfCK6cPuYHE215wzrK0h1SWHTxPbPuYkRdkP05ZwmRmT
# nAO5/arnY83jeNzhP06ShdnRqtZlV59+8yv+KIhE5ILMqgOZYAENHNX9SJDm+qxp
# 4VqpB3MV/h53yl41aHU5pledi9lCBbH9JeIkNFICiVHNkRmq4TpxtwfvjsUedyz8
# rNyfQJy/aOs5b4s+ac7IH60B+Ja7TVM+EKv1WuTGwcLmoU3FpOFMbmPj8pz44MPZ
# 1f9+YEQIQty/NQd/2yGgW+ufflcZ/ZE9o1M7a5Jnqf2i2/uMSWymR8r2oQBMdlyh
# 2n5HirY4jKnFH/9gRvd+QOfdRrJZb1sCAwEAAaOCAWQwggFgMB8GA1UdIwQYMBaA
# FDLrkpr/NZZILyhAQnAgNpFcF4XmMB0GA1UdDgQWBBQPKssghyi47G9IritUpimq
# F6TNDDAOBgNVHQ8BAf8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIBADATBgNVHSUE
# DDAKBggrBgEFBQcDAzAbBgNVHSAEFDASMAYGBFUdIAAwCAYGZ4EMAQQBMEsGA1Ud
# HwREMEIwQKA+oDyGOmh0dHA6Ly9jcmwuc2VjdGlnby5jb20vU2VjdGlnb1B1Ymxp
# Y0NvZGVTaWduaW5nUm9vdFI0Ni5jcmwwewYIKwYBBQUHAQEEbzBtMEYGCCsGAQUF
# BzAChjpodHRwOi8vY3J0LnNlY3RpZ28uY29tL1NlY3RpZ29QdWJsaWNDb2RlU2ln
# bmluZ1Jvb3RSNDYucDdjMCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5zZWN0aWdv
# LmNvbTANBgkqhkiG9w0BAQwFAAOCAgEABv+C4XdjNm57oRUgmxP/BP6YdURhw1aV
# cdGRP4Wh60BAscjW4HL9hcpkOTz5jUug2oeunbYAowbFC2AKK+cMcXIBD0ZdOaWT
# syNyBBsMLHqafvIhrCymlaS98+QpoBCyKppP0OcxYEdU0hpsaqBBIZOtBajjcw5+
# w/KeFvPYfLF/ldYpmlG+vd0xqlqd099iChnyIMvY5HexjO2AmtsbpVn0OhNcWbWD
# RF/3sBp6fWXhz7DcML4iTAWS+MVXeNLj1lJziVKEoroGs9Mlizg0bUMbOalOhOfC
# ipnx8CaLZeVme5yELg09Jlo8BMe80jO37PU8ejfkP9/uPak7VLwELKxAMcJszkye
# iaerlphwoKx1uHRzNyE6bxuSKcutisqmKL5OTunAvtONEoteSiabkPVSZ2z76mKn
# zAfZxCl/3dq3dUNw4rg3sTCggkHSRqTqlLMS7gjrhTqBmzu1L90Y1KWN/Y5JKdGv
# spbOrTfOXyXvmPL6E52z1NZJ6ctuMFBQZH3pwWvqURR8AgQdULUvrxjUYbHHj95E
# jza63zdrEcxWLDX6xWls/GDnVNueKjWUH3fTv1Y8Wdho698YADR7TNx8X8z2Bev6
# SivBBOHY+uqiirZtg0y9ShQoPzmCcn63Syatatvx157YK9hlcPmVoa1oDE5/L9Uo
# 2bC5a4CH2RwwggZZMIIEQaADAgECAg0B7BySQN79LkBdfEd0MA0GCSqGSIb3DQEB
# DAUAMEwxIDAeBgNVBAsTF0dsb2JhbFNpZ24gUm9vdCBDQSAtIFI2MRMwEQYDVQQK
# EwpHbG9iYWxTaWduMRMwEQYDVQQDEwpHbG9iYWxTaWduMB4XDTE4MDYyMDAwMDAw
# MFoXDTM0MTIxMDAwMDAwMFowWzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2Jh
# bFNpZ24gbnYtc2ExMTAvBgNVBAMTKEdsb2JhbFNpZ24gVGltZXN0YW1waW5nIENB
# IC0gU0hBMzg0IC0gRzQwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDw
# AuIwI/rgG+GadLOvdYNfqUdSx2E6Y3w5I3ltdPwx5HQSGZb6zidiW64HiifuV6PE
# Ne2zNMeswwzrgGZt0ShKwSy7uXDycq6M95laXXauv0SofEEkjo+6xU//NkGrpy39
# eE5DiP6TGRfZ7jHPvIo7bmrEiPDul/bc8xigS5kcDoenJuGIyaDlmeKe9JxMP11b
# 7Lbv0mXPRQtUPbFUUweLmW64VJmKqDGSO/J6ffwOWN+BauGwbB5lgirUIceU/kKW
# O/ELsX9/RpgOhz16ZevRVqkuvftYPbWF+lOZTVt07XJLog2CNxkM0KvqWsHvD9WZ
# uT/0TzXxnA/TNxNS2SU07Zbv+GfqCL6PSXr/kLHU9ykV1/kNXdaHQx50xHAotIB7
# vSqbu4ThDqxvDbm19m1W/oodCT4kDmcmx/yyDaCUsLKUzHvmZ/6mWLLU2EESwVX9
# bpHFu7FMCEue1EIGbxsY1TbqZK7O/fUF5uJm0A4FIayxEQYjGeT7BTRE6giunUln
# EYuC5a1ahqdm/TMDAd6ZJflxbumcXQJMYDzPAo8B/XLukvGnEt5CEk3sqSbldwKs
# DlcMCdFhniaI/MiyTdtk8EWfusE/VKPYdgKVbGqNyiJc9gwE4yn6S7Ac0zd0hNkd
# Zqs0c48efXxeltY9GbCX6oxQkW2vV4Z+EDcdaxoU3wIDAQABo4IBKTCCASUwDgYD
# VR0PAQH/BAQDAgGGMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFOoWxmnn
# 48tXRTkzpPBAvtDDvWWWMB8GA1UdIwQYMBaAFK5sBaOTE+Ki5+LXHNbH8H/IZ1Og
# MD4GCCsGAQUFBwEBBDIwMDAuBggrBgEFBQcwAYYiaHR0cDovL29jc3AyLmdsb2Jh
# bHNpZ24uY29tL3Jvb3RyNjA2BgNVHR8ELzAtMCugKaAnhiVodHRwOi8vY3JsLmds
# b2JhbHNpZ24uY29tL3Jvb3QtcjYuY3JsMEcGA1UdIARAMD4wPAYEVR0gADA0MDIG
# CCsGAQUFBwIBFiZodHRwczovL3d3dy5nbG9iYWxzaWduLmNvbS9yZXBvc2l0b3J5
# LzANBgkqhkiG9w0BAQwFAAOCAgEAf+KI2VdnK0JfgacJC7rEuygYVtZMv9sbB3DG
# +wsJrQA6YDMfOcYWaxlASSUIHuSb99akDY8elvKGohfeQb9P4byrze7AI4zGhf5L
# FST5GETsH8KkrNCyz+zCVmUdvX/23oLIt59h07VGSJiXAmd6FpVK22LG0LMCzDRI
# RVXd7OlKn14U7XIQcXZw0g+W8+o3V5SRGK/cjZk4GVjCqaF+om4VJuq0+X8q5+dI
# ZGkv0pqhcvb3JEt0Wn1yhjWzAlcfi5z8u6xM3vreU0yD/RKxtklVT3WdrG9KyC5q
# ucqIwxIwTrIIc59eodaZzul9S5YszBZrGM3kWTeGCSziRdayzW6CdaXajR63Wy+I
# Lj198fKRMAWcznt8oMWsr1EG8BHHHTDFUVZg6HyVPSLj1QokUyeXgPpIiScseeI8
# 5Zse46qEgok+wEr1If5iEO0dMPz2zOpIJ3yLdUJ/a8vzpWuVHwRYNAqJ7YJQ5NF7
# qMnmvkiqK1XZjbclIA4bUaDUY6qD6mxyYUrJ+kPExlfFnbY8sIuwuRwx773vFNgU
# QGwgHcIt6AvGjW2MtnHtUiH+PvafnzkarqzSL3ogsfSsqh3iLRSd+pZqHcY8yvPZ
# HL9TTaRHWXyVxENB+SXiLBB+gfkNlKd98rUJ9dhgckBQlSDUQ0S++qCV5yBZtnjG
# pGqqIpswggZoMIIEUKADAgECAhABSJA9woq8p6EZTQwcV7gpMA0GCSqGSIb3DQEB
# CwUAMFsxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMTEw
# LwYDVQQDEyhHbG9iYWxTaWduIFRpbWVzdGFtcGluZyBDQSAtIFNIQTM4NCAtIEc0
# MB4XDTIyMDQwNjA3NDE1OFoXDTMzMDUwODA3NDE1OFowYzELMAkGA1UEBhMCQkUx
# GTAXBgNVBAoMEEdsb2JhbFNpZ24gbnYtc2ExOTA3BgNVBAMMMEdsb2JhbHNpZ24g
# VFNBIGZvciBNUyBBdXRoZW50aWNvZGUgQWR2YW5jZWQgLSBHNDCCAaIwDQYJKoZI
# hvcNAQEBBQADggGPADCCAYoCggGBAMLJ3AO2G1D6Kg3onKQh2yinHfWAtRJ0I/5e
# L8MaXZayIBkZUF92IyY1xiHslO+1ojrFkIGbIe8LJ6TjF2Q72pPUVi8811j5bazA
# L5B4I0nA+MGPcBPUa98miFp2e0j34aSm7wsa8yVUD4CeIxISE9Gw9wLjKw3/QD4A
# QkPeGu9M9Iep8p480Abn4mPS60xb3V1YlNPlpTkoqgdediMw/Px/mA3FZW0b1XRF
# OkawohZ13qLCKnB8tna82Ruuul2c9oeVzqqo4rWjsZNuQKWbEIh2Fk40ofye8eEa
# VNHIJFeUdq3Cx+yjo5Z14sYoawIF6Eu5teBSK3gBjCoxLEzoBeVvnw+EJi5obPrL
# TRl8GMH/ahqpy76jdfjpyBiyzN0vQUAgHM+ICxfJsIpDy+Jrk1HxEb5CvPhR8toA
# Ar4IGCgFJ8TcO113KR4Z1EEqZn20UnNcQqWQ043Fo6o3znMBlCQZQkPRlI9Lft3L
# bbwbTnv5qgsiS0mASXAbLU/eNGA+vQIDAQABo4IBnjCCAZowDgYDVR0PAQH/BAQD
# AgeAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMB0GA1UdDgQWBBRba3v0cHQIwQ0q
# yO/xxLlA0krG/TBMBgNVHSAERTBDMEEGCSsGAQQBoDIBHjA0MDIGCCsGAQUFBwIB
# FiZodHRwczovL3d3dy5nbG9iYWxzaWduLmNvbS9yZXBvc2l0b3J5LzAMBgNVHRMB
# Af8EAjAAMIGQBggrBgEFBQcBAQSBgzCBgDA5BggrBgEFBQcwAYYtaHR0cDovL29j
# c3AuZ2xvYmFsc2lnbi5jb20vY2EvZ3N0c2FjYXNoYTM4NGc0MEMGCCsGAQUFBzAC
# hjdodHRwOi8vc2VjdXJlLmdsb2JhbHNpZ24uY29tL2NhY2VydC9nc3RzYWNhc2hh
# Mzg0ZzQuY3J0MB8GA1UdIwQYMBaAFOoWxmnn48tXRTkzpPBAvtDDvWWWMEEGA1Ud
# HwQ6MDgwNqA0oDKGMGh0dHA6Ly9jcmwuZ2xvYmFsc2lnbi5jb20vY2EvZ3N0c2Fj
# YXNoYTM4NGc0LmNybDANBgkqhkiG9w0BAQsFAAOCAgEALms+j3+wsGDZ8Z2E3JW2
# 318NvyRR4xoGqlUEy2HB72Vxrgv9lCRXAMfk9gy8GJV9LxlqYDOmvtAIVVYEtuP+
# HrvlEHZUO6tcIV4qNU1Gy6ZMugRAYGAs29P2nd7KMhAMeLC7VsUHS3C8pw+rcryN
# y+vuwUxr2fqYoXQ+6ajIeXx2d0j9z+PwDcHpw5LgBwwTLz9rfzXZ1bfub3xYwPE/
# DBmyAqNJTJwEw/C0l6fgTWolujQWYmbIeLxpc6pfcqI1WB4m678yFKoSeuv0lmt/
# cqzqpzkIMwE2PmEkfhGdER52IlTjQLsuhgx2nmnSxBw9oguMiAQDVN7pGxf+LCue
# 2dZbIjj8ZECGzRd/4amfub+SQahvJmr0DyiwQJGQL062dlC8TSPZf09rkymnbOfQ
# MD6pkx/CUCs5xbL4TSck0f122L75k/SpVArVdljRPJ7qGugkxPs28S9Z05LD7Mtg
# Uh4cRiUI/37Zk64UlaiGigcuVItzTDcVOFBWh/FPrhyPyaFsLwv8uxxvLb2qtuto
# I/DtlCcUY8us9GeKLIHTFBIYAT+Eeq7sR2A/aFiZyUrCoZkVBcKt3qLv16dVfLyE
# G02Uu45KhUTZgT2qoyVVX6RrzTZsAPn/ct5a7P/JoEGWGkBqhZEcr3VjqMtaM7WU
# M36yjQ9zvof8rzpzH3sg23IwggZ1MIIE3aADAgECAhA1nosluv9RC3xO0e22wmkk
# MA0GCSqGSIb3DQEBDAUAMFQxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdv
# IExpbWl0ZWQxKzApBgNVBAMTIlNlY3RpZ28gUHVibGljIENvZGUgU2lnbmluZyBD
# QSBSMzYwHhcNMjIwMTI3MDAwMDAwWhcNMjUwMTI2MjM1OTU5WjBSMQswCQYDVQQG
# EwJVUzERMA8GA1UECAwITWljaGlnYW4xFzAVBgNVBAoMDkFuZHJldyBSYXRoYnVu
# MRcwFQYDVQQDDA5BbmRyZXcgUmF0aGJ1bjCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBALe0CgT89ev6jRIhHdrp9cdPnRoF5AV3wQdWzNG8JiY4dpN1YVwG
# Llw8aBosm0NIRz2/y/kriL+Jdu/FFakJdpB8l/J+mesliYhN+zj9vFviBjrElMAS
# EBS9DXKaUFuqZMGiC6k6yASGfyqF121OkLZ2JImy4a0C43Pd74dbf+/Ae4QHj66o
# tahUBL++7ayba/TJebhRdEq0wFiaxYsZOt18c3LLfAw0fniHfMBZXXJAQhgu1xfg
# pw7OE4N/M5or5VDVQ4ovtSFDVRzRARIF4ibZZqB76Rp5MuI0pMCs74TPN6WdlzGT
# DBu4pTS064iGx5hlP+GB5s/w/YW1BDigFV6yaERsbet9G2lsMmNwZtI6zUuGd9HE
# td5isz/9ENhLcFoaJE7/KK8CL5jt8i9I3Lx+5EOgEwm65eHm45bq63AVKvSHrjis
# uxX89jWTeslKMM/rpw8GMrNBxo9DZvDS4+kCloFKARiwKHJIKpNWUT3T8Kw6Q/ay
# xUt7TKp+cqh0U9YoXLbXIYMpLa5KfOsf21SqfSrhJ+rSEPEBM11uX41T/mQD5sAr
# N9AIPQxp6X7qLckzClylAQgzF2OVHEEi5m2kmb0lvfMOMGQ3BgwQHCRcd65wugzC
# Iipb5KBTq+HJLgRWFwYGraxcfsLkkwBY1ssKPaVpAgMDmlWJo6hDoYR9AgMBAAGj
# ggHDMIIBvzAfBgNVHSMEGDAWgBQPKssghyi47G9IritUpimqF6TNDDAdBgNVHQ4E
# FgQUUwhn1KEy//RT4cMg1UJfMUX5lBcwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB
# /wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUHAwMwEQYJYIZIAYb4QgEBBAQDAgQQMEoG
# A1UdIARDMEEwNQYMKwYBBAGyMQECAQMCMCUwIwYIKwYBBQUHAgEWF2h0dHBzOi8v
# c2VjdGlnby5jb20vQ1BTMAgGBmeBDAEEATBJBgNVHR8EQjBAMD6gPKA6hjhodHRw
# Oi8vY3JsLnNlY3RpZ28uY29tL1NlY3RpZ29QdWJsaWNDb2RlU2lnbmluZ0NBUjM2
# LmNybDB5BggrBgEFBQcBAQRtMGswRAYIKwYBBQUHMAKGOGh0dHA6Ly9jcnQuc2Vj
# dGlnby5jb20vU2VjdGlnb1B1YmxpY0NvZGVTaWduaW5nQ0FSMzYuY3J0MCMGCCsG
# AQUFBzABhhdodHRwOi8vb2NzcC5zZWN0aWdvLmNvbTAlBgNVHREEHjAcgRphbmRy
# ZXcuZC5yYXRoYnVuQGdtYWlsLmNvbTANBgkqhkiG9w0BAQwFAAOCAYEATPy2wx+J
# fB71i+UCYCOjFFBqrA4kCxsHv3ihLjF4N3g8jb7A156vBangR3BDPQ6lF0YCPwEF
# E9MQzqG7OgkUauX0vfPeuVe8cEadUFlrmb6xCmXsxKdGXObaITeGABz97AzLKxgx
# Rf7xCEKsAzvbuaK3lvb3Me9jtRVn9Q69sBTE5I/IDf2PoG/tO/ibPYXC1KpilBNT
# 0A28xMtQ1ijTS0dnbOyTMaUBCZUrNR/9qY2sOBhvxuvSouWjuEazDLTCs6zsMBQH
# 9vfrLoNlvEXI5YO9Ck19kT9pZ2rGFO7y8ySRmoVpZvHI29Z4bXBtGUGb2g/RRppi
# d5anuRtN+Skr7S1wdrNlhBIYErmCUPH2RPMphN2wmUy6IsDpdTPJkPTmU83q3tpO
# BGwvyTdxhiPIurZMXSDXfUyGB2iiXoyUHP2caVUmsarEb3BgCEf0PT2rO971WCDn
# G0mMgle2Yur4z3eWEsKUoPdFAoiizb7CddijTOsNvxYNf0XEg5Ek1gTSMYIGUTCC
# Bk0CAQEwaDBUMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVk
# MSswKQYDVQQDEyJTZWN0aWdvIFB1YmxpYyBDb2RlIFNpZ25pbmcgQ0EgUjM2AhA1
# nosluv9RC3xO0e22wmkkMA0GCWCGSAFlAwQCAQUAoEwwGQYJKoZIhvcNAQkDMQwG
# CisGAQQBgjcCAQQwLwYJKoZIhvcNAQkEMSIEILAf70YEMggc5Ah9jbbeLF/aTKf+
# 16MjryuVQMZhq+pnMA0GCSqGSIb3DQEBAQUABIICAAStdCXHXu1eiAdNeuv5PN2P
# l7gi7S57ggEHLiIx/iQuK1HSTzc3PTmMMXhIMWShLMuq6y/Dy/B3CoAuq16/f9HS
# t07FtMp/LlJe34c2AFkMOdzRNr6giSXlKYueFvVumLm0vY7cVhN4o8lZPbd8RopJ
# e9kS98SIuRClwfOyjvfjDzf4EPlR1dBKOF02xyhbRMYQQi4BaVI7NcM/qElT2TYj
# GEBA9rQAlS0hLBu9w8963BwEDkU17hEi+iMQ4robnb5/VaMxgtQLFeTbA0FPGdJG
# 6S29fQpETTHRm4MhCr3j02YuE3D5O9Rv8XxEDooCVofnogqasq+mBZzhVFPEKWsO
# svWezHiSJc3xKbNIdiqRQZaD4qPsBdTQZXvx/IiFcI1xURCklueL1mCLlM1sJHs1
# My69UqFH0pmiGsnVlEUTAhxjypcO17xnvvuFbtDDyf6WJRW4gAw5n7EAEg0D88jW
# zHoLa8ZH95ykz/GMv+K3mKn7Bi3YuCvrRlXjZBLcshPVM1ewxJikdHkzO0AeRNPM
# Q1gFMKdlD6pooY3aUUEN4ZXETqEO8QnztRDmID2YKc8WS6zjobKJ9Q610gRoYJN2
# +q7soN5kQpRDSP+R+5ODTjjObaqf0UI2z2rrBS47T5iemQPa0zJIpqaQwQotkxxH
# D7aQOR1A71d2tCsPto4coYIDbDCCA2gGCSqGSIb3DQEJBjGCA1kwggNVAgEBMG8w
# WzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExMTAvBgNV
# BAMTKEdsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gU0hBMzg0IC0gRzQCEAFI
# kD3CirynoRlNDBxXuCkwCwYJYIZIAWUDBAIBoIIBPTAYBgkqhkiG9w0BCQMxCwYJ
# KoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yMzA2MTcxNDM2MTJaMCsGCSqGSIb3
# DQEJNDEeMBwwCwYJYIZIAWUDBAIBoQ0GCSqGSIb3DQEBCwUAMC8GCSqGSIb3DQEJ
# BDEiBCDR5ETxwwGoUnSBfggzVTJp51MkoBk6VQ0S8Zr7m0+oFDCBpAYLKoZIhvcN
# AQkQAgwxgZQwgZEwgY4wgYsEFDEDDhdqpFkuqyyLregymfy1WF3PMHMwX6RdMFsx
# CzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMTEwLwYDVQQD
# EyhHbG9iYWxTaWduIFRpbWVzdGFtcGluZyBDQSAtIFNIQTM4NCAtIEc0AhABSJA9
# woq8p6EZTQwcV7gpMA0GCSqGSIb3DQEBCwUABIIBgLN4e0zd0pR+Mj/LdLSCzRb6
# S5TTZsklyjpHfwbkwpLCZZvR1P/369j2p5ConMdSuFC9wPD3YnE8SPzSgjVuiTGc
# mdDCUqcI8LyW7pWWHz+1pdLudzzQRHwivmd5JZ0MVvqANPCT/5tTr7Y7BA6oJFPa
# aY2FcBgv6Kb2D+xmNkk6RW3oVMOwjKOWKkzyqoGwWRZGOChHTtuQKp7UMpEp13l5
# XPwSF4/FNh0UIhULTBMAr2lBTKhWxt7SvPVqGXYyVx4xkF3yeD3DpSGDkp6/ANxL
# H4V4sSBznuEu/KSaoPbQMOobhNpmVHa9hloUCvkTnfKdjqkVjBjwHAuIDd89wfbL
# T40B1g0mrwSgHeuGdO6lyzZ+Sdy7FWYsOkfi2l21s/gueyeb5zWOgyfNbPPDfSaJ
# xQalyWJLJB7UgTUwCXARWvopDasu8H9H6DMBvu75a9a7Md7ifQdrZcPVEimSDdBr
# hnjy7W0k3vUQ1+sDS21J5s8a19D+qBOB7EpvFg6Dtg==
# SIG # End signature block
