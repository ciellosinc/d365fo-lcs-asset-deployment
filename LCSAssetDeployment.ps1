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
        [string]$UpdateName,
        [switch]$WaitForCompletion)
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

Get-D365LcsApiToken -ClientId $ClientId -Username $Username -Password $Password -LcsApiUri "https://lcsapi.lcs.dynamics.com" | Set-D365LcsApiConfig -ProjectId $ProjectId
$PSFObject = Invoke-D365LcsDeployment -AssetId $LCSFileAssetID -EnvironmentId $LCSEnvironmentID -UpdateName $UpdateName

do {
    Start-Sleep -Seconds 30
    $deploymentStatus = Get-D365LcsDeploymentStatus -ActivityId $PSFObject.ActivityId -EnvironmentId $LCSEnvironmentID -FailOnErrorMessage -EnableException -SleepInSeconds 5

    if ($FailOnErrorMessage -and $deploymentStatus.ErrorMessage) {
        $messageString = "The request against LCS succeeded, but the response was an error message for the operation: <c='em'>$($deploymentStatus.ErrorMessage)</c>."
        $errorMessagePayload = "`r`n$($deploymentStatus | ConvertTo-Json)"

    }
    Write-Host $deploymentStatus.OperationStatus, $deploymentStatus.CompletionDate
}
while ((($deploymentStatus.OperationStatus -eq "InProgress") -or ($deploymentStatus.OperationStatus -eq "NotStarted") -or ($deploymentStatus.OperationStatus -eq "PreparingEnvironment")) -and $WaitForCompletion)

