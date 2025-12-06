<#
PowerShell script to create a user and mailbox in Microsoft 365 (Exchange Online).
Requires: Exchange Online and MS Online modules and Global Admin credentials.

Usage:
1. Install-Module MSOnline; Install-Module ExchangeOnlineManagement
2. Connect-MsolService; Connect-ExchangeOnline -UserPrincipalName admin@yourdomain.com
3. ./m365-create-mailbox.ps1 -UserPrincipalName kiliaan@bakerstreetproject.com -DisplayName "Kiliaan Derks" -Password "SecureP@ssw0rd"
#>

param(
  [Parameter(Mandatory=$true)]
  [string]$UserPrincipalName,
  [Parameter(Mandatory=$true)]
  [string]$DisplayName,
  [Parameter(Mandatory=$true)]
  [string]$Password
)

Write-Output "Creating user $UserPrincipalName with display name $DisplayName"

# Create user in Azure AD (via MSOnline module)
New-MsolUser -UserPrincipalName $UserPrincipalName -DisplayName $DisplayName -FirstName "Kiliaan" -LastName "Derks" -UsageLocation "US" -Password $Password

# Assign license to the user (replace SKU accordingly):
# Set license SKU (example: tenant:EXCHANGESHARED, or per your MS 365 SKU)
# $licenseSku = "mytenant:ENTERPRISEPACK"
# Set-MsolUserLicense -UserPrincipalName $UserPrincipalName -AddLicenses $licenseSku

Write-Output "User created. Please assign a license to enable the mailbox in the Microsoft 365 Admin Center or via script."
