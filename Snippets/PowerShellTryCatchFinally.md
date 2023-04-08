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
  
## Credit

Special thank you to ChatGPT for teaching me about proper error handling as well as all the smart people on the internet in my search results helping me piece together and understand the concepts in this snippet. 
