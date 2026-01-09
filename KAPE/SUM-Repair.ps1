<#
    .SYNOPSIS
        SUM Repair Script for all files in the SUM folder and run SumECmd.exe
    
    .DESCRIPTION
        Follow steps to repair the SUM so you can run SumECmd.exe again.
        https://svch0st.medium.com/windows-user-access-logs-ual-9580f1100635
    
    .PARAMETER TargetPath
        Specifies the path to KAPE tout folder where the SUM folder is located
    
    .PARAMETER OutputPath
        Specifies the path for the working copy of the SUM and SumECmd.exe Output
    
    .PARAMETER Kape
        Switch parameter, used if the script is being run inside KAPE as a Module. This means this script will utilize the SumECmd binary that resides within .\KAPE\Modules\bin
    
    .PARAMETER SUMECmd
        Please specify where the SumECmd binary resides.
    
    .EXAMPLE
        PS> .\SUM-Repair.ps1 -TargetPath C:\Test\tout
        -OutputPath C:\Test\workingCopySUM
    
    .NOTES
        ===========================================================================
        Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2022 v5.8.201
        Created on:   	3/7/2022 15:06 PM
        Created by:   	Matthew Arbaugh
        ===========================================================================
#>
param
(
	[Parameter(Mandatory = $true,
			   Position = 1,
			   HelpMessage = 'Specifies the path to KAPE tout folder where the SUM folder is located')]
	[String]$TargetPath,
	[Parameter(Mandatory = $true,
			   Position = 2,
			   HelpMessage = 'Specifies the path for the working copy of the SUM folder and SumECmd.exe Output')]
	[String]$OutputPath,
	[Parameter(HelpMessage = 'Switch parameter, used if the script is being run inside KAPE as a Module. This means this script will utilize the SumECmd binary that resides within .\KAPE\Modules\bin')]
	[switch]$Kape,
	[Parameter(HelpMessage = 'Please specify where the SumECmd binary resides.')]
	[String]$SUMECmd = $(
		if ($Kape)
		{
			# If being used as a KAPE module, $PSScriptRoot is .\KAPE\Modules\bin
			(Get-ChildItem -Recurse -Path $PSScriptRoot -Include 'SumECmd.exe').FullName
		}
		else
		{
			# Get path to SumECmd.exe as user input
			Read-Host -Prompt "Enter full path to the executable SumECmd.exe"
		}
	)
)

# If SumECmd.exe is not set, exit
if ([string]::IsNullOrEmpty($SUMECmd))
{
	Write-Host "SUMECmd is not specificed or not found, exiting"
	Exit
}

# Check the path for the SumECmd.exe is valid
else
{
	if (Test-Path  $SUMECmd -PathType Leaf)
	{
		Write-Host "SUMECmd set to," $SUMECmd
	}
	else
	{
		Write-Host $SUMECmd" is NOT a valid path to SumECmd.exe, exiting"
		Exit
	}
}

$workingSUM = $OutputPath

if (Test-Path $workingSUM)
{
	Write-Host (Get-Date).ToString() "| Output folder already Exists"
}
else
{
	New-Item $workingSUM -ItemType Directory | Out-Null
	Write-Host (Get-Date).ToString() "| Output folder Created successfully: $workingSUM "
}

$sourceSUMFolder = Get-ChildItem -Path $TargetPath -filter "SUM" -Directory -Recurse | ForEach-Object { $_.fullname }

# Make a copy of the files within the SUM directory
Write-Host (Get-Date).ToString() "| Copying source files from $TargetPath to $workingSUM"
Copy-Item -Path $sourceSUMFolder\* -Destination $workingSUM

# Undo Read Only attributes to folder and all files therein
Write-Host (Get-Date).ToString() "| Undoing Read Only attributes to all files in $workingSUM"
$Folder = Get-Item -Path $workingSUM
$Folder.Attributes = $Folder.Attributes -band -bnot [System.IO.FileAttributes]::ReadOnly
Get-ChildItem $workingSUM -Recurse | ForEach-Object {
	Write-Host (Get-Date).ToString() "| Undo Read Only attributes for $workingSUM\$_"
	Set-ItemProperty -Path $workingSUM\$_ -Name IsReadOnly -Value $False
}

# Execute this command esentutl.exe /p Current.mdb
Write-Host (Get-Date).ToString() "| Running esentutl.exe -argumentlist /p $workingSUM\Current.mdb /o -PassThru"
$currentProg = Start-Process -NoNewWindow "esentutl.exe" -argumentlist "/p $workingSUM\Current.mdb /o" -PassThru
$count = 0
$window = $false
$wshell = New-Object -ComObject wscript.shell;

# Send ok button press to 'Warning' pop up window
while ($count -lt 30 -and $window -eq $false)
{
	$window = $wshell.AppActivate('Warning')
	Start-Sleep 1
	$count++
}
$wshell.SendKeys('~')

# Wait for the esentutl.exe /p Current.mdb command to complete
do { Start-Sleep 1 }
while (Get-Process -Id $currentProg.Id -Ea SilentlyContinue)

# Execute this command esentutl.exe /p SystemIdentity.mdb
Write-Host (Get-Date).ToString() "| Running esentutl.exe -argumentlist /p $workingSUM\SystemIdentity.mdb /o -PassThru"
$siProg = Start-Process -NoNewWindow "esentutl.exe" -argumentlist "/p $workingSUM\SystemIdentity.mdb /o" -PassThru
$count = 0
$window = $false
$wshell = New-Object -ComObject wscript.shell;

# Send ok button press to 'Warning' pop up window
while ($count -lt 30 -and $window -eq $false)
{
	$window = $wshell.AppActivate('Warning')
	Start-Sleep 1
	$count++
}
$wshell.SendKeys('~')

# Wait for the esentutl.exe /p SystemIdentity.mdb command to complete
do { Start-Sleep 1 }
while (Get-Process -Id $siProg.Id -Ea SilentlyContinue)

# For each file found
Get-ChildItem | Where-Object { $_.Name -match '^(\{[-A-Z0-9]+?\})\.mdb' } | ForEach-Object{
	# Execute this command esentutl.exe /p "{<GUID>}.mdb"
	Write-Host (Get-Date).ToString() "| Running esentutl.exe -argumentlist /p $workingSUM\$_ /o -PassThru"
	$Prog = Start-Process -NoNewWindow "esentutl.exe" -argumentlist "/p $workingSUM\$_ /o" -PassThru
	$count = 0
	$window = $false
	$wshell = New-Object -ComObject wscript.shell;
	
	# Send ok button press to 'Warning' pop up window
	while ($count -lt 30 -and $window -eq $false)
	{
		$window = $wshell.AppActivate('Warning')
		Start-Sleep 1
		$count++
	}
	$wshell.SendKeys('~')
	
	# Wait for the esentutl.exe /p {<GUID>}.mdb command to complete
	do { Start-Sleep 1 }
	while (Get-Process -Id $Prog.Id -Ea SilentlyContinue)
}

# Try running SumECmd again against the location where these repaired files reside
Write-Host (Get-Date).ToString() "| $SUMECmd -argumentlist -d $workingSUM --csv $workingSUM --debug"
Start-Process -NoNewWindow $SUMECmd -argumentlist "-d $workingSUM --csv $workingSUM --debug"

# SIG # Begin signature block
# MIIviwYJKoZIhvcNAQcCoIIvfDCCL3gCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDsJWtiMWtHOHkd
# U4H8jIm/PqDn9kP0icTs+qk+2vPscaCCKJAwggQyMIIDGqADAgECAgEBMA0GCSqG
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
# pGqqIpswggZuMIIE1qADAgECAhAhqkhIHhrn6JmTDAPnG+yGMA0GCSqGSIb3DQEB
# DAUAMFQxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxKzAp
# BgNVBAMTIlNlY3RpZ28gUHVibGljIENvZGUgU2lnbmluZyBDQSBSMzYwHhcNMjUw
# MTI3MDAwMDAwWhcNMjgwMTI3MjM1OTU5WjBeMQswCQYDVQQGEwJVUzERMA8GA1UE
# CAwITWljaGlnYW4xHTAbBgNVBAoMFEFuZHJldyBEYXZpZCBSYXRoYnVuMR0wGwYD
# VQQDDBRBbmRyZXcgRGF2aWQgUmF0aGJ1bjCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBAMkJu/RzsqNXey1TrbKBHF4iHKDxJ0O94mWuaZpEQsGr0nWz+/Kv
# +TMBbsDxne/TAIY6TGAnS8ul62tD9lTJ8itMKoUkRF2MNHiHe1UJvbtTMf0i0Yc8
# mvk7E65pzCD9jhfPCxmF4sE/egwPfCvWwH222I128N3dIpZbkMo7XN5JVRRKpnxz
# zvACfEF4zpxKFBrTDa9cO4ncP4Q+vY1lPOeEeXJPaKUkA3KcxIjddZSK4P+zs7ma
# 1R9kk6J80SUdOhgutNKR0wPFKRcUS5h+b4F41RlE6ywz886Ab43D77q5ziyDJvDU
# lYLBzZJCAr9WMPKV04sYbIa0AB2wqWEfXT/8xTCWSmVb4uL7J3YKmiXzCJZAgNas
# dRjs6iMOu8uPNNaujduzzRPf/auQod3ZD3aje0YMMP2W1GFylWMIxAN9IyHjooxZ
# EJklEu2qDWHEVhVtwDwQRsnH980W7gDTEPSdAHe7eQ+svVqWwFvaKPt12k73PkXI
# toy5HAROPUe5tfdiWXcVKRM1qUwWnVUfXGI5HtJmqxrfOl4wVOR0S6D1LliI2cVA
# jEJ1fygAsVPgXEo5bfploZQvUZzF3akTAvKdkc5faUIoBuO3WnNMbO3y8f+bt9Th
# aFQ5z6qTH6p1EVqN4w9O3t9yMIHsnUrDEdg9yqhxiEbkaepQa92x9mE5AgMBAAGj
# ggGwMIIBrDAfBgNVHSMEGDAWgBQPKssghyi47G9IritUpimqF6TNDDAdBgNVHQ4E
# FgQUp8BNwU9LtpBX3khU8nN8LWZ3lRQwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB
# /wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUHAwMwSgYDVR0gBEMwQTA1BgwrBgEEAbIx
# AQIBAwIwJTAjBggrBgEFBQcCARYXaHR0cHM6Ly9zZWN0aWdvLmNvbS9DUFMwCAYG
# Z4EMAQQBMEkGA1UdHwRCMEAwPqA8oDqGOGh0dHA6Ly9jcmwuc2VjdGlnby5jb20v
# U2VjdGlnb1B1YmxpY0NvZGVTaWduaW5nQ0FSMzYuY3JsMHkGCCsGAQUFBwEBBG0w
# azBEBggrBgEFBQcwAoY4aHR0cDovL2NydC5zZWN0aWdvLmNvbS9TZWN0aWdvUHVi
# bGljQ29kZVNpZ25pbmdDQVIzNi5jcnQwIwYIKwYBBQUHMAGGF2h0dHA6Ly9vY3Nw
# LnNlY3RpZ28uY29tMCUGA1UdEQQeMByBGmFuZHJldy5kLnJhdGhidW5AZ21haWwu
# Y29tMA0GCSqGSIb3DQEBDAUAA4IBgQAGC/+y/bEbicUcdL3NSNIqMeeBamW5efm0
# X8b8uj+M4ZoXi+lbdpCeNtGkPbzjmgCodiUSbZXIbkxQNlRtGW/7NxXAlIwqbwJn
# wq06tov/sckJszOk0d4x4kZz4IFZR8xiu7o4eobsEE2bIv/FP5yGqEEUbCsOuT5G
# bGFJnultBF68vNpeTb5CoJ4n2RT4SJapc6m7KIMZqzFyFm+v70Zv812P7VukTqVp
# Yh9jRW90bq76x75XllrN/iPSSbzvfksn83Cb8M9SDckIjpwIhgJTYKi/NYDUjnqu
# OJryMdfozz3h5p1jcAkKb3mfWJgXtQ3HZ2DB9vIPoKVgA3Q7l4YlJT7lXWC35IuI
# U6h3QlmpXEKr+UEVmPOUuBcyvoZ/p31NOY3uBbLoXUQuj+lv4srCVz1E7oGGPMGU
# X4QRuFiVZxFwySgpvuM1OAvnTN16DS/70SEKvM83oFROsHWcyd9DOwiWND1GPC+/
# OeUdiZ8p+jK/X0Hit1QHISPdN7ULX5IwggZvMIIEV6ADAgECAhABXMCK85u0U3OW
# iccagp0yMA0GCSqGSIb3DQEBDAUAMFsxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBH
# bG9iYWxTaWduIG52LXNhMTEwLwYDVQQDEyhHbG9iYWxTaWduIFRpbWVzdGFtcGlu
# ZyBDQSAtIFNIQTM4NCAtIEc0MB4XDTI1MDUxNTA4MzAwMFoXDTM0MTIxMDAwMDAw
# MFowajELMAkGA1UEBhMCQkUxGTAXBgNVBAoMEEdsb2JhbFNpZ24gbnYtc2ExQDA+
# BgNVBAMMN0dsb2JhbHNpZ24gVFNBIGZvciBNUyBBdXRoZW50aWNvZGUgQWR2YW5j
# ZWQgLSBHNCAtIDIwMjUwggGiMA0GCSqGSIb3DQEBAQUAA4IBjwAwggGKAoIBgQCP
# TxsZdPqLrp/G8sMHvYYd4KunisUzQa+FjoK2KfZH6lQ1UB7WvGZV1X8jJywqaZKN
# fQhHLFbxbA4rOu/naMSSqX5/TOXJd+FLJ+lE+9Q8hyF9FKJ353W3tPLC+O7KeAoA
# b80vt0uGRXs4NoQNG5dYMZHBif6IRUDdhZtufFTxWJr5cRIWbsRC24UAwbK5TQIo
# kg43huUPeXj2qKZukuasKQ5tUTCrUhmYR3IFpHkyVpdu+cdBcEPw4K9N53himASq
# RHej4nz/2gGsH6OvLFIpJawYbSwiV8m6DcpHVxT3plxDj9nCU88wTVgipzsda+pI
# 5vvhht42IG/n4e1BUY+fqph6EJM7bs3CSR6htAmDsn4esE7iMdQm/+mkVow2OnBz
# k8GLg2guEEENAWgh83OlWBGTvzwGmKaY+FI9maDrqvGnEuj8QzjbY3Kq38D4jsFg
# rQjiLAeI8z02gltITWqatYDqanYkrSny8k05oEHPHEZSAXA2+SiXVFPKfUw5xosC
# AwEAAaOCAZ4wggGaMA4GA1UdDwEB/wQEAwIHgDAWBgNVHSUBAf8EDDAKBggrBgEF
# BQcDCDAdBgNVHQ4EFgQU1zj7uMf7PJwuwEpTcZtKNo8+rbMwTAYDVR0gBEUwQzBB
# BgkrBgEEAaAyAR4wNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFsc2ln
# bi5jb20vcmVwb3NpdG9yeS8wDAYDVR0TAQH/BAIwADCBkAYIKwYBBQUHAQEEgYMw
# gYAwOQYIKwYBBQUHMAGGLWh0dHA6Ly9vY3NwLmdsb2JhbHNpZ24uY29tL2NhL2dz
# dHNhY2FzaGEzODRnNDBDBggrBgEFBQcwAoY3aHR0cDovL3NlY3VyZS5nbG9iYWxz
# aWduLmNvbS9jYWNlcnQvZ3N0c2FjYXNoYTM4NGc0LmNydDAfBgNVHSMEGDAWgBTq
# FsZp5+PLV0U5M6TwQL7Qw71lljBBBgNVHR8EOjA4MDagNKAyhjBodHRwOi8vY3Js
# Lmdsb2JhbHNpZ24uY29tL2NhL2dzdHNhY2FzaGEzODRnNC5jcmwwDQYJKoZIhvcN
# AQEMBQADggIBAArKwhvg0yjAbbXM8cNYCGjDhogTZTteS3WJ4Sn6m2aH9j023Z0m
# nqJtwEANLzxtIGfzwbnXTbTYZ7gWm9Hug6SNE7zitwSI3poJB1pcuOEl3DOzTQy2
# t/P5Nb3PwP+gLyk++Ic6zYmI34SfiKYeEG+UrMtdG4BiX5VouvUYrPZo+o52QA60
# ZF24+2cYgooB+CJolTUqXaCfjIdiDFm1Gn1oVi/FrTD+0qF6WRp4YXz4nF/rhdnh
# /PXp546gIK5mKcu8kt/kn69fG8mLjMiPF3VbJ5AmGPwE3G8v5hbLPQUWHZKpolFy
# ym8GDMh4cTS7fg0KBZreaFveo/by2ogbRwv0JZGarnRcgQl5E9UQbJ2otaj7J6Bv
# hoFz4zdL1BkhkIFcANlx/3iDLW6Sr9xwZ2e7z6XMU8TVbfdBod12ovzS6XooCOb0
# ma7kxlseO7wLgudYo50YAj3QZYctb7ZzLUplRz+XdETxJc5eYllIhBVxoBFku2e9
# +5ICKMnOSBoFBfqXnBIYUhQ2gYGO1kEkMuE0SIE63yHnQGvrTrMNc/vQfYPPOAEk
# hNrT+vym4dYBlaaLD0OOlg4RP01wuFVXzsfD4J3D1sAKYNFTAGa8IXonjCrvEZnu
# nef1+tjRwG+4XMwyLwrYvnu4IAxdj6OWZ59W4aNTjxkXBeiECM/cMkjnMYIGUTCC
# Bk0CAQEwaDBUMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVk
# MSswKQYDVQQDEyJTZWN0aWdvIFB1YmxpYyBDb2RlIFNpZ25pbmcgQ0EgUjM2AhAh
# qkhIHhrn6JmTDAPnG+yGMA0GCWCGSAFlAwQCAQUAoEwwGQYJKoZIhvcNAQkDMQwG
# CisGAQQBgjcCAQQwLwYJKoZIhvcNAQkEMSIEIG9PnaoYeDThmcCLOo24JJ0ZaZo+
# D1g3hSeuKjf+kcSOMA0GCSqGSIb3DQEBAQUABIICALhJ+NLVmyxKC8sr7kP+eNqa
# HcqTnDtAuAFIhuLPpHm6fOo+xwd4bLVTEOB502pk/KT5jQ1BR5fj0gUaxgDtX8/P
# Juz84kMnwI+EVtMY3OdU4arxT0Qj5cx1JGiLdT78AeEIUlkvTmhFe6JRTOt8Hj6V
# bSLwoPtpS/9OwQViRXlhgpc9rlRoYzTRj3MVY9yCPmxVx2HH9jWqy7PKjzRJh+wn
# rYh9ZiYX3HexuopFfL02iey9scVEUj5g1fIcOzfff/phK40OYr+IpvHQJMP2G4Lu
# a9sQn8QQj06IiOvgcQRTHTOpMuuPRCuAar7uTzR69EymK1qMe/ipjDfb7eunVkUp
# RvWqVvrqsVNnBhx1Fl3kaiJWM4YI//xYZS85nKpU5TvN6ueyXHA9t2i1YzRtjZtI
# lnlHsyXluAZNr3gimxnZZUKLn2qZdrjrSDRczKaR/hCI4oORA8GhlBEm8vnEVaH5
# N4xs3Ssa9dqqOMGqApHrvY7mArLEy3Ht154KLC0kRoWV2bucb8G4Pgs08a5oAD8o
# B8ZkJuaw4dZoFLV1vj95Kli75bvHrS7hxTPnx78s8q0on7MSIADU05iFl6y4Wk2e
# RuVEdS90bZmocSOl1hIt4vNJ0KHmuMPqa5MnO1npcfWxdmT65HQMEOWe0MoVi5k3
# ALkTTnDs0NR16mCS2avWoYIDbDCCA2gGCSqGSIb3DQEJBjGCA1kwggNVAgEBMG8w
# WzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExMTAvBgNV
# BAMTKEdsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gU0hBMzg0IC0gRzQCEAFc
# wIrzm7RTc5aJxxqCnTIwCwYJYIZIAWUDBAIBoIIBPTAYBgkqhkiG9w0BCQMxCwYJ
# KoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNjAxMDkxNjU5MDVaMCsGCSqGSIb3
# DQEJNDEeMBwwCwYJYIZIAWUDBAIBoQ0GCSqGSIb3DQEBCwUAMC8GCSqGSIb3DQEJ
# BDEiBCDy/mvL+TVpw3RKlfFqMWuV95Db13nGoh0COVXMgKPowDCBpAYLKoZIhvcN
# AQkQAgwxgZQwgZEwgY4wgYsEFHBf2oJUMvP1hyvtvyOsoCS6o1tVMHMwX6RdMFsx
# CzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMTEwLwYDVQQD
# EyhHbG9iYWxTaWduIFRpbWVzdGFtcGluZyBDQSAtIFNIQTM4NCAtIEc0AhABXMCK
# 85u0U3OWiccagp0yMA0GCSqGSIb3DQEBCwUABIIBgIryLzCZ7SX3vE1JnriI7hic
# 24TFb57oSkam6quEE+p2J54eyojeU0nmFJZBzD+0qwGqQYSVLPwobUu9X7t/b6oo
# rkRzRHJT7ImvCisvnSKtIRSVQhd6eaIQO7NkjVl0c91yyecN2nhtGsvmVOlCGDHr
# 4S/Vmu9VWZVR7TOGtRg+gnSBR0pmO9JiZ4BDbHoi6oqLgQ+Szl+fAodokgqf4PMc
# JFKMjy/fVxdgPudDCZcdJ1pFYmU+tgMDZK2iFRDwXLoa7U7VIAFn7m9Wl+F4xc+1
# bppwIJhYF/d/ePyDHvx62JRnBv4VaDdPA+bI605vFIyKJBZqKTlN0ZwWp2DDf1RK
# 6sTgyYwtsILt4VxPiKFAOk4U38s0VtYzby2Ig3IBp9l39G9xKDLkW2KZAeJlYIXB
# jQXhTWVYre3I75KPYXjvdXP6mWgG3yJOvn+c0RrhLIh5e56IP4PslCMmrSeOezhb
# lFkgAEOoFyGfhAwUMuUJNYz4AURA10DBfugpxHJb9g==
# SIG # End signature block
