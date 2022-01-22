<#
	.SYNOPSIS
		Searches for the $J and $MFT and then parses them together with MFTECmd to generate data within the ParentPath column in the CSV output.
	
	.DESCRIPTION
		$J + $MFT = more verbose and useful $J CSV output with MFTECmd!
	
	.PARAMETER TargetsFolder
		Please specify a folder that contains a $J and $MFT to be parsed by MFTECmd
	
	.PARAMETER OutputFolder
		Please specify where you want the parsed $J and $MFT CSV output to go
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2022 v5.8.198
		Created on:   	20220117 @ 1945 UTC
		Created by:   	Andrew Rathbun
		===========================================================================
#>
param
(
	[Parameter(Mandatory = $true,
			   Position = 1)]
	[String]$TargetsFolder,
	[Parameter(Mandatory = $true,
			   Position = 2)]
	[String]$OutputFolder
)

if (!(Test-Path -Path $OutputFolder))
{
	New-Item -Path $OutputFolder -ItemType "directory" | Out-Null
	while (!(Test-Path -Path $OutputFolder))
	{
		Start-Sleep -Milliseconds 100
	}
}

$MFT = Get-ChildItem -Recurse -Path $TargetsFolder -Include '$MFT'
$J = Get-ChildItem -Recurse -Path $TargetsFolder -Include '$J'
$MFTECmd = 'C:\Path\To\MFTECmd.exe' # Paste the file path to MFTECmd.exe here

Start-Process -FilePath $MFTECmd -ArgumentList "-f $J -m $MFT --csv $OutputFolder"
