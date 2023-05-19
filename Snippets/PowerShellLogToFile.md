# PowerShell Logging

## Code Snippet

```PowerShell  
# Set the location for the log file in a variable
$logFile = "$PSScriptRoot\NameOfLog.log"

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

# Example logging message to use instead of Write-Host
Log -logFile $logFile -msg "This is an example message that will be written to the log AND to the console" -level "Info"
```  
  
## Credit

Special thank you to all the smart people on the internet from whom I've borrowed multiple pieces of code to put together the above that works very well for my purposes. 
