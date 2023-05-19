# PowerShell Try/Catch/Finally

## Code Snippet

```PowerShell  
function Name-Function
{
	[CmdletBinding()]
	param ()
	
	try
	{
		# script goes here
	}
	catch [System.Exception]
	{
		Write-Error "An error occurred while running Name-Function"
		Write-Error "Exception type: $($_.Exception.GetType().FullName)"
		Write-Error "Exception message: $($_.Exception.Message)"
	}
	finally
	{
		Write-Verbose "Finished running Name-Function"
	}
}
```  
For the end of a script when calling functions using the Logging snippet:

```PowerShell
try
{
	# Code block to be executed within the try block
	# ...
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
	Log -logFile $logFile -msg "----- End of Session -----" -level "Info"
}
```

## Credit

Special thank you to ChatGPT for teaching me about proper error handling as well as all the smart people on the internet in my search results helping me piece together and understand the concepts in this snippet. 
