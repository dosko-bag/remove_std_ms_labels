# =====================================================================
# Microsoft Purview
# Remove Microsoft Default Sensitivity Labels
# + Remove Global Sensitivity Label Policy
#
# Purpose:
# Removal of the default Microsoft labels and policy to prepare for
# the customer-specific sensitivity label configuration.
# =====================================================================

$ErrorActionPreference = "Stop"


# =====================================================================
# 1. Connect to Microsoft Purview / Security & Compliance PowerShell
# =====================================================================

Write-Host ""
Write-Host "=== Connecting to Microsoft Purview ===" -ForegroundColor Cyan

# Load the Exchange Online Management module
Import-Module ExchangeOnlineManagement -ErrorAction Stop

# Connect only if the Purview cmdlets are not already available
if (-not (Get-Command Get-Label -ErrorAction SilentlyContinue)) {

    Write-Host "Connecting to Microsoft Purview..." `
        -ForegroundColor Yellow

    Connect-IPPSSession `
        -ShowBanner:$false `
        -ErrorAction Stop

    Write-Host "[OK] Connection established." `
        -ForegroundColor Green
}
else {

    Write-Host "[OK] Microsoft Purview connection already available." `
        -ForegroundColor Green
}


# ===========================================================================================
# 2. Define Microsoft Default Sensitivity Labels -> change the id`s in case they don`t match!
# ===========================================================================================

$MicrosoftDefaultLabelIds = @(

    "defa4170-0d19-0005-0000-bc88714345d2", # Personal
    "defa4170-0d19-0005-0001-bc88714345d2", # Public
    "defa4170-0d19-0005-0002-bc88714345d2", # General

    "defa4170-0d19-0005-0003-bc88714345d2", # Anyone (unrestricted)
    "defa4170-0d19-0005-0004-bc88714345d2", # All Employees (unrestricted)

    "defa4170-0d19-0005-0005-bc88714345d2", # Confidential

    "defa4170-0d19-0005-0006-bc88714345d2", # Anyone (unrestricted)
    "defa4170-0d19-0005-0007-bc88714345d2", # All Employees
    "defa4170-0d19-0005-0008-bc88714345d2", # Trusted People

    "defa4170-0d19-0005-0009-bc88714345d2", # Highly Confidential

    "defa4170-0d19-0005-000a-bc88714345d2", # All Employees
    "defa4170-0d19-0005-000b-bc88714345d2"  # Specified People
)


# =====================================================================
# 3. Identify Microsoft Default Labels to Remove
# =====================================================================

Write-Host ""
Write-Host "=== Microsoft Default Sensitivity Labels ===" `
    -ForegroundColor Cyan

$LabelsToDelete = @(
    Get-Label |
        Where-Object {
            $_.Name -in $MicrosoftDefaultLabelIds
        }
)

$LabelsToDelete |
    Select-Object DisplayName, Name, ParentId |
    Format-Table -AutoSize

Write-Host "Default labels found: $($LabelsToDelete.Count)" `
    -ForegroundColor Yellow


# =====================================================================
# 4. Remove Global Sensitivity Label Policy
# =====================================================================

Write-Host ""
Write-Host "=== Global Sensitivity Label Policy ===" `
    -ForegroundColor Cyan

$GlobalPolicies = @(
    Get-LabelPolicy |
        Where-Object {
            $_.Name -eq "Global" -or
            $_.Name -eq "Global Policy"
        }
)


if ($GlobalPolicies.Count -eq 0) {

    Write-Host "No Global Label Policy found." `
        -ForegroundColor DarkGray

}
else {

    foreach ($Policy in $GlobalPolicies) {

        Write-Host "Removing policy: $($Policy.Name)" `
            -ForegroundColor Yellow

        try {

            Remove-LabelPolicy `
                -Identity $Policy.Guid `
                -Confirm:$false `
                -ErrorAction Stop

            Write-Host "[OK] Policy '$($Policy.Name)' removed." `
                -ForegroundColor Green
        }
        catch {

            Write-Host "[ERROR] Policy '$($Policy.Name)' could not be removed:" `
                -ForegroundColor Red

            Write-Host $_.Exception.Message `
                -ForegroundColor Red
        }
    }
}


# =====================================================================
# 5. Remove Microsoft Sublabels First
# =====================================================================

Write-Host ""
Write-Host "=== Removing Sublabels ===" `
    -ForegroundColor Cyan

$ChildLabels = @(
    $LabelsToDelete |
        Where-Object {
            $null -ne $_.ParentId -and
            $_.ParentId.ToString().Trim() -ne ""
        }
)


foreach ($Label in $ChildLabels) {

    Write-Host "Removing sublabel: $($Label.DisplayName)" `
        -ForegroundColor Yellow

    try {

        Remove-Label `
            -Identity $Label.Name `
            -Confirm:$false `
            -ErrorAction Stop

        Write-Host "[OK] $($Label.DisplayName)" `
            -ForegroundColor Green
    }
    catch {

        Write-Host "[ERROR] $($Label.DisplayName): $($_.Exception.Message)" `
            -ForegroundColor Red
    }
}


# =====================================================================
# 6. Remove Microsoft Parent Labels
# =====================================================================

Write-Host ""
Write-Host "=== Removing Parent Labels ===" `
    -ForegroundColor Cyan

$ParentLabels = @(
    $LabelsToDelete |
        Where-Object {
            $null -eq $_.ParentId -or
            $_.ParentId.ToString().Trim() -eq ""
        }
)


foreach ($Label in $ParentLabels) {

    Write-Host "Removing parent label: $($Label.DisplayName)" `
        -ForegroundColor Yellow

    try {

        Remove-Label `
            -Identity $Label.Name `
            -Confirm:$false `
            -ErrorAction Stop

        Write-Host "[OK] $($Label.DisplayName)" `
            -ForegroundColor Green
    }
    catch {

        Write-Host "[ERROR] $($Label.DisplayName): $($_.Exception.Message)" `
            -ForegroundColor Red
    }
}


# =====================================================================
# 7. Final Verification
# =====================================================================

Write-Host ""
Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host " Final Verification" `
    -ForegroundColor Cyan

Write-Host "============================================================" `
    -ForegroundColor Cyan


Write-Host ""
Write-Host "Remaining Sensitivity Labels:" `
    -ForegroundColor Cyan

Get-Label |
    Select-Object DisplayName, Name, ParentId |
    Format-Table -AutoSize


Write-Host ""
Write-Host "Remaining Label Policies:" `
    -ForegroundColor Cyan

Get-LabelPolicy |
    Select-Object Name, Guid |
    Format-Table -AutoSize


Write-Host ""
Write-Host "=== Operation completed ===" `
    -ForegroundColor Green
