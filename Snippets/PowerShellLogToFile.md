# PowerShell Logging

## Code Snippet

```PowerShell  
# Set the location for the log file in a variable
$logFilePath = "$PSScriptRoot\NameOfLog.log"

<#
    .SYNOPSIS
        Gets the current time in YYYY/MM/dd HH:mm:ss format
#>
function Get-TimeStamp
{
    return "[{0:yyyy/MM/dd} {0:HH:mm:ss}]" -f (Get-Date)
}

<#
    .SYNOPSIS
        Function used to make logging easier. Will append a message to the given log files
    
    .PARAMETER logFilePath
        Log file to append to
    
    .PARAMETER msg
        Message to append to log
    
    .EXAMPLE
        PS C:\> Log -logFilePath $logFilePath -msg "insert message here"
#>
function Log
{
    param
    (
        [Parameter(Mandatory = $true,
                   Position = 1,
                   HelpMessage = 'Please specify the log file to append to')]
        [string]$logFilePath,
        [Parameter(Mandatory = $true,
                   Position = 2,
                   HelpMessage = 'Please specify the message to write to host and the specified log file')]
        [string]$msg
    )
    
    $msg = Write-Output "$(Get-TimeStamp) | $msg"
    Out-File $logFilePath -Append -InputObject $msg -encoding ASCII
    Write-Host $msg
}

# Example logging message to use instead of Write-Host
Log -logFilePath $logFilePath -msg "This is an example message that will be written to the log AND to the console"
```  
  
## Credit

Special thank you to all the smart people on the internet from whom I've borrowed multiple pieces of code to put together the above that works very well for my purposes. 
