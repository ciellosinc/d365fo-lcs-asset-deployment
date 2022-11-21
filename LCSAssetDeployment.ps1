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
function installModules {
     Param(
         [String[]] $modules
     )
     begin{
         Set-MpPreference -DisableRealtimeMonitoring $true
     }
     process{
         $modules | ForEach-Object {
             if($_ -eq "Az")
             {
                 Set-ExecutionPolicy RemoteSigned
                 try {
                     Uninstall-AzureRm
                 }
                 catch {
                 }
             }
             if (-not (get-installedmodule -Name $_ -ErrorAction SilentlyContinue)) {
                 Write-Host "Installing module $_"
                 Install-Module $_ -Force -AllowClobber | Out-Null
             }
         }
         $modules | ForEach-Object { 
             Write-Host "Importing module $_"
             Import-Module $_ -DisableNameChecking -WarningAction SilentlyContinue | Out-Null
         }
     }
     end{
         Set-MpPreference -DisableRealtimeMonitoring $false
     }
 }

if([string]::IsNullOrEmpty($NuGet))
{
    Install-PackageProvider nuget -Scope CurrentUser -Force -Confirm:$false
}

installModules AZ,Azure.Storage,d365fo.tools

Get-D365LcsApiToken -ClientId $ClientId -Username $Username -Password $Password -LcsApiUri "https://lcsapi.lcs.dynamics.com" | Set-D365LcsApiConfig -ProjectId $ProjectId
$PSFObject = Invoke-D365LcsDeployment -AssetId $LCSFileAssetID -EnvironmentId $LCSEnvironmentID -UpdateName $UpdateName

do {
    Start-Sleep -Seconds 10
    $deploymentStatus = Get-D365LcsDeploymentStatus -ActivityId $PSFObject.ActivityId -EnvironmentId $LCSEnvironmentID -FailOnErrorMessage -SleepInSeconds 5

    if (($deploymentStatus.ErrorMessage) -or ($deploymentStatus.OperationStatus -eq "PreparationFailed")) {
        $messageString = "The request against LCS succeeded, but the response was an error message for the operation: <c='em'>$($deploymentStatus.ErrorMessage)</c>."
        $errorMessagePayload = "`r`n$($deploymentStatus | ConvertTo-Json)"
        Write-Error $errorMessagePayload
    }
    Write-Host $deploymentStatus.OperationStatus, $deploymentStatus.CompletionDate
}
while ((($deploymentStatus.OperationStatus -eq "InProgress") -or ($deploymentStatus.OperationStatus -eq "NotStarted") -or ($deploymentStatus.OperationStatus -eq "PreparingEnvironment")) -and $WaitForCompletion)
