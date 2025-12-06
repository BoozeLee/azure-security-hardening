#!/usr/bin/env python3
"""
AI Code Generator Agent for workflow orchestrator.

Handles development stage requests by generating code similar to GitHub Copilot.
Uses placeholder AI logic that can be replaced with actual AI services.

Communicates via qwe messaging system.
"""
import argparse
import requests
import time
import sys
import logging
import json

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
        logger.info(f"Sent message: {message[:50]}...")
        return resp
    except requests.RequestException as e:
        logger.error(f"Failed to send message: {e}")
        return None

def generate_code(prompt):
    """
    Placeholder AI function to generate code based on prompt.
    Replace with actual AI service call (e.g., GitHub Copilot API).
    """
    try:
        # Simulate AI processing
        logger.info("Generating code with AI...")
        time.sleep(1.5)  # Simulate processing time

        # Placeholder response - in real implementation, call AI API
        if "function" in prompt.lower():
            code = f"""
# Generated code for: {prompt}

def process_data(data):
    \"\"\"Process input data and return results.\"\"\"
    if not data:
        return None

    # Validate input
    if not isinstance(data, (list, dict)):
        raise ValueError("Invalid data type")

    # Process based on type
    if isinstance(data, list):
        return [item.upper() if isinstance(item, str) else item for item in data]
    elif isinstance(data, dict):
        return {{k: v.upper() if isinstance(v, str) else v for k, v in data.items()}}

    return data

# Example usage
if __name__ == "__main__":
    sample_data = ["hello", "world", {"key": "value"}]
    result = process_data(sample_data)
    print(result)
"""
        elif "class" in prompt.lower():
            code = f"""
# Generated code for: {prompt}

class DataProcessor:
    \"\"\"A class for processing various types of data.\"\"\"
    
    def __init__(self, config=None):
        self.config = config or {{}}
        self.processed_count = 0
    
    def process(self, data):
        \"\"\"Process input data.\"\"\"
        try:
            result = self._validate_and_transform(data)
            self.processed_count += 1
            return result
        except Exception as e:
            logger.error(f"Processing failed: {{e}}")
            return None
    
    def _validate_and_transform(self, data):
        \"\"\"Internal validation and transformation.\"\"\"
        if not data:
            return None
        
        # Apply transformations based on config
        if self.config.get('uppercase', False):
            return str(data).upper()
        
        return data
    
    def get_stats(self):
        \"\"\"Return processing statistics.\"\"\"
        return {{
            "processed_count": self.processed_count,
            "config": self.config
        }}

# Example usage
if __name__ == "__main__":
    processor = DataProcessor({{"uppercase": True}})
    result = processor.process("hello world")
    print(result)
    print(processor.get_stats())
"""
        else:
            code = f"""
# Generated code for: {prompt}

# This is a placeholder implementation
# Replace with actual AI-generated code

def generated_function():
    \"\"\"A function generated based on the prompt.\"\"\"
    # TODO: Implement based on specific requirements
    return "Generated result for: {prompt}"

# Example usage
if __name__ == "__main__":
    result = generated_function()
    print(result)
"""

        return code.strip()
    except Exception as e:
        logger.error(f"Error in AI code generation: {e}")
        return f"# Error generating code: {str(e)}"

def process_code_generation_request(message_text, agent_name):
    """Process a code generation request message."""
    try:
        # Extract prompt from message (simple parsing)
        if "generate code:" in message_text.lower():
            prompt = message_text.split("generate code:", 1)[1].strip()
        elif "code:" in message_text.lower():
            prompt = message_text.split("code:", 1)[1].strip()
        else:
            prompt = message_text.strip()

        logger.info(f"Processing code generation request: {prompt}")

        # Generate code
        code = generate_code(prompt)

        # Format response
        response = f"Code generated for '{prompt}':\n```python\n{code}\n```"

        return response
    except Exception as e:
        logger.error(f"Error processing code generation request: {e}")
        return f"Error generating code: {str(e)}"

def main():
    parser = argparse.ArgumentParser(description='AI Code Generator Agent')
    parser.add_argument('--server', default='http://localhost:9001', help='QWE server URL')
    parser.add_argument('--channel', default='development', help='Channel to listen on')
    parser.add_argument('--interval', type=float, default=2.0, help='Polling interval in seconds')
    parser.add_argument('--agent-name', default='ai-code-generator', help='Agent name')
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
                    logger.info(f"Received message: {msg_text[:50]}...")

                    # Check if it's a code generation request
                    if any(keyword in msg_text.lower() for keyword in ['generate code', 'code:', 'implement']):
                        response = process_code_generation_request(msg_text, agent_name)

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