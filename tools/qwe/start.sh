#!/usr/bin/env bash
# Simple helper for starting the qwe server locally
# Usage: ./start.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
# Create a venv for the qwe tool if not present
if [ ! -d .venv ]; then
  python3 -m venv .venv
fi
# Activate
source .venv/bin/activate
# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt
# Start the server
python server.py
