#!/usr/bin/env python3
"""
Lightweight CLI client for the agent communicator server (qwe).
Usage:
  python qwe.py send --channel agents --message "Hello" --server http://localhost:9001
  python qwe.py list --server http://localhost:9001

The CLI uses HTTP to POST to the server's `/api/v1/agents/message` endpoint.
"""
import argparse
import requests
import sys

def send_message(server, channel, message, agent='unknown', token=''):
    url = server.rstrip('/') + '/api/v1/agents/message'
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = f'Bearer {token}'
    payload = {'channel': channel, 'message': message, 'agent': agent}
    resp = requests.post(url, json=payload, headers=headers)
    if resp.status_code in (200, 201):
        try:
            j = resp.json()
            print('Message sent:', j)
        except Exception:
            print('Message sent')
        return 0
    else:
        print('Failed to send message:', resp.status_code, resp.text)
        return 1


def list_messages(server):
    url = server.rstrip('/') + '/api/v1/agents/messages'
    resp = requests.get(url)
    if resp.status_code == 200:
        j = resp.json()
        print('Messages:')
        for m in j.get('messages', []):
            print(m['timestamp'], m['channel'], m['message'])
        return 0
    else:
        print('Failed to list messages:', resp.status_code, resp.text)
        return 1


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest='cmd')

    sp_send = subparsers.add_parser('send')
    sp_send.add_argument('--channel', default='agents')
    sp_send.add_argument('--message', required=True)
        sp_send.add_argument('--agent', default='unknown')
        sp_send.add_argument('--token', default='')
    sp_send.add_argument('--server', default='http://localhost:9001')

    sp_list = subparsers.add_parser('list')
    sp_list.add_argument('--server', default='http://localhost:9001')

    args = parser.parse_args()
    if args.cmd == 'send':
            sys.exit(send_message(args.server, args.channel, args.message, agent=args.agent, token=args.token))
    elif args.cmd == 'list':
        sys.exit(list_messages(args.server))
    else:
        parser.print_help()
        sys.exit(1)
