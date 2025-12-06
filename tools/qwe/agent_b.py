#!/usr/bin/env python3
"""
Simple agent-b simulator that polls the qwe server for messages and replies with an acknowledgement.

Usage:
  python agent_b.py --server http://localhost:9001 --channel agents

The agent will poll `/api/v1/agents/messages` every `--interval` seconds, and send an
acknowledgement message for any new message not originating from itself.
"""
import argparse
import requests
import time
import sys


def fetch_messages(server):
    url = server.rstrip('/') + '/api/v1/agents/messages'
    resp = requests.get(url)
    resp.raise_for_status()
    return resp.json().get('messages', [])


def send_message(server, channel, message):
    url = server.rstrip('/') + '/api/v1/agents/message'
    resp = requests.post(url, json={'channel': channel, 'message': message})
    resp.raise_for_status()
    return resp


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--server', default='http://localhost:9001')
    parser.add_argument('--channel', default='agents')
    parser.add_argument('--interval', type=float, default=1.0, help='Polling interval in seconds')
    parser.add_argument('--agent-name', default='agent-b')
    args = parser.parse_args()

    server = args.server
    channel = args.channel
    interval = args.interval
    name = args.agent_name
    ack_prefix = f"ACK from {name}:"

    seen = set()
    print(f"[{name}] Starting agent. Server={server} channel={channel} interval={interval}s")
    try:
        while True:
            try:
                messages = fetch_messages(server)
            except Exception as ex:
                print(f"[{name}] Error fetching messages: {ex}")
                time.sleep(interval)
                continue

            for m in messages:
                # Use the tuple (timestamp, channel, message) as an identifier
                identifier = (m.get('timestamp'), m.get('channel'), m.get('message'))
                if identifier in seen:
                    continue
                seen.add(identifier)

                # Avoid acknowledging our own acks to prevent loops
                msg_text = m.get('message', '') or ''
                if msg_text.startswith(ack_prefix) or name in msg_text:
                    # Skip messages that are ack from this agent or include its name
                    continue

                # Build and send acknowledgement
                ack_msg = f"{ack_prefix} received: '{msg_text}'"
                try:
                    send_message(server, channel, ack_msg)
                    print(f"[{name}] Sent ack for message: {msg_text}")
                except Exception as ex:
                    print(f"[{name}] Failed to send ack: {ex}")

            time.sleep(interval)
    except KeyboardInterrupt:
        print(f"[{name}] Shutting down")
        sys.exit(0)


if __name__ == '__main__':
    main()
