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
		return "Connected to $vsts_Account"
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
				Uri = "$($vsts_Account)/$ProjectName/_apis/distributedtask/variablegroups"
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
					Uri = "$($vsts_Account)/$ProjectName/_apis/distributedtask/variablegroups?api-version=4.1-preview.1"
					Headers = $vsts_Headers
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
				Uri = "$($vsts_Account)/$ProjectName/_apis/distributedtask/variablegroups?api-version=4.1-preview.1"
				Headers = $vsts_headers
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