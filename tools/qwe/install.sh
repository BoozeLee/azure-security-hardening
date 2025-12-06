#!/usr/bin/env bash
# Install script for qwe: create virtual environment and install dependencies
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
if [ ! -d .venv ]; then
  python3 -m venv .venv
fi
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
if [ "${1:-}" = "--dev" ]; then
  pip install -r requirements-dev.txt
fi
echo "qwe environment installed in ${SCRIPT_DIR}/.venv"
