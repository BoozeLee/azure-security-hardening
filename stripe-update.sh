#!/usr/bin/env bash
# Update Stripe account's support email via Stripe API
# Requires: STRIPE_SECRET_KEY env var set with your Stripe secret key

set -e

if [ -z "$STRIPE_SECRET_KEY" ]; then
  echo "Please set STRIPE_SECRET_KEY environment variable"
  exit 1
fi

ACCOUNT_ID="$1"
SUPPORT_EMAIL="support+stripe@bakerstreetproject.com"

if [ -z "$ACCOUNT_ID" ]; then
  echo "Usage: $0 <stripe_account_id>"
  exit 1
fi

curl https://api.stripe.com/v1/accounts/$ACCOUNT_ID \
  -u $STRIPE_SECRET_KEY: \
  -d "support[email]=$SUPPORT_EMAIL"

echo "Stripe support email updated to $SUPPORT_EMAIL"
