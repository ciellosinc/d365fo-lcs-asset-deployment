    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ClientId,
        [string]$Username,
        [string]$Password,
        [string]$FilePath,
        $ProjectId,
        [string]$LCSEnvironmentID,
        [string]$LCSFileAssetID,
        [string]$UpdateName)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#Check Modules installed
if( -not ((Get-PackageProvider -Name nuget).Name -eq 'NuGet'))
{
    Install-PackageProvider nuget -Scope CurrentUser -Force -Confirm:$false
}
if( -not ((Find-Module  -Name AZ).Name -eq 'Az'))
{
    Install-Module -Name AZ -AllowClobber -Scope CurrentUser -Force -Confirm:$False -SkipPublisherCheck
}
if( -not ((Find-Module -Name d365fo.tools).Name -eq 'd365fo.tools'))
{
    Install-Module -Name d365fo.tools -AllowClobber -Scope CurrentUser -Force -Confirm:$false
}
else
{
     Import-Module -Name d365fo.tools -Force -Confirm:$false
}
Get-D365LcsApiToken -ClientId $ClientId -Username $Username -Password $Password -LcsApiUri "https://lcsapi.lcs.dynamics.com" -Verbose | Set-D365LcsApiConfig -ProjectId $ProjectId
$PSFObject = Invoke-D365LcsDeployment -AssetId $LCSFileAssetID -EnvironmentId $LCSEnvironmentID -UpdateName $UpdateName
Get-D365LcsDeploymentStatus -ActivityId $PSFObject.ActivityId -EnvironmentId $LCSEnvironmentID -WaitForCompletion
