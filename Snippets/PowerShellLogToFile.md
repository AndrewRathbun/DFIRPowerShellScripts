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

<#
    .SYNOPSIS
        Function used to make logging easier. Will append a message to the given log files
    
    .PARAMETER logFile
        Log file to append to
    
    .PARAMETER msg
        Message to append to log
    
    .PARAMETER level
        The level of the log message (Info, Warning, Error)
    
    .EXAMPLE
        PS C:\> Log -logFile $logFile -msg "insert message here" -level "Info"
#>
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
    
    $msg = Write-Output "$(Get-TimeStamp) | $level | $msg"
    Out-File $logFile -Append -InputObject $msg -encoding ASCII
    Write-Host $msg
}

# Example logging message to use instead of Write-Host
Log -logFile $logFile -msg "This is an example message that will be written to the log AND to the console" -level "Info"
```  
  
## Credit

Special thank you to all the smart people on the internet from whom I've borrowed multiple pieces of code to put together the above that works very well for my purposes. 
