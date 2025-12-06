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
  [Parameter(Mandatory=$false)]
  [string]$Password,
  [Parameter(Mandatory=$false)]
  [string]$LicenseSku
)

Write-Output "Creating user $UserPrincipalName with display name $DisplayName"

# Determine password: use provided, environment variable, or prompt securely
if (-not $Password) {
  if ($env:NEW_USER_PASSWORD) {
    $Password = $env:NEW_USER_PASSWORD
    Write-Output "Using NEW_USER_PASSWORD environment variable"
  }
  else {
    $securePw = Read-Host -Prompt "Enter a strong password for the new user (will not be shown)" -AsSecureString
    $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePw))
  }
}

# Create user in Azure AD (via MSOnline module)

New-MsolUser -UserPrincipalName $UserPrincipalName -DisplayName $DisplayName -FirstName "Kiliaan" -LastName "Derks" -UsageLocation "US" -Password $Password

# Assign license to the user if provided
if ($LicenseSku) {
  Write-Output "Assigning license $LicenseSku to $UserPrincipalName"
  Set-MsolUserLicense -UserPrincipalName $UserPrincipalName -AddLicenses $LicenseSku
}

Write-Output "User created. Please assign a license to enable the mailbox in the Microsoft 365 Admin Center or via script."
