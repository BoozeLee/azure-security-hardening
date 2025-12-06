#!/usr/bin/env bash
# Helper script to send a message with the qwe tool.
# Usage: ./send.sh "Hello world" [server]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
MESSAGE="${1:-Test message from send.sh}"
SERVER="${2:-http://localhost:9001}"
# Use the venv if present
if [ -f .venv/bin/activate ]; then
  source .venv/bin/activate
fi
python qwe.py send --message "$MESSAGE" --server "$SERVER"
