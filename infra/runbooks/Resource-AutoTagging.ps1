<#
.SYNOPSIS
    Resource Auto-Tagging Runbook

.DESCRIPTION
    Automatically tags Azure resources for compliance and governance.
    Applies standard tags based on resource type, location, and naming conventions.

.NOTES
    Requires: System-assigned managed identity with Contributor role
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId = "",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = "Production"
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

# Define standard tags
$standardTags = @{
    "ManagedBy" = "Automation"
    "LastTagged" = (Get-Date -Format "yyyy-MM-dd")
    "Environment" = $Environment
    "ComplianceRequired" = "true"
}

Write-Output "Starting resource auto-tagging process..."
Write-Output "Standard tags to apply: $($standardTags | ConvertTo-Json -Compress)"

# Initialize counters
$totalResources = 0
$taggedResources = 0
$skippedResources = 0
$errors = 0

# Get all resources in the resource group (or subscription if no RG specified)
if ($ResourceGroupName) {
    Write-Output "Fetching resources from Resource Group: $ResourceGroupName"
    $resources = Get-AzResource -ResourceGroupName $ResourceGroupName
}
else {
    Write-Output "Fetching all resources in subscription"
    $resources = Get-AzResource
}

$totalResources = $resources.Count
Write-Output "Found $totalResources resources to process"

# Process each resource
foreach ($resource in $resources) {
    try {
        Write-Output "Processing: $($resource.ResourceType)/$($resource.Name)"
        
        # Get current tags
        $currentTags = $resource.Tags
        if (-not $currentTags) {
            $currentTags = @{}
        }
        
        # Merge with standard tags (preserve existing, add missing)
        $mergedTags = $currentTags.Clone()
        $tagsAdded = $false
        
        foreach ($key in $standardTags.Keys) {
            if (-not $mergedTags.ContainsKey($key)) {
                $mergedTags[$key] = $standardTags[$key]
                $tagsAdded = $true
                Write-Output "  Adding tag: $key = $($standardTags[$key])"
            }
        }
        
        # Add resource-type specific tags
        switch -Wildcard ($resource.ResourceType) {
            "Microsoft.Storage/storageAccounts" {
                if (-not $mergedTags.ContainsKey("DataClassification")) {
                    $mergedTags["DataClassification"] = "Confidential"
                    $tagsAdded = $true
                }
            }
            "Microsoft.KeyVault/vaults" {
                if (-not $mergedTags.ContainsKey("SecurityLevel")) {
                    $mergedTags["SecurityLevel"] = "Critical"
                    $tagsAdded = $true
                }
            }
            "Microsoft.Compute/virtualMachines" {
                if (-not $mergedTags.ContainsKey("BackupRequired")) {
                    $mergedTags["BackupRequired"] = "true"
                    $tagsAdded = $true
                }
            }
            "Microsoft.Network/*" {
                if (-not $mergedTags.ContainsKey("NetworkZone")) {
                    $mergedTags["NetworkZone"] = "Restricted"
                    $tagsAdded = $true
                }
            }
        }
        
        # Apply tags if any were added
        if ($tagsAdded) {
            Write-Output "  Updating tags on resource..."
            Set-AzResource -ResourceId $resource.ResourceId -Tag $mergedTags -Force | Out-Null
            $taggedResources++
            Write-Output "  ✅ Successfully tagged: $($resource.Name)"
        }
        else {
            Write-Output "  ⏭️  All required tags already present, skipping"
            $skippedResources++
        }
    }
    catch {
        Write-Error "  ❌ Failed to tag resource $($resource.Name): $_"
        $errors++
    }
}

# Summary
Write-Output "`n=========================================="
Write-Output "Resource Auto-Tagging Complete"
Write-Output "=========================================="
Write-Output "Total Resources Processed: $totalResources"
Write-Output "Successfully Tagged: $taggedResources"
Write-Output "Skipped (already tagged): $skippedResources"
Write-Output "Errors: $errors"
Write-Output "=========================================="

# Create summary object
$summary = @{
    Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    Subscription = (Get-AzContext).Subscription.Name
    ResourceGroup = $ResourceGroupName
    TotalResources = $totalResources
    TaggedResources = $taggedResources
    SkippedResources = $skippedResources
    Errors = $errors
    StandardTags = $standardTags
}

# Return summary as JSON
$summary | ConvertTo-Json -Depth 10
