<#
    .SYNOPSIS
        Dumps Office client registry info.

    .DESCRIPTION
        Dumps Office client registry info.

    .PARAMETER Computer
        The target or targets to be surveyed.

    .PARAMETER List
        Switch to tell the script that target is a file list.

    .NOTES
        Name: Get-OfficeClient
        Author: keyboardcrunch

    .EXAMPLE
        Get-OfficeClient -Computer MYMACHINE
#>

param (
    [alias('computer')]
    [string]$target = $(throw "-target is required."),
    [switch]$list
)

$ErrorActionPreference= 'silentlycontinue'
Write-Host "Target: $target" -ForegroundColor Yellow

if($list) {
    $devices = Get-Content $target | ? {$_} # bit after the pipe skips blank lines :)

    Foreach($device in $devices) {
        $device = $device -replace '\s','' # remove spaces from device string
        Write-Host "$device" -ForegroundColor Yellow

        if (Test-Connection -ComputerName $device -Count 3 -Quiet) {
            Invoke-Command -ComputerName $target -ScriptBlock { get-itemproperty -path HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration\ }
        } else {
            Write-Host "`tDevice offline!" -ForegroundColor Red
        }
   }
}
else {
    if (Test-Connection -ComputerName $target -Count 1 -Quiet) {
        Invoke-Command -ComputerName $target -ScriptBlock { get-itemproperty -path HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration\ }
    } else {
        Write-Host "`tDevice offline!" -ForegroundColor Red
    }
}
