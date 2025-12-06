#!/usr/bin/env python3
"""
AI Validator Agent for workflow orchestrator.

Handles testing stage requests by performing security validation and code analysis.
Uses placeholder AI logic that can be replaced with actual AI services.

Communicates via qwe messaging system.
"""
import argparse
import requests
import time
import sys
import logging
import json
import re

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def fetch_messages(server):
    """Fetch messages from qwe server."""
    url = server.rstrip('/') + '/api/v1/agents/messages'
    try:
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        return resp.json().get('messages', [])
    except requests.RequestException as e:
        logger.error(f"Error fetching messages: {e}")
        return []

def send_message(server, channel, message, agent_name):
    """Send message to qwe server."""
    url = server.rstrip('/') + '/api/v1/agents/message'
    payload = {
        'channel': channel,
        'message': message,
        'agent': agent_name
    }
    try:
        resp = requests.post(url, json=payload, timeout=10)
        resp.raise_for_status()
        logger.info(f"Sent validation report")
        return resp
    except requests.RequestException as e:
        logger.error(f"Failed to send message: {e}")
        return None

def validate_code(code):
    """
    Placeholder AI function to perform security validation and code analysis.
    Replace with actual AI service call (e.g., security scanning tools).
    """
    try:
        # Simulate AI processing
        logger.info("Analyzing code for security and quality...")
        time.sleep(2)  # Simulate processing time

        issues = []
        score = 100  # Start with perfect score

        # Basic security checks (placeholder logic)
        if "eval(" in code:
            issues.append("SECURITY: Use of eval() detected - high risk")
            score -= 30

        if "exec(" in code:
            issues.append("SECURITY: Use of exec() detected - high risk")
            score -= 30

        if "input(" in code:
            issues.append("SECURITY: Raw input() usage - potential injection risk")
            score -= 15

        if "import os" in code and "os.system" in code:
            issues.append("SECURITY: Direct OS system calls - command injection risk")
            score -= 25

        # Code quality checks
        if not re.search(r'def \w+\(', code):
            issues.append("QUALITY: No functions defined")
            score -= 10

        if not re.search(r'"""', code):
            issues.append("QUALITY: Missing docstrings")
            score -= 5

        if len(code.split('\n')) < 5:
            issues.append("QUALITY: Code seems too minimal")
            score -= 5

        # Check for error handling
        if "try:" not in code:
            issues.append("QUALITY: No exception handling detected")
            score -= 10

        # Performance checks
        if "for " in code and " in range(" in code and "1000000" in code:
            issues.append("PERFORMANCE: Potential large loop - consider optimization")
            score -= 10

        # Ensure score doesn't go below 0
        score = max(0, score)

        # Generate report
        report = f"""
Code Validation Report
======================

Overall Security Score: {score}/100

Issues Found:
{chr(10).join(f"- {issue}" for issue in issues) if issues else "- No major issues detected"}

Recommendations:
"""

        if score >= 80:
            report += "- Code appears secure and well-structured\n"
        elif score >= 60:
            report += "- Address security issues before deployment\n- Consider code review\n"
        else:
            report += "- Critical security issues found - do not deploy\n- Comprehensive security audit required\n"

        if not issues:
            report += "- Code passed basic validation checks\n"

        report += "\nAnalysis completed by AI Validator Agent"

        return report.strip()
    except Exception as e:
        logger.error(f"Error in AI validation: {e}")
        return f"Error during validation: {str(e)}"

def perform_security_analysis(code):
    """
    Additional security-focused analysis.
    """
    try:
        vulnerabilities = []

        # Check for common vulnerabilities
        patterns = {
            "SQL Injection": r"(SELECT|INSERT|UPDATE|DELETE).*(\+|\%s|format)",
            "XSS": r"innerHTML\s*=|document\.write",
            "Path Traversal": r"\.\./|\.\.\\",
            "Hardcoded Secrets": r"(password|secret|key)\s*=\s*['\"][^'\"]*['\"]",
            "Weak Crypto": r"md5\(|sha1\(",
        }

        for vuln_type, pattern in patterns.items():
            if re.search(pattern, code, re.IGNORECASE):
                vulnerabilities.append(f"{vuln_type}: Potential vulnerability detected")

        if not vulnerabilities:
            return "No common security vulnerabilities detected in basic scan."
        else:
            return "Security Analysis:\n" + "\n".join(f"- {v}" for v in vulnerabilities)

    except Exception as e:
        return f"Security analysis error: {str(e)}"

def process_validation_request(message_text, agent_name):
    """Process a validation request message."""
    try:
        # Extract code from message (simple parsing)
        if "validate:" in message_text.lower():
            code = message_text.split("validate:", 1)[1].strip()
        elif "analyze:" in message_text.lower():
            code = message_text.split("analyze:", 1)[1].strip()
        else:
            # Assume the message contains code
            code = message_text.strip()

        logger.info("Processing validation request")

        # Perform validation
        validation_report = validate_code(code)
        security_analysis = perform_security_analysis(code)

        # Combine reports
        full_report = f"{validation_report}\n\n{security_analysis}"

        # Format response
        response = f"Validation complete:\n{full_report}"

        return response
    except Exception as e:
        logger.error(f"Error processing validation request: {e}")
        return f"Error during validation: {str(e)}"

def main():
    parser = argparse.ArgumentParser(description='AI Validator Agent')
    parser.add_argument('--server', default='http://localhost:9001', help='QWE server URL')
    parser.add_argument('--channel', default='testing', help='Channel to listen on')
    parser.add_argument('--interval', type=float, default=2.0, help='Polling interval in seconds')
    parser.add_argument('--agent-name', default='ai-validator', help='Agent name')
    args = parser.parse_args()

    server = args.server
    channel = args.channel
    interval = args.interval
    agent_name = args.agent_name

    seen = set()
    logger.info(f"Starting {agent_name}. Server={server} channel={channel} interval={interval}s")

    try:
        while True:
            try:
                messages = fetch_messages(server)
            except Exception as ex:
                logger.error(f"Error in main loop: {ex}")
                time.sleep(interval)
                continue

            for m in messages:
                # Use message ID as identifier to avoid duplicates
                msg_id = m.get('id')
                if msg_id in seen:
                    continue
                seen.add(msg_id)

                msg_channel = m.get('channel', '')
                msg_text = m.get('message', '')
                msg_agent = m.get('agent', '')

                # Only process messages on our channel and not from ourselves
                if msg_channel == channel and msg_agent != agent_name:
                    logger.info(f"Received validation request")

                    # Check if it's a validation request
                    if any(keyword in msg_text.lower() for keyword in ['validate', 'analyze', 'check', 'test']):
                        response = process_validation_request(msg_text, agent_name)

                        # Send response back
                        send_message(server, channel, response, agent_name)

            time.sleep(interval)
    except KeyboardInterrupt:
        logger.info(f"Shutting down {agent_name}")
        sys.exit(0)
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()