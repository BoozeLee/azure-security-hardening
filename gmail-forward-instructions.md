# Gmail Forwarding - Manual Steps and Script

If you want all emails from `kiliaanv2@gmail.com` and `iamthatiamresearch@gmail.com` to auto-forward to your new `kiliaan@bakerstreetproject.com` mailbox, follow the steps below.

## Option A: Manual Gmail Settings
1. Sign in to `kiliaanv2@gmail.com` and `iamthatiamresearch@gmail.com`.
2. Settings (gear) -> See all settings -> Forwarding and POP/IMAP -> Add a forwarding address -> Enter `kiliaan@bakerstreetproject.com`.
3. Verify the forwarding via the verification email sent to `kiliaan@bakerstreetproject.com`.
4. Create a filter: Search `from:kiliaan@bakerstreetproject221b.store OR from:other-address` and Create filter -> Forward to `kiliaan@bakerstreetproject.com`.

## Option B: Programmatic (Gmail API or GAM)
1. Use GAM (https://github.com/jay0lee/GAM) for admins to add forwarding and filters at scale.
2. Example GAM command to add a forwarding address and filter (admin privileges required):
```bash
# Create forwarding address
gam user kiliaanv2@gmail.com forward to kiliaan@bakerstreetproject.com

# Create filter to forward only senders
gam user kiliaanv2@gmail.com filter create label 'Forwarded' criteria 'from:(example@example.com)' action 'forward:kiliaan@bakerstreetproject.com'
```

**Note**: Gmail will require verification for the forwarding address; you must access `kiliaan@bakerstreetproject.com` to confirm.
