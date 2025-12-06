#!/usr/bin/env python3
"""
Simple local HTTP server to receive messages from agents.
Usage:
  python server.py

Endpoints:
  POST /api/v1/agents/message  - accepts {"channel": "agents", "message": "..."}
  GET  /api/v1/agents/messages - returns a list of recent messages

The server writes messages to tools/qwe/messages.log for persistence.
"""
from flask import Flask, request, jsonify
import os
import json
from datetime import datetime
import uuid
import os

APP_DIR = os.path.dirname(os.path.abspath(__file__))
LOG_FILE = os.path.join(APP_DIR, "messages.log")

app = Flask(__name__)

# Ensure messages file exists
if not os.path.exists(LOG_FILE):
    with open(LOG_FILE, 'w', encoding='utf-8') as f:
        f.write('[]')


def append_message(channel, message):
    with open(LOG_FILE, 'r+', encoding='utf-8') as f:
        try:
            messages = json.load(f)
        except json.JSONDecodeError:
            messages = []
        messages.append({
            'id': uuid.uuid4().hex,
            'timestamp': datetime.utcnow().isoformat() + 'Z',
            'channel': channel,
            'agent': message.get('agent') if isinstance(message, dict) and message.get('agent') else 'unknown',
            'message': message.get('message') if isinstance(message, dict) else message,
            'meta': message.get('meta') if isinstance(message, dict) and message.get('meta') else None,
        })
        f.seek(0)
        f.truncate(0)
        json.dump(messages, f, indent=2)


@app.route('/api/v1/agents/message', methods=['POST'])
def receive_message():
    try:
        # Token auth: if server token is set, require Authorization header Bearer <token>
        server_token = os.getenv('QWE_SERVER_TOKEN', '')
        if server_token:
            auth = request.headers.get('Authorization', '')
            if not auth.startswith('Bearer ') or auth.split(' ', 1)[1] != server_token:
                return jsonify({'error': 'unauthorized'}), 401

        payload = request.json
        if not payload or 'message' not in payload:
            return jsonify({'error': 'invalid payload'}), 400
        channel = payload.get('channel', 'agents')
        # Accept agent and optional meta fields
        message = {
            'message': payload.get('message'),
            'agent': payload.get('agent', 'unknown'),
            'meta': payload.get('meta'),
        }
        append_message(channel, message)
        print(f"[qwe] Received message on channel={channel} message={message}")
        # Return a status JSON including a generated message id and the agent
        return jsonify({'status': 'ok', 'message': 'received', 'agent': message.get('agent'), 'channel': channel, 'message_id': messages[-1].get('id')}), 201
    except Exception as ex:
        print('Error receiving message:', ex)
        return jsonify({'error': str(ex)}), 500


@app.route('/api/v1/agents/messages', methods=['GET'])
def list_messages():
    try:
        with open(LOG_FILE, 'r', encoding='utf-8') as f:
            messages = json.load(f)
        return jsonify({'messages': messages}), 200
    except Exception as ex:
        return jsonify({'error': str(ex)}), 500


if __name__ == '__main__':
    # Run the app
    app.run(host='127.0.0.1', port=9001)
