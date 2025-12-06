import subprocess
import os
import sys
import pytest


def test_send_qwe_dry_run(tmp_path, monkeypatch):
    # Run a bash subprocess that sources the helper and uses DRY_RUN to avoid network
    script_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'scripts', 'qwe-sh'))
    cmd = f"bash -c 'source {script_path} && QWE_DRY_RUN=true QWE_DEBUG=1 send_qwe \"pytest dry run message\"'"
    proc = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    # dry-run should exit 0 and print debug (or not) — we check exit code
    assert proc.returncode == 0
