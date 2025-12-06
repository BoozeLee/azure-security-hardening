import os
import json
import sys
import pytest

# Make tools/qwe importable for tests
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
import server as qserver


@pytest.fixture
def client():
    import importlib.metadata
    import werkzeug as _werkzeug
    # Some Werkzeug installs don't expose __version__ on the module; ensure it's present for Flask test client
    if not hasattr(_werkzeug, '__version__'):
        try:
            _werkzeug.__version__ = importlib.metadata.version('Werkzeug')
        except Exception:
            _werkzeug.__version__ = 'unknown'

    app = qserver.app
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


def test_receive_message_success(client, tmp_path, monkeypatch):
    # Ensure messages.log is in tmp_path
    msgfile = tmp_path / 'messages.log'
    # Ensure messages log exists before server tries to write to it
    msgfile.write_text('[]')
    monkeypatch.setattr(qserver, 'LOG_FILE', str(msgfile))
    resp = client.post('/api/v1/agents/message', json={'channel': 'agents', 'message': 'hello', 'agent': 'pytest'})
    assert resp.status_code == 201
    j = resp.get_json()
    assert j['status'] == 'ok'
    assert j['agent'] == 'pytest'


def test_receive_message_missing_message(client):
    resp = client.post('/api/v1/agents/message', json={'channel': 'agents'})
    assert resp.status_code == 400


def test_receive_message_with_token_auth(client, monkeypatch, tmp_path):
    monkeypatch.setenv('QWE_SERVER_TOKEN', 's3cr3t')
    # ensure log file exists
    msgfile = tmp_path / 'messages.log'
    msgfile.write_text('[]')
    # Valid token
    msgfile = tmp_path / 'messages.log'
    msgfile.write_text('[]')
    # Valid token
    headers = {'Authorization': 'Bearer s3cr3t'}
    resp = client.post('/api/v1/agents/message', json={'channel': 'agents', 'message': 'hello', 'agent': 'pytest'}, headers=headers)
    assert resp.status_code == 201
    # Invalid token
    headers = {'Authorization': 'Bearer wrong'}
    resp2 = client.post('/api/v1/agents/message', json={'channel': 'agents', 'message': 'hello2', 'agent': 'pytest'}, headers=headers)
    assert resp2.status_code == 401
