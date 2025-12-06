#!/bin/bash
# Emergency Local Security Hardening for Kali Linux
# High-threat environment protection

set -e

echo "🚨 URGENT: Implementing Local Security Hardening"
echo "📧 Security Contact: kiliaan@bakerstreetproject221b.store"
echo "🔒 Threat Level: HIGH"
echo ""

# Update system packages
echo "🔄 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install UFW firewall if not present
echo "📦 Installing UFW firewall..."
sudo apt install ufw -y

# Configure firewall - BLOCK ALL REMOTE ACCESS
echo "🔥 Configuring UFW firewall - BLOCKING ALL REMOTE ACCESS..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
# NO SSH ALLOWED - Complete remote access lockdown
sudo ufw --force enable

# Disable unnecessary services and remote access
echo "🛑 Disabling unnecessary services and blocking remote access..."
sudo systemctl disable bluetooth.service || true
sudo systemctl stop bluetooth.service || true
sudo systemctl disable cups.service || true
sudo systemctl stop cups.service || true
sudo systemctl disable ssh.service || true
sudo systemctl stop ssh.service || true
sudo systemctl disable sshd.service || true
sudo systemctl stop sshd.service || true

# Remove SSH if installed (complete remote access lockdown)
echo "🚫 Removing SSH for complete remote access lockdown..."
sudo apt remove openssh-server -y || true

# Install fail2ban
echo "🛡️ Installing and configuring Fail2Ban..."
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Configure automatic security updates
echo "🔄 Configuring automatic security updates..."
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure -plow unattended-upgrades

# Install ClamAV antivirus
echo "🦠 Installing ClamAV antivirus..."
sudo apt install clamav clamav-daemon -y
sudo systemctl enable clamav-daemon
sudo freshclam || true
sudo systemctl start clamav-daemon

# Configure log monitoring
echo "📊 Setting up log monitoring..."
sudo apt install logwatch -y

# Create security monitoring script
cat > /tmp/security_monitor.sh << 'EOF'
#!/bin/bash
# Security monitoring for high-threat environment

LOG_FILE="/var/log/security-monitor.log"
EMAIL="kiliaan@bakerstreetproject221b.store"

# Monitor failed login attempts
FAILED_LOGINS=$(journalctl --since "1 hour ago" | grep -i "failed\|invalid" | wc -l)
if [ $FAILED_LOGINS -gt 10 ]; then
    echo "$(date): HIGH ALERT - $FAILED_LOGINS failed login attempts in last hour" >> $LOG_FILE
fi

# Check for suspicious network connections
CONNECTIONS=$(netstat -tuln | grep LISTEN | wc -l)
echo "$(date): Active listening ports: $CONNECTIONS" >> $LOG_FILE

# Monitor system resources
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
MEMORY_USAGE=$(free | grep Mem | awk '{printf("%.2f", $3/$2 * 100.0)}')
echo "$(date): CPU: ${CPU_USAGE}%, Memory: ${MEMORY_USAGE}%" >> $LOG_FILE
EOF

sudo mv /tmp/security_monitor.sh /usr/local/bin/security_monitor.sh
sudo chmod +x /usr/local/bin/security_monitor.sh

# Add to crontab for monitoring every 15 minutes
(crontab -l 2>/dev/null; echo "*/15 * * * * /usr/local/bin/security_monitor.sh") | crontab -

# Configure password policy
echo "🔑 Configuring password policy..."
sudo apt install libpam-pwquality -y

# Create security report
echo ""
echo "🎉 LOCAL SECURITY HARDENING COMPLETED!"
echo ""
echo "✅ Security Measures Implemented:"
echo "   🔥 UFW Firewall: ENABLED (BLOCKS ALL REMOTE ACCESS)"
echo "   🛡️ Fail2Ban: ENABLED (brute force protection)"
echo "   🚫 SSH: DISABLED/REMOVED (no remote access)"
echo "   🦠 ClamAV: INSTALLED (antivirus protection)"
echo "   🔄 Auto Updates: ENABLED"
echo "   📊 Log Monitoring: ACTIVE"
echo "   🚫 Unnecessary Services: DISABLED"
echo ""
echo "📋 Security Status: MAXIMUM LOCAL PROTECTION - NO REMOTE ACCESS"
echo "📧 Monitoring: /var/log/security-monitor.log"
echo ""
echo "⚠️ NOTE: This provides basic local protection."
echo "   For complete security, still set up Azure infrastructure!"
echo ""
echo "🔍 Check security status: sudo systemctl status ufw fail2ban clamav-daemon"