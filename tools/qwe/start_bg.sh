#!/usr/bin/env bash
# Start the qwe server in the background, write logs to qwe-server.log, save PID to server.pid
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
if [ -f .venv/bin/activate ]; then
  source .venv/bin/activate
else
  echo "Virtualenv not found, running install.sh..."
  ./install.sh
  source .venv/bin/activate
fi
LOG_FILE="qwe-server.log"
PID_FILE="server.pid"
nohup python server.py >> "$LOG_FILE" 2>&1 &
echo $! > "$PID_FILE"
echo "Server started in background. PID=$(cat $PID_FILE). Logs: ${SCRIPT_DIR}/$LOG_FILE"
