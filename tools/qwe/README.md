# qwe — Agent Message Server and CLI

A tiny local HTTP server and CLI to simulate sending messages between local agent components.

## Files

- `server.py` — Flask server that receives and persists messages into `messages.log`.
- `qwe.py` — CLI client that sends messages to the `server.py` API and lists messages.
- `requirements.txt` — dependencies for the qwe tool (Flask + requests).
- `start.sh` — helper to create a virtual environment, install deps, and run the server.
- `send.sh` — helper script to send a message using the CLI.
- `messages.log` — created automatically by the server on first start.

## Quick start

 - `agent_b.py` — simple agent simulator which polls the server for messages and replies with acknowledgements.
 - `start-agent-b.sh` — helper script to start `agent_b.py` in the background and write logs and PID.
 - `test-agent-b.sh` — quick test to verify agent-b replies to messages.

Start server in background (logs written to `qwe-server.log` and PID saved to `server.pid`):

```bash
cd tools/qwe
./install.sh
./start_bg.sh
```

In another terminal, send a message from the CLI:

```bash
cd tools/qwe
./send.sh "Hello world from CLI"
# or use the CLI directly
python qwe.py send --message "Hello world" --channel agents --server http://localhost:9001
```


Start agent-b simulator in background:

```bash
./start-agent-b.sh
```

Run quick test to ensure agent-b replies to messages:

```bash
./test-agent-b.sh
```
List messages:

```bash
python qwe.py list --server http://localhost:9001
```

## Notes

- The helper scripts use a `.venv` in `tools/qwe` to isolate dependencies.
- `messages.log` keeps an array of messages and will be created automatically when the server starts.
- `server.pid` stores the PID when running `start_bg.sh` (use `kill $(cat server.pid)` to stop).
- If you edit `requirements.txt`, re-run `./install.sh` to update the `.venv`.
