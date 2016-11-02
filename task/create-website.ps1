[CmdletBinding()]
param(
    [string]$server,
    [string]$webSiteName,
    [string]$appPoolName,
    [string]$portNumber,
    [string]$filePath
)

Import-Module "Microsoft.TeamFoundation.DistributedTask.Task.Internal"
Import-Module "Microsoft.TeamFoundation.DistributedTask.Task.Common"

Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
Write-Verbose "Parameter Values"
$PSBoundParameters.Keys | % { Write-HOST "  ${_} = $($PSBoundParameters[$_])" }

$command = {
    param(
        [string]$webSiteName,
        [string]$appPoolName,
        [string]$portNumber,
        [string]$filePath
    )
    Import-Module WebAdministration
    Write-Host "Starting Create Web Site Task"
    $appPoolPath = "IIS:\AppPools\$AppPoolName"
    Write-Host "Checking for application pool: '$appPoolName'"
    if(-Not (Test-Path $appPoolPath)) {
        Write-Host "Creating Application Pool with default settings"
        $appPool = New-Item –Path $appPoolPath
        $appPool.managedRuntimeVersion = "v4.0"
        $appPool.managedPipeLineMode = "Integrated"
        Write-Host "Application Pool created."
    } else {
        Write-Host "Application Pool exist"
    }
    $webAppPath = "IIS:\Sites\$webSiteName"
    Write-Host "Checking for site '$webSiteName'"
    if (Test-Path $webAppPath) { 
        Write-Host "$webSiteName exists. Skipping Task" 
    } else {
        Write-Host "Creating web site '$webSiteName'"
        New-Website -Name $webSiteName -ApplicationPool $appPoolName  -Force -PhysicalPath $filePath  -Port $portNumber
        Write-Host "Created web site '$webSiteName'"
    }
    $currentAppPool = (Get-Item $webAppPath | Select applicationPool).applicationPool
    Write-Host "Current Application Pool: $currentAppPool"
    if ($appPoolName -ne $currentAppPool){
        write-host "Changing Application Pool to $appPoolName"
        Set-ItemProperty $webAppPath -name applicationPool  -value $appPoolName -force
        $currentAppPool = (Get-Item $webAppPath | Select applicationPool).applicationPool
        Write-Host "Current Application Pool: $currentAppPool"
    }
    Write-Host "Create WebSite Task Completed."
}

Invoke-Command -ComputerName $server $command -ArgumentList $webSiteName,$appPoolName,$portNumber,$filePath