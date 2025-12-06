<#
Script to assign an Office 365 license SKU to a user.
Usage:
  .\m365-assign-license.ps1 -UserPrincipalName user@domain.com -LicenseSku yourtenant:ENTERPRISEPACK
#>
param(
  [Parameter(Mandatory=$true)]
  [string]$UserPrincipalName,
  [Parameter(Mandatory=$true)]
  [string]$LicenseSku
)

Write-Output "Assigning $LicenseSku to $UserPrincipalName"
Set-MsolUserLicense -UserPrincipalName $UserPrincipalName -AddLicenses $LicenseSku

Write-Output "Done. Verify license with: Get-MsolUser -UserPrincipalName $UserPrincipalName | Select-Object Licenses"
