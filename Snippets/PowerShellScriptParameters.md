# PowerShell Script Parameters

## Code Snippet

```PowerShell  
param
(
	[Parameter(Mandatory = $true,
			   Position = 1,
			   HelpMessage = 'Please specify a valid Windows folder path')]
	[ValidatePattern('^([a-zA-Z]:\\)([^\\/:*?<>"|]+\\)*[^\\/:*?<>"|\s]+$')]
	[String]$path,
	[Parameter(Mandatory = $true,
			   Position = 2,
			   HelpMessage = 'This is a parameter that is looking for a case non-specific set of values, and nothing else')]
	[ValidateSet('thing1', 'thing2', 'thing3', 'thing4', IgnoreCase = $true)]
	[String]$SetOfValues,
	[Parameter(Mandatory = $true,
			   Position = 3,
			   HelpMessage = 'This is an example of a parameter that needs a number between 1 and 10')]
	[ValidateRange(1, 10)]
	[int]$Number = '3',
	[Parameter(Position = 4,
			   HelpMessage = 'This parameter is looking for only a positive integer')]
	[ValidateRange("Positive")]
	[int]$PositiveNumberOnly,
	[string]$NotMandatoryOrPositional # This parameter is not mandatory or positional, compared to the rest of the parameters
)
```  
  
## Credit

Special thank you to PowerShell Studio by SAPIEN Technologies for teaching me about script parameters and how to structure them with effective help messages, positioning, etc. 
