#!/usr/bin/env bash
# Create and activate a Python virtual environment and install dependencies
set -e

python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
if [ -f requirements.txt ]; then
  pip install -r requirements.txt
fi
echo "Virtual environment ready. Activate with: source .venv/bin/activate"
