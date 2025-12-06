#!/usr/bin/env python3
"""
Simple Stripe webhook receiver that verifies signature and triggers
GitHub repository dispatch (repository_dispatch) as a secure way to
connect Stripe events to your GitHub Actions workflows.

Usage (dev):
1. pip install -r requirements.txt (flask stripe requests)
2. STRIPE_WEBHOOK_SECRET=whsec_... GH_PAT=ghp_xxx python3 stripe_webhook_server.py
3. Use stripe CLI to forward events: stripe listen --forward-to http://localhost:5000/webhook
"""

from flask import Flask, request, jsonify
import os
import hmac
import hashlib
import json
import requests

app = Flask(__name__)

STRIPE_WEBHOOK_SECRET = os.getenv('STRIPE_WEBHOOK_SECRET')
GITHUB_PAT = os.getenv('GH_PAT')
GITHUB_OWNER = os.getenv('GITHUB_OWNER', 'BoozeLee')
GITHUB_REPO = os.getenv('GITHUB_REPO', 'azure-security-hardening')

def verify_signature(raw_body, sig_header, secret):
    # Verify Stripe signature - this is a simplified implementation for demo
    # For production use the official Stripe library's webhook construct
    if not secret:
        return True
    try:
        # Using stripe library is recommended; fallback naive check
        import stripe
        stripe.api_key = os.getenv('STRIPE_SECRET_KEY')
        event = stripe.Webhook.construct_event(raw_body, sig_header, secret)
        return True, event
    except Exception as e:
        return False, str(e)

@app.route('/webhook', methods=['POST'])
def webhook():
    payload = request.data
    sig_header = request.headers.get('Stripe-Signature')

    ok, event_or_err = verify_signature(payload, sig_header, STRIPE_WEBHOOK_SECRET)
    if not ok:
        return jsonify({'error': str(event_or_err)}), 400

    event = event_or_err
    # For simplicity, allow event to be dict when Stripe lib not installed
    if not isinstance(event, dict):
        try:
            event = json.loads(payload)
        except Exception:
            event = {}

    # Example: respond to checkout.session.completed
    if event.get('type') in ('checkout.session.completed', 'payment_intent.succeeded', 'invoice.payment_succeeded'):
        customer_email = event.get('data', {}).get('object', {}).get('customer_email', 'unknown@example.com')
        # Trigger repository dispatch to let GitHub Actions handle license delivery
        repo_dispatch_url = f"https://api.github.com/repos/{GITHUB_OWNER}/{GITHUB_REPO}/dispatches"
        headers = {
            'Accept': 'application/vnd.github.v3+json',
            'Authorization': f'Bearer {GITHUB_PAT}'
        }
        payload = {
            'event_type': 'stripe_payment',
            'client_payload': {
                'customer_email': customer_email,
                'product_name': 'Professional',
                'amount': event.get('data', {}).get('object', {}).get('amount_total', 2500),
                'payment_id': event.get('id')
            }
        }
        r = requests.post(repo_dispatch_url, json=payload, headers=headers)
        if r.status_code in (200, 204):
            return jsonify({'status': 'dispatched'}), 200
        else:
            return jsonify({'status': 'failed', 'detail': r.text}), 500

    return jsonify({'status': 'ignored'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.getenv('PORT', 5000)))
