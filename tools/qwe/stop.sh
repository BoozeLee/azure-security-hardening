#!/usr/bin/env bash
# Gracefully stop the qwe server and agent-b
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

kill_pid_file() {
  PID_FILE="$1"
  NAME="$2"
  if [ -f "$PID_FILE" ]; then
    PID="$(cat "$PID_FILE")"
    if [ -z "$PID" ]; then
      echo "No PID in $PID_FILE, skipping $NAME"
      rm -f "$PID_FILE"
      return 0
    fi
    if kill -0 "$PID" 2>/dev/null; then
      echo "Stopping $NAME (PID=$PID)..."
      kill "$PID" || true
      # Wait up to 10s for graceful shutdown
      for i in $(seq 1 10); do
        if ! kill -0 "$PID" 2>/dev/null; then
          break
        fi
        sleep 1
      done
      if kill -0 "$PID" 2>/dev/null; then
        echo "$NAME did not exit; sending SIGKILL"
        kill -9 "$PID" || true
      fi
    else
      echo "$NAME pid $PID not running"
    fi
    rm -f "$PID_FILE"
  else
    echo "No PID file $PID_FILE for $NAME"
  fi
}

kill_pid_file "server.pid" "qwe server"
kill_pid_file "agent-b.pid" "agent-b"

echo "--- Last lines of server log (qwe-server.log) ---"
if [ -f "qwe-server.log" ]; then
  tail -n 50 qwe-server.log || true
else
  echo "No qwe-server.log found"
fi
echo "--- Last lines of agent log (agent-b.log) ---"
if [ -f "agent-b.log" ]; then
  tail -n 50 agent-b.log || true
else
  echo "No agent-b.log found"
fi

echo "Stop complete"
