function Add-VstsAccount {
<#
	.Synopsis
		Authenticate with VSTS.
	
	.Description
		Converts the Personal Access Token to base64 and creates object to use in other functions.
	
	.PARAMETER AccountName
        Required AccountName. Used to authenticate with VSTS.
    
    .PARAMETER Token
		Required personal access token to autheticate with VSTS.
		
	.Example
		Autheticate with VSTS

		Add-VstsAccount -AccountName Demo -Token 4j294429dsqw14425674466f22d43sd323d465tga1a
#>
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   Position = 0)]
		[string]$AccountName,
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   Position = 0)]
		[string]$PersonalAccessToken
	)

	Begin {
	}
	Process {
		# Authorization to usf hii VSTS. $UserName is left blank... Token is Personal Access Token default value. 
		$ConvertToBase64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $UserName, $PersonalAccessToken)))
		try {
			$AccountProperties = @{
				Authorization = ("Basic {0}" -f $ConvertToBase64)
			}	
			$Request = (Invoke-RestMethod -uri "https://$($AccountName).visualstudio.com/_apis/projects/" -Headers $AccountProperties).Value
			if ($Request -eq $null) {
				Write-Error "Invalid token: $Token"
			}
			$global:vsts_Headers = $AccountProperties
			$global:vsts_AccountName = $AccountName
			$global:vsts_Account = "https://$($AccountName).visualstudio.com"
		}
		catch {
			throw $_
		}
	}
	End {
		return "Connected to $ENV:vsts_Account"
	}
}

function Export-VstsVariableGroup {
<#
	.Synopsis
		Exports library variable groups.

	.Description
		Exports Library variable groups to json files. Could be used in the pipeline to import the variable groups into a different team project.

		In order to run function, VSTS will need to be authenticated. 

	.PARAMETER AccountName
		Mandatory AccountName. Name of VSTS account. Example: demo

	.PARAMETER ProjectName
		Mandatory ProjectName. Name of team project in VSTS.

	.PARAMETER VariableGroupName 
		Name of library variable group in VSTS.
	
	.PARAMETER Path
		File path to export the variable group(s) to json files.
		
	.Example
		Example 1: Get all library variable groups

		$Headers = (Get-VstsAutorization -AccountName demo -Token 4j294429dsqw14425674466f22d43sd323d465tga1a).Headers
		Export-VstsVariableGroup -AccountName demo -ProjectName Project1

		Example 2: Get one variable group

		$Headers = (Get-VstsAutorization -AccountName demo -Token 4j294429dsqw14425674466f22d43sd323d465tga1a).Headers
		Export-VstsVariableGroup -AccountName demo -ProjectName Project1 -VariableGroupName Project1-Dev

		Example 3: Get multiple variable groups

		$Headers = (Get-VstsAutorization -AccountName demo -Token 4j294429dsqw14425674466f22d43sd323d465tga1a).Headers
		Export-VstsVariableGroup -AccountName demo -ProjectName Project1 -VariableGroupName Project1-Dev, Project1-Production

		Example 4: Export one variable group to json file

		$Headers = (Get-VstsAutorization -AccountName demo -Token 4j294429dsqw14425674466f22d43sd323d465tga1a).Headers
		Export-VstsVariableGroup -AccountName demo -ProjectName Project1 -VariableGroupName Project1-Dev -Path C:\temp

		Example 5: Export multiple variable groups to json files

		$Headers = (Get-VstsAutorization -AccountName demo -Token 4j294429dsqw14425674466f22d43sd323d465tga1a).Headers
		Export-VstsVariableGroup -AccountName demo -ProjectName Project1 -VariableGroupName Project1-Dev, Project1-Production -Path C:\temp

#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   Position = 1)]
		[string]$ProjectName,
		[Parameter(Mandatory = $false,
				   ValueFromPipeline=$true,
				   Position = 2)]
		[string[]]$VariableGroupName,
		[Parameter(Mandatory = $false,
				   Position = 3)]
		[string]$Path
	)

	Begin {
	}
	Process {
		try {
			$Params = @{
				Uri = "$($ENV:vsts_Account)/$ProjectName/_apis/distributedtask/variablegroups"
				Headers = $vsts_Headers
				Method = 'Get'
				ErrorAction = 'Stop'
			}
			$Response = (Invoke-RestMethod @Params).Value
			if ($VariableGroupName) {
				$Response = foreach ($Name in $VariableGroupName) {
					$Response |Where-Object name -eq $Name
				}
			}
		}
		catch {
			throw $_
		}
	}
	End {
		foreach ($Group in $Response) {
			$ConvertVariableGroup = $Group |ConvertTo-Json -Depth 4
			if ($Path) {
				$ConvertVariableGroup |Out-File "$($Path)\$($Group.name).json"
			}
			$ConvertVariableGroup
		}
	}
}

function Import-VstsVariableGroup {
<#
	.Synopsis
		Imports library variable groups.

	.Description
		Imports Library variable groups from json files or the pipeline.

		In order to run function, VSTS will need to be authenticated. 

	.PARAMETER AccountName
		Mandatory AccountName. Name of VSTS account. Example: demo

	.PARAMETER ProjectName
		Mandatory ProjectName. Name of team project in VSTS.

	.PARAMETER InputObject
	
	.PARAMETER Path
		File path to import the variable group(s) from json files.
		
	.Example
		Example 1: Import all variable groups

		$Headers = (Get-VstsAutorization -AccountName demo -Token 4j294429dsqw14425674466f22d43sd323d465tga1a).Headers
		Export-VstsVariableGroup -AccountName demo -ProjectName Project1 |Import-VstsVariableGroup

		Example 2: Import one variable group

		$Headers = (Get-VstsAutorization -AccountName demo -Token 4j294429dsqw14425674466f22d43sd323d465tga1a).Headers
		Export-VstsVariableGroup -AccountName demo -ProjectName Project1 -VariableGroupName Project1-Dev -Headers $Headers |Import-VstsVariableGroup

		Example 3: Import variable group from json file.

		$Headers = (Get-VstsAutorization -AccountName demo -Token 4j294429dsqw14425674466f22d43sd323d465tga1a).Headers
		Import-VstsVariableGroup -AccountName demo -ProjectName Project1 -Path C:\temp\project1-dev.json -Headers $Headers

		Example 5: Import multiple variable groups from json files

		$Headers = (Get-VstsAutorization -AccountName demo -Token 4j294429dsqw14425674466f22d43sd323d465tga1a).Headers
		Import-VstsVariableGroup -AccountName demo -ProjectName Project1 -Path C:\temp\project1-dev.json,C:\temp\project1-production.json -Headers $Headers

#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   Position = 2)]
		[string]$ProjectName,
		[Parameter(ValueFromPipeline = $True,
				   Position = 3)]
        [object]$InputObject,
		[Parameter(Mandatory = $false,
				   ValueFromPipeline = $false,
				   Position = 4)]
		[string[]]$Path
	)

	Begin {
	}
	Process {
		if ($Path) {
			foreach ($File in $Path) {
				$Params = @{
					Uri = "$($global:vsts_Account)/$ProjectName/_apis/distributedtask/variablegroups?api-version=4.1-preview.1"
					Headers = $global:vsts_Headers
					ContentType = 'application/json'
					Method = 'Post'
				}
				$Json = Get-Content -Path $File
				$Params.Add('Body', $Json)
				Invoke-RestMethod @Params
			}
		}
		else {
			$Params = @{
				Uri = "$($global:vsts_Account)/$ProjectName/_apis/distributedtask/variablegroups?api-version=4.1-preview.1"
				Headers = $global:vsts_headers
				ContentType = 'application/json'
				Method = 'Post'
			}
			if ($InputObject) {
				$Params.Add('Body', $InputObject)
			}
			Invoke-RestMethod @Params
		}
	}
	End {
	}
}


# SIG # Begin signature block
# MIIORgYJKoZIhvcNAQcCoIIONzCCDjMCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUTFL+oO1lmP5SrGoYqJRxlea/
# Nd6gggt+MIIFizCCBHOgAwIBAgIQJG0JIrvaHRFoNN+b4GQU8zANBgkqhkiG9w0B
# AQsFADB8MQswCQYDVQQGEwJVUzELMAkGA1UECBMCTUkxEjAQBgNVBAcTCUFubiBB
# cmJvcjESMBAGA1UEChMJSW50ZXJuZXQyMREwDwYDVQQLEwhJbkNvbW1vbjElMCMG
# A1UEAxMcSW5Db21tb24gUlNBIENvZGUgU2lnbmluZyBDQTAeFw0xNjA3MDUwMDAw
# MDBaFw0xOTA3MDUyMzU5NTlaMIHFMQswCQYDVQQGEwJVUzEOMAwGA1UEEQwFMzM2
# MTIxCzAJBgNVBAgMAkZMMQ4wDAYDVQQHDAVUYW1wYTESMBAGA1UECQwJU3VpdGUg
# MTAwMRswGQYDVQQJDBIzNjUwIFNwZWN0cnVtIEJsdmQxJDAiBgNVBAoMG1VuaXZl
# cnNpdHkgb2YgU291dGggRmxvcmlkYTEMMAoGA1UECwwDRVBJMSQwIgYDVQQDDBtV
# bml2ZXJzaXR5IG9mIFNvdXRoIEZsb3JpZGEwggEiMA0GCSqGSIb3DQEBAQUAA4IB
# DwAwggEKAoIBAQC0lA9TBpRbE2esKduC45jNeyEZ2GbQj4Cu4J6Fhdrf4xbgJJBY
# XGEUjex5BfxLj1/J8cDI2zHTY94N6FWDbAbHSaviWR7TyyEUpuFyjqJ7U2wYb42R
# W3UiW+euo6EZIsP021i6LMrtGi31e3LjRCmQyD/P3E/xFG3NPQf7R+GsQYmT+kwT
# dUpTwHWhJuVubOcW1v1bAWg8pKQKfRAqXf/PDlW/idy6IcjSN6fX/6dRPy79qkNK
# mMqC27qU2Kt2UOsR7t9Y6x0Ju4uQprD2nGKXWPD1ptS43HYaOXhT535tA/CNQaf1
# lEbHCQSz/NDFzlZEv4V3+399bM+IH5RSwYkZAgMBAAGjggG9MIIBuTAfBgNVHSME
# GDAWgBSuNSMX//8GPZxQ4IwkZTMecBCIojAdBgNVHQ4EFgQUksSexgxWwlgzyiEV
# ihEMltxPKsswDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwEwYDVR0lBAww
# CgYIKwYBBQUHAwMwEQYJYIZIAYb4QgEBBAQDAgQQMGYGA1UdIARfMF0wWwYMKwYB
# BAGuIwEEAwIBMEswSQYIKwYBBQUHAgEWPWh0dHBzOi8vd3d3LmluY29tbW9uLm9y
# Zy9jZXJ0L3JlcG9zaXRvcnkvY3BzX2NvZGVfc2lnbmluZy5wZGYwSQYDVR0fBEIw
# QDA+oDygOoY4aHR0cDovL2NybC5pbmNvbW1vbi1yc2Eub3JnL0luQ29tbW9uUlNB
# Q29kZVNpZ25pbmdDQS5jcmwwfgYIKwYBBQUHAQEEcjBwMEQGCCsGAQUFBzAChjho
# dHRwOi8vY3J0LmluY29tbW9uLXJzYS5vcmcvSW5Db21tb25SU0FDb2RlU2lnbmlu
# Z0NBLmNydDAoBggrBgEFBQcwAYYcaHR0cDovL29jc3AuaW5jb21tb24tcnNhLm9y
# ZzANBgkqhkiG9w0BAQsFAAOCAQEAp2+YsTmkusJg0/pnpWqpKzhsSo4Zw691T5Cr
# 4x6KqDvF7Jl4lAdjpQNcbcQB1/SefturFQITJT92KYvewzQ3nMWj+42xWMPU9fhb
# zE0aPIOYXYCzJbBxNeRuTf95fZ0dtCbO4+LErgfGN+ZtVsD2GR+3ncpVGgFq3J2l
# a4ubLmwdIPwmjPjf8kFPt9brBUTJnPotFVVxdL9WR7sfEebvQVEF8W7/hHzVsNjw
# bwH3aJAZKjfBLugtU26WlEG07bxRF9SgbNOn/Hwas1E+wcZbouqwLf2eHiWM3uAh
# H+A1cO8GpPSy9f6OnkG8gSR3obqqAj6sT4kwicdFMUUhVmllfDCCBeswggPToAMC
# AQICEGXh4uPV3lBFhfMmJIAF4tQwDQYJKoZIhvcNAQENBQAwgYgxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpOZXcgSmVyc2V5MRQwEgYDVQQHEwtKZXJzZXkgQ2l0eTEe
# MBwGA1UEChMVVGhlIFVTRVJUUlVTVCBOZXR3b3JrMS4wLAYDVQQDEyVVU0VSVHJ1
# c3QgUlNBIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MB4XDTE0MDkxOTAwMDAwMFoX
# DTI0MDkxODIzNTk1OVowfDELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAk1JMRIwEAYD
# VQQHEwlBbm4gQXJib3IxEjAQBgNVBAoTCUludGVybmV0MjERMA8GA1UECxMISW5D
# b21tb24xJTAjBgNVBAMTHEluQ29tbW9uIFJTQSBDb2RlIFNpZ25pbmcgQ0EwggEi
# MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDAoC+LHnq7anWs+D7co7o5Isrz
# o3bkv30wJ+a605gyViNcBoaXDYDo7aKBNesL9l5+qT5oc/2d1Gd5zqrqaLcZ2xx2
# OlmHXV6Zx6GyuKmEcwzMq4dGHGrH7zklvqfd2iw1cDYdIi4gO93jHA4/NJ/lff5V
# gFsGfIJXhFXzOPvyDDapuV6yxYFHI30SgaDAASg+A/k4l6OtAvICaP3VAav11VFN
# UNMXIkblcxjgOuQ3d1HInn1Sik+A3Ca5wEzK/FH6EAkRelcqc8TgISpswlS9HD6D
# +FupLPH623jP2YmabaP/Dac/fkxWI9YJvuGlHYsHxb/j31iq76SvgssF+AoJAgMB
# AAGjggFaMIIBVjAfBgNVHSMEGDAWgBRTeb9aqitKz1SA4dibwJ3ysgNmyzAdBgNV
# HQ4EFgQUrjUjF///Bj2cUOCMJGUzHnAQiKIwDgYDVR0PAQH/BAQDAgGGMBIGA1Ud
# EwEB/wQIMAYBAf8CAQAwEwYDVR0lBAwwCgYIKwYBBQUHAwMwEQYDVR0gBAowCDAG
# BgRVHSAAMFAGA1UdHwRJMEcwRaBDoEGGP2h0dHA6Ly9jcmwudXNlcnRydXN0LmNv
# bS9VU0VSVHJ1c3RSU0FDZXJ0aWZpY2F0aW9uQXV0aG9yaXR5LmNybDB2BggrBgEF
# BQcBAQRqMGgwPwYIKwYBBQUHMAKGM2h0dHA6Ly9jcnQudXNlcnRydXN0LmNvbS9V
# U0VSVHJ1c3RSU0FBZGRUcnVzdENBLmNydDAlBggrBgEFBQcwAYYZaHR0cDovL29j
# c3AudXNlcnRydXN0LmNvbTANBgkqhkiG9w0BAQ0FAAOCAgEARiy2f2pOJWa9nGqm
# qtCevQ+uTjX88DgnwcedBMmCNNuG4RP3wZaNMEQT0jXtefdXXJOmEldtq3mXwSZk
# 38lcy8M2om2TI6HbqjACa+q4wIXWkqJBbK4MOWXFH0wQKnrEXjCcfUxyzhZ4s6tA
# /L4LmRYTmCD/srpz0bVU3AuSX+mj05E+WPEop4WE+D35OLcnMcjFbst3KWN99xxa
# K40VHnX8EkcBkipQPDcuyt1hbOCDjHTq2Ay84R/SchN6WkVPGpW8y0mGc59lul1d
# lDmjVOynF9MRU5ACynTkdQ0JfKHOeVUuvQlo2Qzt52CTn3OZ1NtIZ0yrxm267pXK
# uK86UxI9aZrLkyO/BPO42itvAG/QMv7tzJkGns1hmi74OgZ3WUVk3SNTkixAqCbf
# 7TSmecnrtyt0XB/P/xurcyFOIo5YRvTgVPc5lWn6PO9oKEdYtDyBsI5GAKVpmrUf
# dqojsl5GRYQQSnpO/hYBWyv+LsuhdTvaA5vwIDM8WrAjgTFx2vGnQjg5dsQIeUOp
# TixMierCUzCh+bF47i73jX3qoiolCX7xLKSXTpWS2oy7HzgjDdlAsfTwnwton5YN
# TJxzg6NjrUjsUbEIORtJB/eeld5EWbQgGfwaJb5NEOTonZckUtYS1VmaFugWUEuh
# SWodQIq7RA6FT/4AQ6qdj3yPbNExggIyMIICLgIBATCBkDB8MQswCQYDVQQGEwJV
# UzELMAkGA1UECBMCTUkxEjAQBgNVBAcTCUFubiBBcmJvcjESMBAGA1UEChMJSW50
# ZXJuZXQyMREwDwYDVQQLEwhJbkNvbW1vbjElMCMGA1UEAxMcSW5Db21tb24gUlNB
# IENvZGUgU2lnbmluZyBDQQIQJG0JIrvaHRFoNN+b4GQU8zAJBgUrDgMCGgUAoHgw
# GAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGC
# NwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQx
# FgQUTGzHO6jjD4KuMxsB2UEi7LXt98AwDQYJKoZIhvcNAQEBBQAEggEAHssR8ewg
# YStPAT1q7+pb5mjpKfS6FvzfT8O18/8yctV5kvCPV/zfGWcu9RCowHQ5/0MiU/Kf
# MaUXKz+lC/N+r8gxp0PE5GFC33nM5qINKU1RKA0TpkkIfJ/NDeLVgWRUi9wEsrvL
# GfKXGwfF4KvX9jsYYC7jMq48zFpZQxRXb3I1sbmiEyK+zItiwrNhnjwznJIo0Dzd
# XBIh1aAgli1D2Y7MLs5VkyxTJiDspe3BhI8mG371qEFGuRykeP23QspI4j7rtGUC
# VhO/sN6vm3t7UbLgdMvRqZoT0A7UY0I+GQ3MYE03D8Hwy5Ca7k6e+6mvLJ0NbuWi
# nvScVHR1eDNUfg==
# SIG # End signature block
