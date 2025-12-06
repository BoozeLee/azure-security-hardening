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

Start the server:

```bash
cd tools/qwe
./start.sh
```

In another terminal, send a message from the CLI:

```bash
cd tools/qwe
./send.sh "Hello world from CLI"
# or use the CLI directly
python qwe.py send --message "Hello world" --channel agents --server http://localhost:9001
```

List messages:

```bash
python qwe.py list --server http://localhost:9001
```

## Notes

- The helper scripts use a `.venv` in `tools/qwe` to isolate dependencies.
- `messages.log` keeps an array of messages and will be created automatically when the server starts.
