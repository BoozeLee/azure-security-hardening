#!/usr/bin/env bash
# Start agent_b simulator in background
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
if [ ! -d .venv ]; then
  ./install.sh
fi
source .venv/bin/activate
LOG_FILE="agent-b.log"
PID_FILE="agent-b.pid"
nohup python agent_b.py --server http://localhost:9001 --channel agents >> "$LOG_FILE" 2>&1 &
echo $! > "$PID_FILE"
echo "agent-b started in background. PID=$(cat $PID_FILE). Logs: ${SCRIPT_DIR}/$LOG_FILE"
