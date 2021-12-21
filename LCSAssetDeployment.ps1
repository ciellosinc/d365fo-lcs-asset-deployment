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
$NuGet = Get-PackageProvider -Name nuget -ErrorAction SilentlyContinue
$Az = Get-InstalledModule -Name AZ -ErrorAction SilentlyContinue
$DfoTools = Get-InstalledModule -Name d365fo.tools -ErrorAction SilentlyContinue

if([string]::IsNullOrEmpty($NuGet))
{
    Install-PackageProvider nuget -Scope CurrentUser -Force -Confirm:$false
}
if([string]::IsNullOrEmpty($Az))
{
    Install-Module -Name AZ -AllowClobber -Scope CurrentUser -Force -Confirm:$False -SkipPublisherCheck
}
if([string]::IsNullOrEmpty($DfoTools))
{
    Install-Module -Name d365fo.tools -AllowClobber -Scope CurrentUser -Force -Confirm:$false
}

Get-D365LcsApiToken -ClientId $ClientId -Username $Username -Password $Password -LcsApiUri "https://lcsapi.lcs.dynamics.com" -Verbose | Set-D365LcsApiConfig -ProjectId $ProjectId
$PSFObject = Invoke-D365LcsDeployment -AssetId $LCSFileAssetID -EnvironmentId $LCSEnvironmentID -UpdateName $UpdateName -Verbose
Get-D365LcsDeploymentStatus -ActivityId $PSFObject.ActivityId -EnvironmentId $LCSEnvironmentID -FailOnErrorMessage $True  -EnableException $True -WaitForCompletion -Verbose
