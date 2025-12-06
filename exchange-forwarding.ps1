<#
PowerShell script to forward mailbox contents from an old address to the new business mailbox.
Requires Exchange Online PowerShell module and Global Admin credentials.

Usage (powershell.exe):
1. Install-Module ExchangeOnlineManagement
2. Connect-ExchangeOnline -UserPrincipalName admin@yourdomain.com
3. ./exchange-forwarding.ps1 -SourceMailbox old@domain.com -DestinationMailbox kiliaan@bakerstreetproject.com
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SourceMailbox,
    [Parameter(Mandatory=$true)]
    [string]$DestinationMailbox
)

Write-Output "Configuring forwarding from $SourceMailbox to $DestinationMailbox"

Set-Mailbox -Identity $SourceMailbox -ForwardingSMTPAddress $DestinationMailbox -DeliverToMailboxAndForward $true
Write-Output "Forwarding rule created. Please verify at the destination mailbox."
