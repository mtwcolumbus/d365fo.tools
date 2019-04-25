﻿
<#
    .SYNOPSIS
        Start the deployment of a deployable package
        
    .DESCRIPTION
        Deploy a deployable package from the Asset Library from a LCS projcet using the API provided by Microsoft
        
    .PARAMETER ProjectId
        The project id for the Dynamics 365 for Finance & Operations project inside LCS
        
    .PARAMETER ClientId
        The Azure Registered Application Id / Client Id obtained while creating a Registered App inside the Azure Portal
        
    .PARAMETER Username
        The username of the account that you want to impersonate
        
        It can either be your personal account or a service account
        
    .PARAMETER Password
        The password of the account that you want to impersonate

    .PARAMETER FileName
        Name to be assigned / shown on LCS
        
    .PARAMETER LcsApiUri
        URI / URL to the LCS API you want to use
        
        Depending on whether your LCS project is located in europe or not, there is 2 valid URI's / URL's
        
        Valid options:
        "https://lcsapi.lcs.dynamics.com"
        "https://lcsapi.eu.lcs.dynamics.com"
        
    .EXAMPLE
        
    .EXAMPLE
        
    .NOTES
        Tags: Environment, Url, Config, Configuration, LCS, Upload, Api, AAD, Token, Deployment, Deploy
        
        Author: Mötz Jensen (@Splaxi)
        
#>

function Invoke-D365LcsUpload {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUserNameAndPassWordParams", "")]
    [CmdletBinding()]
    [OutputType()]
    param(
        [Parameter(Mandatory = $false, Position = 1)]
        [int] $ProjectId = $Script:LcsUploadProjectId,
        
        [Parameter(Mandatory = $false, Position = 2)]
        [string] $ClientId = $Script:LcsUploadClientId,

        [Parameter(Mandatory = $false, Position = 3)]
        [string] $Username = $Script:LcsUploadUsername,

        [Parameter(Mandatory = $false, Position = 4)]
        [string] $Password = $Script:LcsUploadPassword,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 5)]
        [string] $AssetId,

        [Parameter(Mandatory = $false, Position = 9)]
        [string] $LcsApiUri = $Script:LcsUploadApiUri
    )

    Invoke-TimeSignal -Start

    $fileNameExtracted = Split-Path $FilePath -Leaf

    if ($FileName -eq "") {
        $FileName = $fileNameExtracted
    }

    $scope = "openid"
    $grantType = "password"

    $authToken = Invoke-AadAuthentication -Resource $LcsApiUri -GrantType $grantType -ClientId $ClientId -Username $Username -Password $Password -Scope $scope

    if (Test-PSFFunctionInterrupt) { return }
    
    Write-PSFMessage -Level Verbose -Message "Auth token" -Target $authToken

    $bearerToken = "Bearer {0}" -f $authToken

    $blobDetails = Start-LcsUpload -Token $bearerToken -ProjectId $ProjectId -FileType $FileType -LcsApiUri $LcsApiUri -Name $FileName -Description $FileDescription

    if (Test-PSFFunctionInterrupt) { return }

    Write-PSFMessage -Level Verbose -Message "Start response" -Target $blobDetails

    $uploadResponse = Copy-FileToLcsBlob -FilePath $FilePath -FullUri $blobDetails.FileLocation

    if (Test-PSFFunctionInterrupt) { return }

    Write-PSFMessage -Level Verbose -Message "Upload response" -Target $uploadResponse

    $ackResponse = Complete-LcsUpload -Token $bearerToken -ProjectId $ProjectId -AssetId $blobDetails.Id -LcsApiUri $LcsApiUri

    if (Test-PSFFunctionInterrupt) { return }

    Write-PSFMessage -Level Verbose -Message "Commit response" -Target $ackResponse

    Invoke-TimeSignal -End

    [PSCustomObject]@{
        AssetId = $blobDetails.Id
        Name = $FileName
    }
}