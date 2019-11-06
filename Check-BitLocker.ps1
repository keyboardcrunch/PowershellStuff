<#
.SYNOPSIS
Checks BitLocker for configuration issues.

.DESCRIPTION
Verifies Bitlocker and TPM settings with the option to repair issues.

.PARAMETER ComputerName
The device to review or repair.

.PARAMETER Fix
Optional argument to fix issues with BitLocker and TPM.

.EXAMPLE
Check-Bitlocker.ps1 -ComputerName JuneauPC

.EXAMPLE
Check-Bitlocker.ps1 -ComputerName JuneauPC -Fix

.AUTHOR
keyboardcrunch
#>

param (
    [string]$ComputerName = $(throw "-ComputerName is required."),
    [switch]$Fix
)

$ErrorActionPreference = "Continue"

If ( Test-Connection -ComputerName $ComputerName -Count 3 -Quiet ) { 
    If ($Fix) {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            Write-Host "Gathering BitLocker status..." -ForegroundColor Yellow
            $TPM = Get-TPM
            $BL = Get-BitLockerVolume -MountPoint C:
            $Status = [PSCustomObject] @{
                MountPoint = $BL.MountPoint
                VolumeStatus = $BL.VolumeStatus
                ProtectionStatus = $BL.ProtectionStatus
                EncryptionPercentage = $BL.EncryptionPercentage
                TpmPresent = $TPM.TpmPresent
                TpmReady = $TPM.TpmReady
                KeyProtector = $BL.KeyProtector
            }
            Write-Host "Suspending BitLocker for maintenance..." -ForegroundColor Yellow
            Suspend-BitLocker -MountPoint C:
            If ( $TPM.TpmReady -eq $false ) {
                Write-Host "Clearing and re-initializing TPM..." -ForegroundColor Yellow
                Clear-TPM
                Initialize-TPM
            }            
            If ( $TPM.TpmPresent -eq $false ) {
                Write-Host "TPM is not present! `r`nBIOS reset or further action required!" -ForegroundColor Red
            }
            If ( $BL.KeyProtector.KeyProtectorType -notcontains "Tpm" ) {
                Write-Host "Adding TPM as unlock method for BitLocker..." -ForegroundColor Yellow
                Manage-bde -protectors -add C: -tpm
            } Else {
                Write-Host "Re-registering TPM as unlock method for BitLocker..." -ForegroundColor Yellow
                Manage-bde -protectors -delete C: -type TPM
                Manage-bde -protectors -add C: -tpm
            }
            Write-Host "Resuming BitLocker..." -ForegroundColor Yellow
            Resume-BitLocker -MountPoint C:

            Write-Host "Gathering BitLocker status again..." -ForegroundColor Yellow
            $TPM = Get-TPM
            $BL = Get-BitLockerVolume -MountPoint C:
            Return $Status
        }
    } Else {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            $ErrorCount = 0
            Write-Host "Gathering BitLocker status..."
            $TPM = Get-TPM
            $BL = Get-BitLockerVolume -MountPoint C:
            $Status = [PSCustomObject] @{
                MountPoint = $BL.MountPoint
                VolumeStatus = $BL.VolumeStatus
                ProtectionStatus = $BL.ProtectionStatus
                EncryptionPercentage = $BL.EncryptionPercentage
                TpmPresent = $TPM.TpmPresent
                TpmReady = $TPM.TpmReady
                KeyProtector = $BL.KeyProtector
            }
            If ( $TPM.TpmReady -eq $false ) {
                Write-Host "[WARN] TPM is not ready!" -ForegroundColor Yellow
            }            
            If ( $TPM.TpmPresent -eq $false ) {
                Write-Host "[ERR] TPM is not present!" -ForegroundColor Red
                $ErrorCount++
            }
            If ( $BL.KeyProtector.KeyProtectorType -notcontains "Tpm" ) {
                Write-Host "[ERR] BitLocker missing TPM for unlock!" -ForegroundColor Red
                $ErrorCount++
            }
            If ( $BL.ProtectionStatus -ne "On" ) {
                Write-Host "[WARN] BitLocker is turned off!" -ForegroundColor Yellow
            }
            If ($ErrorCount -gt 0) {
                Write-Host "`r`nErrors found:`r`nRe-run with -Fix to correct the issues." -ForegroundColor Yellow
            }
            Return $Status
        }
    }
} Else {
    Write-Host "$ComputerName is offline!" -ForegroundColor Red
}
