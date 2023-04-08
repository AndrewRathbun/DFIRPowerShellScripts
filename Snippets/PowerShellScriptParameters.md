# PowerShell Script Parameters

## Code Snippet

```PowerShell  
param
(
	[Parameter(Mandatory = $true,
			   Position = 1,
			   HelpMessage = 'Please specify the folder that...')]
	[String]$variableName1,
	[Parameter(Mandatory = $true,
			   Position = 2,
			   HelpMessage = 'Please specify the output directory for...')]
	[String]$variableName2,
	[Parameter(Mandatory = $true,
			   Position = 3,
			   HelpMessage = 'Choose the number of...')]
	[ValidateRange(1, 10)]
	[String]$variableName3 = '3'
)
```  
  
## Credit

Special thank you to PowerShell Studio by SAPIEN Technologies for teaching me about script parameters and how to structure them with effective help messages, positioning, etc. 
