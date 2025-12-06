# 🤖 API Automation Setup Guide

## Required API Keys for Full Automation

### 1. Email Automation (SendGrid)
```bash
# Sign up at sendgrid.com
# Get API key from Dashboard > Settings > API Keys
export SENDGRID_API_KEY="SG.your-key-here"
```

### 2. Lead Generation (Apollo.io)
```bash
# Sign up at apollo.io  
# Get API key from Settings > Integrations
export APOLLO_API_KEY="your-apollo-key"
```

### 3. Social Media (LinkedIn Sales Navigator)
```bash
# Apply for LinkedIn Marketing Developer Platform
# Get access token for Sales Navigator API
export LINKEDIN_ACCESS_TOKEN="your-linkedin-token"
```

### 4. Payment Processing (Stripe)
```bash
# Get from Stripe Dashboard > Developers > API Keys
export STRIPE_SECRET_KEY="sk_live_your-stripe-key"
export STRIPE_PUBLISHABLE_KEY="pk_live_your-stripe-key"
```

### 5. Company Data (Clearbit/ZoomInfo)
```bash
# Sign up for Clearbit API or ZoomInfo
export CLEARBIT_API_KEY="your-clearbit-key"
export ZOOMINFO_API_KEY="your-zoominfo-key"
```

## Quick Setup Commands

### Install Dependencies
```bash
pip install requests sendgrid stripe clearbit python-linkedin
```

### Set Environment Variables
```bash
# Create .env file
cat > .env << 'EOF'
SENDGRID_API_KEY=SG.your-sendgrid-key
APOLLO_API_KEY=your-apollo-key
STRIPE_SECRET_KEY=sk_live_your-stripe-key
LINKEDIN_ACCESS_TOKEN=your-linkedin-token
EOF
```

### Test the Sales Bot
```bash
# Run lead generation test
python3 sales_bot.py

# Run email campaign
gh workflow run sales-bot.yml -f campaign_type=cold_outreach -f target_count=10
```

## Automation Schedule

### Daily (Monday-Friday 9 AM)
- Generate 20 new leads
- Send 10 cold outreach emails  
- Follow up on previous emails
- Track revenue and performance

### Weekly (Monday 9 AM)
- Comprehensive lead scoring
- Competitor analysis update
- Social media monitoring
- Revenue optimization

### Monthly
- Campaign performance review
- Pricing strategy adjustment  
- API integration updates
- Scale automation rules

## API Integration Costs

| Service | Cost | Value |
|---------|------|-------|
| SendGrid | $19.95/month (40K emails) | Essential |
| Apollo.io | $49/month (1K leads) | High ROI |
| LinkedIn Sales Navigator | $79.99/month | Premium |
| Stripe | 2.9% + 30¢ per transaction | Required |
| **Total** | **~$150/month** | **$10K+ revenue/month** |

**ROI: 6,500%+ return on API costs**

## Compliance & Ethics

### CAN-SPAM Compliance
- ✅ Include unsubscribe link
- ✅ Use real from address  
- ✅ Don't use misleading subjects
- ✅ Include physical address

### GDPR Compliance  
- ✅ Legitimate business interest
- ✅ Provide opt-out mechanism
- ✅ Store minimal personal data
- ✅ Honor deletion requests

### Best Practices
- ✅ Personalize all emails
- ✅ Provide genuine value
- ✅ Respect response requests
- ✅ Monitor reputation metrics

## Scaling Strategy

### Phase 1: Manual + Bot (Month 1-2)
- 50 leads/week generated
- 20 emails/week sent  
- 1-2 sales/week target
- Revenue: $5K-10K/month

### Phase 2: Full Automation (Month 3-6)
- 200 leads/week generated
- 100 emails/week sent
- 5-10 sales/week target  
- Revenue: $25K-50K/month

### Phase 3: Scale + Optimize (Month 6+)
- 500 leads/week generated
- 250 emails/week sent
- 20+ sales/week target
- Revenue: $100K+/month

## Success Metrics

### Email Performance
- Open rate: >25% (industry avg: 21%)
- Click rate: >3% (industry avg: 2.3%)  
- Response rate: >2% (industry avg: 1%)
- Conversion rate: >0.5% (our target: 1%+)

### Revenue Tracking
- Cost per lead: <$5
- Cost per customer: <$250
- Customer lifetime value: $2,500+
- Return on ad spend: 10:1+

## Troubleshooting

### Common Issues
1. **Emails going to spam** → Warm up domain, improve content
2. **Low response rates** → Better personalization, value prop
3. **API rate limits** → Implement delays, upgrade plans
4. **Compliance violations** → Review CAN-SPAM, add opt-outs

### Monitoring Dashboard
```bash
# Check campaign performance
python3 sales_bot.py --report

# Monitor API health  
curl -X GET "https://api.sendgrid.com/v3/stats" \
  -H "Authorization: Bearer $SENDGRID_API_KEY"
```

**Bottom line: $150/month in API costs → $25K+/month in revenue = 16,500% ROI! 🚀💰**

## Stripe Webhook Setup (Test + Production)

1. Create a small webhook receiver in the repo (`stripe_webhook_server.py`) to validate Stripe event signatures and then call GitHub's repository dispatch API.
2. Install dependencies locally:
```bash
pip install -r requirements.txt
```
3. Run locally with environment variables (test mode):
```bash
export STRIPE_SECRET_KEY='sk_test_your_key'
export STRIPE_WEBHOOK_SECRET='whsec_your_webhook_secret'
export GH_PAT='ghp_personal_access_token'
export GITHUB_OWNER='BoozeLee'
export GITHUB_REPO='azure-security-hardening'
python3 stripe_webhook_server.py
```
4. Use Stripe CLI to forward events while testing:
```bash
stripe listen --forward-to http://localhost:5000/webhook
stripe trigger checkout.session.completed
```
5. For production, host the webhook server (Azure Functions or a small container) and configure a Stripe webhook endpoint to call your public URL; store your `GH_PAT` in GitHub Secrets and `STRIPE_WEBHOOK_SECRET` as an environment variable in the host or in Key Vault.

Note: Stripe webhooks must be verified on receipt; do NOT trust raw requests in production.
