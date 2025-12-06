# Microsoft 365 Domain & Business Email Setup

This file contains step-by-step guidance for creating a business email (kiliaan@bakerstreetproject.com) on Microsoft 365, setting up forwarding, and configuring SPF/DKIM/DMARC.

IMPORTANT: I cannot create the Microsoft 365 account or edit DNS for you, but this guide shows exactly how to do it.

## 1) Buy a domain
- Pick a registrar (Namecheap, GoDaddy, Cloudflare, etc.) and register `bakerstreetproject.com`.

## 2) Create Microsoft 365 subscription and add domain
1. Sign in to Microsoft 365 Admin Center as Global Admin: https://admin.microsoft.com
2. Go to `Setup` -> `Domains` -> `Add domain` and follow the wizard.
3. Verify domain ownership by adding DNS TXT record from the registrar.

## 3) Create a mailbox for `kiliaan@bakerstreetproject.com`
1. In Microsoft 365 Admin Center -> Users -> Active users -> Add a user. Create the mailbox.
2. Assign necessary roles (Exchange, licenses) for mail delivery.

## 4) Set up forwarding from existing accounts
### Gmail -> Microsoft 365
1. Sign in to Gmail (kiliaanv2@gmail.com, iamthatiamresearch@gmail.com).
2. Settings -> See all settings -> Forwarding and POP/IMAP -> Add a forwarding address -> Enter `kiliaan@bakerstreetproject.com`.
3. Gmail will send a verification code to `kiliaan@bakerstreetproject.com`. Retrieve it from the new account and confirm the forwarding.
4. Create a Gmail filter for each sender (kiliaanv2@gmail.com, iamthatiamresearch@gmail.com) and enable 'Forward to' the new address.

### Existing domain email -> Microsoft 365
If you control `bakerstreetproject221b.store`:
1. Create a forwarding rule in the Exchange Online Admin Center to forward incoming mail to `kiliaan@bakerstreetproject.com`.
2. Or, add an inbox rule in Outlook to forward messages to the new address.

## 5) SPF, DKIM, DMARC Setup
Add these DNS records at your domain registrar's DNS panel. Replace `yourdomain` with `bakerstreetproject.com`.

### SPF (TXT)
Name: @
Type: TXT
Value:
```
v=spf1 include:spf.protection.outlook.com -all
```

### DKIM (CNAME or via Microsoft 365 automatic setup)
Microsoft 365 will provide DKIM keys via the Exchange admin portal. If using manual CNAMEs, create two CNAME records as provided in the DKIM page for your domain.

### DMARC (TXT)
Name: _dmarc
Type: TXT
Value:
```
v=DMARC1; p=none; rua=mailto:postmaster@bakerstreetproject.com; ruf=mailto:postmaster@bakerstreetproject.com; pct=100
```
Change `p=none` to `quarantine` or `reject` after monitoring.

## 6) Enable DKIM and SPF verification
1. In Exchange Admin Center -> Protection -> DKIM -> Enable DKIM signing for your domain.
2. Use https://mxtoolbox.com to verify records.

## 7) Create aliases and sub-addressing
- Use `support@bakerstreetproject.com` as primary support address and `support+stripe@...` as Stripe-specific alias for receipts.
- Microsoft 365 supports plus-addressing by default; you can use `support+stripe@bakerstreetproject.com` without creating a separate mailbox.

## 8) Update docs and public listings
1. Replace personal emails with `kiliaan@bakerstreetproject.com` in all docs (done in repo).
2. Replace support addresses with `support@bakerstreetproject.com` and alias `support+stripe@bakerstreetproject.com` for Stripe receipts.

## 9) Update GitHub and Stripe
**GitHub**: Update organization contact details and `README.md` (done).
**Stripe**: Update `support_email` in the Stripe dashboard or via API to `support+stripe@bakerstreetproject.com`.

## 10) Test end-to-end
1. Send a test message from `kiliaanv2@gmail.com` to a test external address, verify it forwards to `kiliaan@bakerstreetproject.com`.
2. Trigger a Stripe webhook test (Stripe CLI) to verify webhook and GitHub dispatch flow.

If you want, I can prepare scripts to automate the mailbox creation (PowerShell) and the Exchange rules steps, but I need MS 365 admin credentials to run them.
