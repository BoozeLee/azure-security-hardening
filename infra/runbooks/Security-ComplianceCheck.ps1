<#
.SYNOPSIS
    Security Compliance Check Runbook

.DESCRIPTION
    Automated security compliance scanning for Azure resources.
    Checks for common security misconfigurations and reports findings.
    
    Note: For large environments with many VMs, consider using parallel processing
    or Azure Policy for more efficient compliance checking at scale.

.NOTES
    Requires: System-assigned managed identity with Reader role
    Performance: Sequential scanning suitable for small-medium environments
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId = "",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = ""
)

# Connect using System-assigned Managed Identity
try {
    Write-Output "Connecting to Azure using Managed Identity..."
    Connect-AzAccount -Identity -ErrorAction Stop
    Write-Output "Successfully connected to Azure"
}
catch {
    Write-Error "Failed to connect to Azure: $_"
    exit 1
}

# Select subscription if provided
if ($SubscriptionId) {
    Write-Output "Selecting subscription: $SubscriptionId"
    Select-AzSubscription -SubscriptionId $SubscriptionId
}

# Initialize compliance report
$complianceReport = @{
    Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    Subscription = (Get-AzContext).Subscription.Name
    Findings = @()
}

Write-Output "Starting security compliance check..."

# Check 1: Storage Accounts - Secure Transfer Required
Write-Output "Checking Storage Accounts for secure transfer..."
if ($ResourceGroupName) {
    $storageAccounts = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
} else {
    $storageAccounts = Get-AzStorageAccount -ErrorAction SilentlyContinue
}
foreach ($sa in $storageAccounts) {
    if (-not $sa.EnableHttpsTrafficOnly) {
        $finding = @{
            ResourceType = "StorageAccount"
            ResourceName = $sa.StorageAccountName
            Issue = "HTTPS-only traffic not enforced"
            Severity = "High"
            Recommendation = "Enable 'Secure transfer required'"
        }
        $complianceReport.Findings += $finding
        Write-Warning "FINDING: Storage Account '$($sa.StorageAccountName)' does not enforce HTTPS"
    }
}

# Check 2: Virtual Machines - Managed Disks Encryption
Write-Output "Checking VMs for disk encryption..."
if ($ResourceGroupName) {
    $vms = Get-AzVM -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
} else {
    $vms = Get-AzVM -ErrorAction SilentlyContinue
}
foreach ($vm in $vms) {
    $diskEncryption = Get-AzVMDiskEncryptionStatus -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -ErrorAction SilentlyContinue
    if ($diskEncryption -and $diskEncryption.OsVolumeEncrypted -ne "Encrypted") {
        $finding = @{
            ResourceType = "VirtualMachine"
            ResourceName = $vm.Name
            Issue = "OS disk not encrypted"
            Severity = "Critical"
            Recommendation = "Enable Azure Disk Encryption"
        }
        $complianceReport.Findings += $finding
        Write-Warning "FINDING: VM '$($vm.Name)' OS disk is not encrypted"
    }
}

# Check 3: Network Security Groups - Unrestricted RDP/SSH
Write-Output "Checking NSGs for unrestricted RDP/SSH access..."
if ($ResourceGroupName) {
    $nsgs = Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
} else {
    $nsgs = Get-AzNetworkSecurityGroup -ErrorAction SilentlyContinue
}
foreach ($nsg in $nsgs) {
    foreach ($rule in $nsg.SecurityRules) {
        if (($rule.DestinationPortRange -contains "22" -or $rule.DestinationPortRange -contains "3389") -and 
            $rule.SourceAddressPrefix -eq "*" -and 
            $rule.Access -eq "Allow") {
            $finding = @{
                ResourceType = "NetworkSecurityGroup"
                ResourceName = $nsg.Name
                Issue = "Unrestricted inbound access on port $($rule.DestinationPortRange)"
                Severity = "Critical"
                Recommendation = "Restrict source IP ranges for RDP/SSH access"
            }
            $complianceReport.Findings += $finding
            Write-Warning "FINDING: NSG '$($nsg.Name)' allows unrestricted access on port $($rule.DestinationPortRange)"
        }
    }
}

# Check 4: Key Vaults - Soft Delete and Purge Protection
Write-Output "Checking Key Vaults for soft delete and purge protection..."
if ($ResourceGroupName) {
    $keyVaults = Get-AzKeyVault -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
} else {
    $keyVaults = Get-AzKeyVault -ErrorAction SilentlyContinue
}
foreach ($kv in $keyVaults) {
    $kvDetails = Get-AzKeyVault -VaultName $kv.VaultName
    if (-not $kvDetails.EnableSoftDelete) {
        $finding = @{
            ResourceType = "KeyVault"
            ResourceName = $kv.VaultName
            Issue = "Soft delete not enabled"
            Severity = "High"
            Recommendation = "Enable soft delete protection"
        }
        $complianceReport.Findings += $finding
        Write-Warning "FINDING: Key Vault '$($kv.VaultName)' does not have soft delete enabled"
    }
    if (-not $kvDetails.EnablePurgeProtection) {
        $finding = @{
            ResourceType = "KeyVault"
            ResourceName = $kv.VaultName
            Issue = "Purge protection not enabled"
            Severity = "Medium"
            Recommendation = "Enable purge protection"
        }
        $complianceReport.Findings += $finding
        Write-Warning "FINDING: Key Vault '$($kv.VaultName)' does not have purge protection enabled"
    }
}

# Summary
$totalFindings = $complianceReport.Findings.Count
Write-Output "`n=========================================="
Write-Output "Security Compliance Check Complete"
Write-Output "=========================================="
Write-Output "Total Findings: $totalFindings"

if ($totalFindings -eq 0) {
    Write-Output "✅ No security issues found - All checks passed!"
}
else {
    $critical = ($complianceReport.Findings | Where-Object { $_.Severity -eq "Critical" }).Count
    $high = ($complianceReport.Findings | Where-Object { $_.Severity -eq "High" }).Count
    $medium = ($complianceReport.Findings | Where-Object { $_.Severity -eq "Medium" }).Count
    
    Write-Output "⚠️  Critical: $critical"
    Write-Output "⚠️  High: $high"
    Write-Output "⚠️  Medium: $medium"
    
    Write-Output "`nDetailed Findings:"
    foreach ($finding in $complianceReport.Findings) {
        Write-Output "  - [$($finding.Severity)] $($finding.ResourceType)/$($finding.ResourceName): $($finding.Issue)"
    }
}

Write-Output "=========================================="

# Return compliance report as JSON
$complianceReport | ConvertTo-Json -Depth 10
