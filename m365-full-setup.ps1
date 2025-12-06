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
#
# New: Non-interactive certificate automation
# - `KeyVaultName` and `SPAppName` arguments can be passed (or via environment variables) to let the script fetch the SPN certificate from KeyVault.
# - Standard KeyVault secret naming conventions:
#   - `spn-<AppName>-pfx-password`
#   - `spn-<AppName>-cert-name` (the certificate resource name in KeyVault)
#   - `spn-<AppName>-thumbprint` (optional; used to avoid PFX import)
# Examples:
#   - `pwsh ./m365-full-setup.ps1 -AuthMode Certificate -SPClientId <id> -SPTenantId <tenant> -SPAppName my-automation-app -KeyVaultName myKeyVault`
#
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$UserPrincipalName,
    [Parameter(Mandatory=$true)]
    [string]$DisplayName,
    [Parameter(Mandatory=$false)]
    [string]$LicenseSku,
    [Parameter(Mandatory=$false)]
    [string]$ForwardFrom,
    [Parameter(Mandatory=$false)]
    [ValidateSet('Interactive','ServicePrincipal','Certificate')]
    [string]$AuthMode = 'Interactive',
    [Parameter(Mandatory=$false)]
    [string]$SPClientId,
    [Parameter(Mandatory=$false)]
    [string]$SPTenantId,
    [Parameter(Mandatory=$false)]
    [string]$SPThumbprint
    ,
    [Parameter(Mandatory=$false)]
    [string]$KeyVaultName = $env:KEY_VAULT_NAME,
    [Parameter(Mandatory=$false)]
    [string]$SPAppName = $env:SP_APP_NAME
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

Write-Output "Connect to MSOnline and Exchange Online."
if ($AuthMode -eq 'Interactive') {
    Connect-MsolService
    $adminUpn = Read-Host -Prompt "Admin UPN"
    Connect-ExchangeOnline -UserPrincipalName $adminUpn
} elseif ($AuthMode -eq 'ServicePrincipal' -or $AuthMode -eq 'Certificate') {
    if (-not $SPClientId -or -not $SPTenantId) {
        throw "AuthMode requires SPClientId and SPTenantId"
    }
    # If SPThumbprint is not provided, attempt to fetch from Key Vault if KeyVaultName and SPAppName are present
    if (-not $SPThumbprint) {
        if (-not $KeyVaultName -or -not $SPAppName) {
            throw "AuthMode requires SPClientId and SPTenantId and either SPThumbprint or both KeyVaultName and SPAppName to fetch certificate."
        }
        Write-Output "Attempting to resolve certificate from Key Vault: $KeyVaultName using SPAppName: $SPAppName"
        # Build standardized secret names
        $secretPfxName = "spn-$SPAppName-pfx-password"
        $certNameSecret = "spn-$SPAppName-cert-name"

        # detect az CLI
        if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
            throw "Azure CLI (az) must be installed and logged in to fetch Key Vault secrets"
        }

        # Attempt to fetch a pre-recorded thumbprint first
        $thumbprintSecret = "spn-$SPAppName-thumbprint"
        $thumbFromVault = $null
        try {
            $thumbFromVault = az keyvault secret show --vault-name $KeyVaultName --name $thumbprintSecret --query value -o tsv 2>$null | Out-String
            $thumbFromVault = $thumbFromVault.Trim()
        } catch {
            $thumbFromVault = $null
        }
        if ($thumbFromVault) {
            Write-Output "Found thumbprint for $SPAppName in Key Vault, using thumbprint $thumbFromVault"
            $SPThumbprint = $thumbFromVault
        }

        # Fetch the certificate name stored in KeyVault (if any)
        $certName = $null
        try {
            $certName = az keyvault secret show --name $certNameSecret --vault-name $KeyVaultName --query value -o tsv 2>$null | Out-String
            $certName = $certName.Trim()
        } catch {
            Write-Output "No cert-name secret found in KeyVault for $certNameSecret; falling back to default name spn-$SPAppName-cert"
            $certName = "spn-$SPAppName-cert"
        }

        # fetch pfx (Base64) if the certificate was stored as a secret containing the pfx
        Write-Output "Fetching certificate secret from Key Vault: $certName"
        $pfxBase64 = az keyvault secret show --vault-name $KeyVaultName --name $certName --query value -o tsv 2>$null | Out-String
        if (-not $pfxBase64) {
            throw "No certificate secret with name $certName found in Key Vault $KeyVaultName"
        }
        $pfxBase64 = $pfxBase64.Trim()

        # fetch password
        Write-Output "Fetching PFX password secret: $secretPfxName"
        $pfxPassword = az keyvault secret show --vault-name $KeyVaultName --name $secretPfxName --query value -o tsv 2>$null | Out-String
        if (-not $pfxPassword) {
            throw "No PFX password secret named $secretPfxName in Key Vault $KeyVaultName"
        }
        $pfxPassword = $pfxPassword.Trim()

        # write pfx to a temporary file and import
        $tempPfx = Join-Path -Path $env:TEMP -ChildPath ("$SPAppName.pfx")
        [System.IO.File]::WriteAllBytes($tempPfx, [System.Convert]::FromBase64String($pfxBase64))
        $securePwd = ConvertTo-SecureString -String $pfxPassword -AsPlainText -Force
        Write-Output "Importing PFX into personal certificate store"
        Import-PfxCertificate -FilePath $tempPfx -CertStoreLocation Cert:\CurrentUser\My -Password $securePwd | Out-Null

        # find the imported certificate by subject or thumbprint
        $cert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.HasPrivateKey -eq $true -and $_.Subject -like "*CN=$SPAppName*" } | Select-Object -First 1
        if (-not $cert) {
            # fallback: get the latest cert with private key
            $cert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.HasPrivateKey -eq $true } | Sort-Object NotBefore -Descending | Select-Object -First 1
        }
        if (-not $cert) { throw "Failed to locate imported certificate in store" }
        $SPThumbprint = $cert.Thumbprint
        Write-Output "Using certificate thumbprint: $SPThumbprint"
    }
    Write-Output "Connecting with appId $SPClientId and cert thumbprint $SPThumbprint"
    # Non-interactive cert-based login
    Connect-ExchangeOnline -CertificateThumbprint $SPThumbprint -AppId $SPClientId -Organization $SPTenantId -Verbose
    # Connect to Graph too for user creation if needed
    Import-Module Microsoft.Graph.Identity.Directory
    Connect-MgGraph -ClientId $SPClientId -TenantId $SPTenantId -CertificateThumbprint $SPThumbprint
} else {
    throw "Unknown AuthMode: $AuthMode"
}

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
