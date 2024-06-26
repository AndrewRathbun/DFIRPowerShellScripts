﻿<#
	.SYNOPSIS
		A useful script to help identify how many unique values exist in FirstInteracted and LastInteracted columns with SBECmd CSV output
	
	.DESCRIPTION
		A detailed description of the Count-SBECmdTimestampColumns.ps1 file.
	
	.PARAMETER path
		Provide a file path for SBECmd CSV output
	
	.EXAMPLE
		.\Count-SBECmdTimestampColumns.ps1 C:\temp\Andrew_UsrClass.csv
	
	.OUTPUTS
		Example output:
		
		This script combines either FirstInteracted or LastInteracted with the value of AbsolutePath for the purpose of calculating the total count within a respective CSV
		Total count of values in AbsolutePath column: 1612
		Number of unique values in AbsolutePath column: 1595
		Total count of values in FirstInteracted column: 973
		Number of unique values in FirstInteracted column: 960
		Total count of values in LastInteracted column: 637
		Number of unique values in LastInteracted column: 637
		Total unique values between both AbsolutePath and FirstInteracted/LastInteracted columns: 1273
		Total number of values between both AbsolutePath and FirstInteracted/LastInteracted columns: 1610
	
	.NOTES
		===========================================================================
		Created on:   	7/1/2024 14:10
		Created by:   	Andrew Rathbun
		===========================================================================
#>
param
(
	[Parameter(Mandatory = $true,
			   Position = 1,
			   HelpMessage = 'Provide a file path for SBECmd CSV output')]
	[ValidatePattern('^.*_(UsrClass|NtUser)\.csv$')]
	# looks for *_UsrClass.csv or *_NtUser.csv. Can currently only ingest one file at a time
	[string]$Path
)

if (-not (Test-Path $Path))
{
	Write-Host "Error: File not found at the specified path: $Path" -ForegroundColor Red
	exit 1
}

## Read CSV file
$csvData = Import-Csv -Path $Path # ingests the CSV provided by the user via $path

## Get counts for FirstInteracted column combined with AbsolutePath
$AbsolutePathTotal = ($csvData | Where-Object { $_.AbsolutePath }).Count # counts how many AbsolutePath cells have a value
$AbsolutePathUnique = ($csvData | Where-Object { $_.AbsolutePath } | Select-Object -Property AbsolutePath -Unique).Count # counts how many unique AbsolutePath cells exist

## Get counts for FirstInteracted column combined with AbsolutePath
$FirstInteractedTotal = ($csvData | Where-Object { $_.FirstInteracted }).Count # counts how many FirstInteracted cells have a value
$FirstInteractedUnique = ($csvData | Where-Object { $_.FirstInteracted } | Select-Object -Property @{ Name = 'Combo'; Expression = { "$($_.AbsolutePath)|$($_.FirstInteracted)" } } | Select-Object -Unique Combo).Count # counts how many FirstInteracted cells have a value combined with the AbsolutePath value

## Get counts for LastInteracted column combined with AbsolutePath
$LastInteractedTotal = ($csvData | Where-Object { $_.LastInteracted }).Count # counts how many LastInteracted cells have a value
$LastInteractedUnique = ($csvData | Where-Object { $_.LastInteracted } | Select-Object -Property @{ Name = 'Combo'; Expression = { "$($_.AbsolutePath)|$($_.LastInteracted)" } } | Select-Object -Unique Combo).Count # counts how many LastInteracted cells have a value combined with the AbsolutePath value

## Get total unique values between both columns combined with AbsolutePath
$uniqueValues = $csvData | ForEach-Object {
	if ($_.FirstInteracted) { "$($_.AbsolutePath)|$($_.FirstInteracted)" }
	if ($_.LastInteracted) { "$($_.AbsolutePath)|$($_.LastInteracted)" }
} | Select-Object -Unique

$totalUniqueValues = $uniqueValues.Count

## Get total values in both columns
$totalValues = $FirstInteractedTotal + $LastInteractedTotal

## Output results
Write-Host "This script combines either FirstInteracted or LastInteracted with the value of AbsolutePath for the purpose of calculating the total count within a respective CSV"
Write-Host "Total count of values in AbsolutePath column: $AbsolutePathTotal"
Write-Host "Number of unique values in AbsolutePath column: $AbsolutePathUnique"
Write-Host "Total count of values in FirstInteracted column: $FirstInteractedTotal"
Write-Host "Number of unique values in FirstInteracted column: $FirstInteractedUnique"
Write-Host "Total count of values in LastInteracted column: $LastInteractedTotal"
Write-Host "Number of unique values in LastInteracted column: $LastInteractedUnique"
Write-Host "Total unique values between both AbsolutePath and FirstInteracted/LastInteracted columns: $totalUniqueValues"
Write-Host "Total number of values between both AbsolutePath and FirstInteracted/LastInteracted columns: $totalValues"

# SIG # Begin signature block
# MIIvngYJKoZIhvcNAQcCoIIvjzCCL4sCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD3E7tU9nEKh8eL
# C/8T+zJoSuFmLaSJuwys2LSSns/0DqCCKKMwggQyMIIDGqADAgECAgEBMA0GCSqG
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
# pGqqIpswggZ1MIIE3aADAgECAhA1nosluv9RC3xO0e22wmkkMA0GCSqGSIb3DQEB
# DAUAMFQxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxKzAp
# BgNVBAMTIlNlY3RpZ28gUHVibGljIENvZGUgU2lnbmluZyBDQSBSMzYwHhcNMjIw
# MTI3MDAwMDAwWhcNMjUwMTI2MjM1OTU5WjBSMQswCQYDVQQGEwJVUzERMA8GA1UE
# CAwITWljaGlnYW4xFzAVBgNVBAoMDkFuZHJldyBSYXRoYnVuMRcwFQYDVQQDDA5B
# bmRyZXcgUmF0aGJ1bjCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALe0
# CgT89ev6jRIhHdrp9cdPnRoF5AV3wQdWzNG8JiY4dpN1YVwGLlw8aBosm0NIRz2/
# y/kriL+Jdu/FFakJdpB8l/J+mesliYhN+zj9vFviBjrElMASEBS9DXKaUFuqZMGi
# C6k6yASGfyqF121OkLZ2JImy4a0C43Pd74dbf+/Ae4QHj66otahUBL++7ayba/TJ
# ebhRdEq0wFiaxYsZOt18c3LLfAw0fniHfMBZXXJAQhgu1xfgpw7OE4N/M5or5VDV
# Q4ovtSFDVRzRARIF4ibZZqB76Rp5MuI0pMCs74TPN6WdlzGTDBu4pTS064iGx5hl
# P+GB5s/w/YW1BDigFV6yaERsbet9G2lsMmNwZtI6zUuGd9HEtd5isz/9ENhLcFoa
# JE7/KK8CL5jt8i9I3Lx+5EOgEwm65eHm45bq63AVKvSHrjisuxX89jWTeslKMM/r
# pw8GMrNBxo9DZvDS4+kCloFKARiwKHJIKpNWUT3T8Kw6Q/ayxUt7TKp+cqh0U9Yo
# XLbXIYMpLa5KfOsf21SqfSrhJ+rSEPEBM11uX41T/mQD5sArN9AIPQxp6X7qLckz
# ClylAQgzF2OVHEEi5m2kmb0lvfMOMGQ3BgwQHCRcd65wugzCIipb5KBTq+HJLgRW
# FwYGraxcfsLkkwBY1ssKPaVpAgMDmlWJo6hDoYR9AgMBAAGjggHDMIIBvzAfBgNV
# HSMEGDAWgBQPKssghyi47G9IritUpimqF6TNDDAdBgNVHQ4EFgQUUwhn1KEy//RT
# 4cMg1UJfMUX5lBcwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwEwYDVR0l
# BAwwCgYIKwYBBQUHAwMwEQYJYIZIAYb4QgEBBAQDAgQQMEoGA1UdIARDMEEwNQYM
# KwYBBAGyMQECAQMCMCUwIwYIKwYBBQUHAgEWF2h0dHBzOi8vc2VjdGlnby5jb20v
# Q1BTMAgGBmeBDAEEATBJBgNVHR8EQjBAMD6gPKA6hjhodHRwOi8vY3JsLnNlY3Rp
# Z28uY29tL1NlY3RpZ29QdWJsaWNDb2RlU2lnbmluZ0NBUjM2LmNybDB5BggrBgEF
# BQcBAQRtMGswRAYIKwYBBQUHMAKGOGh0dHA6Ly9jcnQuc2VjdGlnby5jb20vU2Vj
# dGlnb1B1YmxpY0NvZGVTaWduaW5nQ0FSMzYuY3J0MCMGCCsGAQUFBzABhhdodHRw
# Oi8vb2NzcC5zZWN0aWdvLmNvbTAlBgNVHREEHjAcgRphbmRyZXcuZC5yYXRoYnVu
# QGdtYWlsLmNvbTANBgkqhkiG9w0BAQwFAAOCAYEATPy2wx+JfB71i+UCYCOjFFBq
# rA4kCxsHv3ihLjF4N3g8jb7A156vBangR3BDPQ6lF0YCPwEFE9MQzqG7OgkUauX0
# vfPeuVe8cEadUFlrmb6xCmXsxKdGXObaITeGABz97AzLKxgxRf7xCEKsAzvbuaK3
# lvb3Me9jtRVn9Q69sBTE5I/IDf2PoG/tO/ibPYXC1KpilBNT0A28xMtQ1ijTS0dn
# bOyTMaUBCZUrNR/9qY2sOBhvxuvSouWjuEazDLTCs6zsMBQH9vfrLoNlvEXI5YO9
# Ck19kT9pZ2rGFO7y8ySRmoVpZvHI29Z4bXBtGUGb2g/RRppid5anuRtN+Skr7S1w
# drNlhBIYErmCUPH2RPMphN2wmUy6IsDpdTPJkPTmU83q3tpOBGwvyTdxhiPIurZM
# XSDXfUyGB2iiXoyUHP2caVUmsarEb3BgCEf0PT2rO971WCDnG0mMgle2Yur4z3eW
# EsKUoPdFAoiizb7CddijTOsNvxYNf0XEg5Ek1gTSMIIGezCCBGOgAwIBAgIQAQdk
# mwiwp/591lSo8vQp9jANBgkqhkiG9w0BAQsFADBbMQswCQYDVQQGEwJCRTEZMBcG
# A1UEChMQR2xvYmFsU2lnbiBudi1zYTExMC8GA1UEAxMoR2xvYmFsU2lnbiBUaW1l
# c3RhbXBpbmcgQ0EgLSBTSEEzODQgLSBHNDAeFw0yMzExMDcxNzEzNDBaFw0zNDEy
# MDkxNzEzNDBaMGwxCzAJBgNVBAYTAkJFMRkwFwYDVQQKDBBHbG9iYWxTaWduIG52
# LXNhMUIwQAYDVQQDDDlHbG9iYWxzaWduIFRTQSBmb3IgTVMgQXV0aGVudGljb2Rl
# IEFkdmFuY2VkIC0gRzQgLSAyMDIzMTEwggGiMA0GCSqGSIb3DQEBAQUAA4IBjwAw
# ggGKAoIBgQC5qJs+qabcQtNBn4pNQ0cJ+WiLE/t1j5lcyoBCYe+OuuFx1keQrZlN
# YwO276kmo/s26m4UR/fXTUR0sipenTJfBGivt8nPWwsnLyhOgt6OtbOJ+ucRScgn
# QF6TbwkhxtZfmPO3uqFAcq7dD9/OIUIEVDjqyiLdA7kaoeC3HJcocywgjT9msnaZ
# 2jrJ9nKWUnTYfWVu4CJv/q9G/X6vTsiJgTKhmCuPd+eyo9Wanx/RgyBOTe9MO1F7
# kSPhg0qib7gE5mQUSy47fOm1/bNuNkRANvW+Iebo0Pp+96hORqyUsNApdOKxl6p/
# OPGJ4nq3ymwFMBhYb31bfjqR1HxvTv/pMX6lgjXhLv8KYOpShVeHeuQqrzyi33nb
# 4HmP35Ht/yY9dkBL3xtL9oKo6oMorVO2t5bXHS2M7799ip6UfFOpZARrfMwWZxkx
# gpLp9Dq81IiovY7uTxJ52P/glpBQfgEV//DjbF4a9K9AxeUnPUb4OkE4/zlItNwG
# Afs7CChoaakCAwEAAaOCAagwggGkMA4GA1UdDwEB/wQEAwIHgDAWBgNVHSUBAf8E
# DDAKBggrBgEFBQcDCDAdBgNVHQ4EFgQU+KOn5SN1VtGlpTuJbhZxy1XWiAkwVgYD
# VR0gBE8wTTAIBgZngQwBBAIwQQYJKwYBBAGgMgEeMDQwMgYIKwYBBQUHAgEWJmh0
# dHBzOi8vd3d3Lmdsb2JhbHNpZ24uY29tL3JlcG9zaXRvcnkvMAwGA1UdEwEB/wQC
# MAAwgZAGCCsGAQUFBwEBBIGDMIGAMDkGCCsGAQUFBzABhi1odHRwOi8vb2NzcC5n
# bG9iYWxzaWduLmNvbS9jYS9nc3RzYWNhc2hhMzg0ZzQwQwYIKwYBBQUHMAKGN2h0
# dHA6Ly9zZWN1cmUuZ2xvYmFsc2lnbi5jb20vY2FjZXJ0L2dzdHNhY2FzaGEzODRn
# NC5jcnQwHwYDVR0jBBgwFoAU6hbGaefjy1dFOTOk8EC+0MO9ZZYwQQYDVR0fBDow
# ODA2oDSgMoYwaHR0cDovL2NybC5nbG9iYWxzaWduLmNvbS9jYS9nc3RzYWNhc2hh
# Mzg0ZzQuY3JsMA0GCSqGSIb3DQEBCwUAA4ICAQBwK1kuawVStSZXIbXPEOia8KzL
# clRobVVFmZY5WEcb0GlrKGzwk4umRMt4yatOYsSCHwWQ3qwGljuuoEYNgYbskHDc
# sjUuy1UtQ0dvi3pOQT/+siGcQDHYrY+VNxqC68i3DqehXBqqwGpJ/Q+KBAcmwtkO
# zyYDfTBFv2xQeg/pJDZMgKToIkErYGa8rAvPMsiAfypGx5zC5R8P1lX5Agxhxbxi
# j12jImHraph4sGQvCbANybgIHFpeBjAkXXGDdjj9SGqYXT9CSG8shDb85v6SwtJw
# Y0GDtfSgCmVa1UH0g6gwG8jWW25A6MPN5jfiyelVXItTxO7h37vTtZGKu2dztQjw
# qEirDhvgRHC+4gTnEanhP1BBmgxmClZFwQVB+UIV/QSmkbX6TBaKfn4FmqGHdFT9
# x6fA5pNnnaQdKlw6BLVO1Rceo+KN7j48CoFPWTH7Bf+YGdOYuAbYSJtJk+ECx22y
# LIrc6l7b1G/9B6wePDZRd/E+LJJk9ZjwTyuaEPPaXzj6SkLJf2Cjm0mhMwsQzsJP
# pdOygFgZJvpDCUq1ddWe2K8Nrx62+0tJeP1fseqG7Xrqd7rR7OeGNQn5WruW4fYK
# V/n91v4kGgBQvZ5NyJEYN+zSKM4PrpdGHcJ8YMu7mmSulrW55cp65XrWeEEk3mbJ
# 9lAXRaV/0x/qHtrv6DGCBlEwggZNAgEBMGgwVDELMAkGA1UEBhMCR0IxGDAWBgNV
# BAoTD1NlY3RpZ28gTGltaXRlZDErMCkGA1UEAxMiU2VjdGlnbyBQdWJsaWMgQ29k
# ZSBTaWduaW5nIENBIFIzNgIQNZ6LJbr/UQt8TtHttsJpJDANBglghkgBZQMEAgEF
# AKBMMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMC8GCSqGSIb3DQEJBDEiBCBA
# N95SsfWxrvMz6m5HblTtddVuZI1VMucn7t+HHxkOLTANBgkqhkiG9w0BAQEFAASC
# AgBXe34gO9545baHj6L+5/WqyHiRxvSwNXNR+z3xe7wUaXzXUCG4kR2f5at8dRI2
# sK+uwtAXyhkFXDKBphWiZ8+j2OfQ0mX78ZkiSfstW/XhPDS8u9Iq4Vfw5r/TMAqg
# thLwotwJU0bWzWPzQ4r+uRMVIOgrnaJhX3EzO/vzIR+uhZwMZ9zZNBy1O0bszgDr
# wGIo9XybGuEw/0Xwv/6WUwtR4js2YXuh3sCfu+XhDf74xqIfhlAgZCDMntjtGyVQ
# bfbbhgJipfEtil4GQyj8MFoxh9/a6fXKjZ2YNhVzjns1FsU3PAHmqmLhqeyDwS7C
# WtdGreV3+idXxTN0Xz963Sv/i+QdxA4QS2Y2SrxqNFXNoy1Sca3OuaHDzFEYooLm
# YM1NGROcXf129PD//huNFsXm90ys8g5GlkFIGyF5X3YLBp8gvTSFjvH7bFdJYDPc
# +O8BwTcBYBX9wGiTD0tlCKuRvWSSIyu9DO0p+yPvW4HyOJz8lIAGAH0Gy6W8+9hT
# lO2QNF3iazGMK452JQt9lDmoBxW9lVT9mnPmeeB6tl2ZIi0Y/49IZEc954VO0V3n
# WIwc2u9K6jKSd2VFAfUDwSCb9O83wOByMI36SSDxgfL57OZ3K9XrwOQCOMUUA4zl
# z7jHufShCC08AtfIBRKQM3ETqH2/TQs2epmaHMNYKsxvk6GCA2wwggNoBgkqhkiG
# 9w0BCQYxggNZMIIDVQIBATBvMFsxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9i
# YWxTaWduIG52LXNhMTEwLwYDVQQDEyhHbG9iYWxTaWduIFRpbWVzdGFtcGluZyBD
# QSAtIFNIQTM4NCAtIEc0AhABB2SbCLCn/n3WVKjy9Cn2MAsGCWCGSAFlAwQCAaCC
# AT0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMjQw
# NzAxMTkxNzQ3WjArBgkqhkiG9w0BCTQxHjAcMAsGCWCGSAFlAwQCAaENBgkqhkiG
# 9w0BAQsFADAvBgkqhkiG9w0BCQQxIgQgugWivAmbZ3Bx20d0rcS/kHN1H9a8C5H6
# LzErbJFyfYgwgaQGCyqGSIb3DQEJEAIMMYGUMIGRMIGOMIGLBBRE05OczRuIf4Z6
# zNqB7K8PZfzSWTBzMF+kXTBbMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFs
# U2lnbiBudi1zYTExMC8GA1UEAxMoR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0Eg
# LSBTSEEzODQgLSBHNAIQAQdkmwiwp/591lSo8vQp9jANBgkqhkiG9w0BAQsFAASC
# AYAu5QN96C27qx7zN9nugt3ZM9xhSIY9Lirh5UPBPSZ1BT15R/0xNsWWh5GIAJQN
# ieo9FNUYyeX+w6j0DbsKdjfodQHByNZrIzgmTCy3SZTQ82y/P1sqfH28LcfLQpTP
# hKXoExxI5MqRlTGMPoRuk9UbC7ZNyqiMX65KUnxodHZ+dnj1jni1ajPmM7Jjg+Yk
# McxxL45sz1fDeg/3hxpeCsF+P8jpedcfq9l5OMqoQUbJjqtnStoaiGTE+/85X6qZ
# mLfyMwupWF06+VJN7SWu8Azve/8f4ojh2ZOb7cGMoOGHaXUFKJLbmxYAWt2KEqA5
# QDgt0fmOkdYausjzYXjEhadWX26tpFGiHEcJgk0nNPOKsA7EoqgJLq7P/48xgBeN
# nau3uzzxqk2ciVmj4ZBDkzKZEXJGfQeheecHJbC/KOrR7TqY5jQWzpy+V4nuE0cZ
# EiL/4yOII9C5rjJZrn3oG+hC60p3msT8b+Qui57IGl8xV/fnfWkX0byhRcOMUdsn
# L5c=
# SIG # End signature block
