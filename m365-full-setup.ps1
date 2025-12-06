<#
m365-full-setup.ps1 - Orchestrates mailbox creation, license assignment, alias setup and optional forwarding.

This script will:
 - Install MSOnline and ExchangeOnlineManagement modules if missing
 - Connect to Azure AD and Exchange Online
 - Create a user/mailbox (with license if provided)
 - Assign license (if provided)
 - Add `support@` alias
 - Optionally configure forwarding from an old mailbox

Usage examples:
  Powershell run (prompts for credentials):
  .\m365-full-setup.ps1 -UserPrincipalName kiliaan@bakerstreetproject.com -DisplayName "Kiliaan Derks" -LicenseSku "contoso:ENTERPRISEPACK" -ForwardFrom old@bakerstreetproject221b.store

Note: Requires Global Admin account and email verification for forwarding.
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$UserPrincipalName,
    [Parameter(Mandatory=$true)]
    [string]$DisplayName,
    [Parameter(Mandatory=$false)]
    [string]$LicenseSku,
    [Parameter(Mandatory=$false)]
    [string]$ForwardFrom
)

function Install-ModuleIfMissing($name) {
    if (-not (Get-Module -ListAvailable -Name $name)) {
        Write-Output "Installing module $name..."
        Install-Module -Name $name -Force -AllowClobber -Scope CurrentUser
    } else {
        Write-Output "Module $name already installed"
    }
}

Install-ModuleIfMissing -name MSOnline
Install-ModuleIfMissing -name ExchangeOnlineManagement

Write-Output "Connect to MSOnline and Exchange Online. Please provide admin credentials when prompted."
Connect-MsolService
Connect-ExchangeOnline -UserPrincipalName (Read-Host -Prompt "Admin UPN")

# Password handling: uses environment variable NEW_USER_PASSWORD or prompt
$passwordPlain = $env:NEW_USER_PASSWORD
if (-not $passwordPlain) {
    $securePw = Read-Host -Prompt "Enter password for new user (will not be shown)" -AsSecureString
    $passwordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePw))
}

.
\m365-create-mailbox.ps1 -UserPrincipalName $UserPrincipalName -DisplayName $DisplayName -Password $passwordPlain -LicenseSku $LicenseSku

if ($LicenseSku) {
    .\m365-assign-license.ps1 -UserPrincipalName $UserPrincipalName -LicenseSku $LicenseSku
}

Write-Output "Adding support alias (support@ and support+stripe alias) to $UserPrincipalName"
Set-Mailbox -Identity $UserPrincipalName -EmailAddresses @{add="smtp:support@bakerstreetproject.com"}
Set-Mailbox -Identity $UserPrincipalName -EmailAddresses @{add="smtp:support+stripe@bakerstreetproject.com"}

if ($ForwardFrom) {
    Write-Output "Configuring forwarding for $ForwardFrom to $UserPrincipalName"
    Set-Mailbox -Identity $ForwardFrom -ForwardingSMTPAddress $UserPrincipalName -DeliverToMailboxAndForward $true
}

Write-Output "Mailbox setup complete. Verifying mailbox..."
Get-Mailbox -Identity $UserPrincipalName | Format-List DisplayName,PrimarySmtpAddress,EmailAddresses

Write-Output "All done!"
