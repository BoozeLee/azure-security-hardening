#!/usr/bin/env bash
# Test script that starts the qwe server and agent-b, sends a message, and checks that agent-b replies with an acknowledgement.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
SERVER="http://localhost:9001"

echo "Installing venv and dependencies if missing..."
./install.sh

echo "Starting qwe server in background..."
./start_bg.sh
sleep 1

echo "Starting agent-b simulator in background..."
./start-agent-b.sh
sleep 1

TEST_MSG="Hello from test-agent-b"
echo "Sending test message: $TEST_MSG"
./send.sh "$TEST_MSG" "$SERVER"

echo "Waiting for agent-b to acknowledge..."
TRIES=15
SLEEP=1
FOUND=0
for i in $(seq 1 $TRIES); do
  echo -n "."
  MESSAGES=$(python qwe.py list --server "$SERVER" | sed -n '2,200p') || true
  if echo "$MESSAGES" | grep -qi "ACK from agent-b"; then
    FOUND=1
    break
  fi
  sleep $SLEEP
done
echo
if [ "$FOUND" -eq 1 ]; then
  echo "✅ agent-b replied with acknowledgement"
  echo "Messages:"
  python qwe.py list --server "$SERVER"
  exit 0
else
  echo "⚠️ agent-b did not reply within timeout"
  echo "Messages:"
  python qwe.py list --server "$SERVER"
  exit 2
fi
