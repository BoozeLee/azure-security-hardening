# Update GitHub & Stripe Contacts to the New Business Email

This document shows how to update public contact email in GitHub and Stripe.

## Update GitHub

1. Update your GitHub profile email:
   - Sign in to https://github.com/settings/profile
   - Set Email to `kiliaan@bakerstreetproject.com` (and make it public if desired)
2. Update Organization contact (requires org admin):
   - Go to https://github.com/organizations/YOUR_ORG/settings
   - Edit the 'Contact email' field to `support@bakerstreetproject.com`
3. Update Repository settings:
   - Repo -> Settings -> Manage access -> Add or update contact method
4. Add `support@bakerstreetproject.com` to CODEOWNERS or issue templates if needed.

## Update Stripe

1. In the Stripe Dashboard, Settings -> Business settings -> Public business information -> Support -> Edit email and change to `support+stripe@bakerstreetproject.com`.
2. Or via API using `stripe-update.sh` script (requires STRIPE_SECRET_KEY and account id):
```bash
export STRIPE_SECRET_KEY="sk_live_xxx"
./stripe-update.sh acct_12345
```

Note: Use Stripe test keys in dev/testing and live keys in production.
