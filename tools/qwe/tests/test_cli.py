import sys
import os
import json
import types
import pytest

# Make tools/qwe importable
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
import qwe as qwe


class DummyResp:
    def __init__(self, status=201, json_data=None):
        self.status_code = status
        self._json = json_data or {'status': 'ok'}

    def json(self):
        return self._json


def test_send_message_headers_and_payload(monkeypatch):
    called = {}

    def fake_post(url, json=None, headers=None):
        called['url'] = url
        called['json'] = json
        called['headers'] = headers
        return DummyResp()

    monkeypatch.setattr(qwe.requests, 'post', fake_post)
    ret = qwe.send_message('http://127.0.0.1:9001', 'agents', 'hello-from-test', agent='test-agent', token='my-token')
    assert ret == 0
    assert called['url'].endswith('/api/v1/agents/message')
    assert called['json']['agent'] == 'test-agent'
    assert called['json']['message'] == 'hello-from-test'
    assert called['headers']['Authorization'] == 'Bearer my-token'
