import os
import subprocess
import tempfile
import sys
import pytest


def _make_fakebin(tmpdir):
    bin_dir = tmpdir / 'fakebin'
    bin_dir.mkdir()
    az = bin_dir / 'az'
    gh = bin_dir / 'gh'
    az.write_text('#!/bin/bash\necho "Mock az: $*"\nexit 0\n')
    gh.write_text('#!/bin/bash\necho "Mock gh: $*"\nexit 0\n')
    os.chmod(str(az), 0o755)
    os.chmod(str(gh), 0o755)
    return str(bin_dir)


def test_automate_raptor_cli_dry_run(tmp_path, monkeypatch):
    # Create a fakebin with az/gh to prevent real calls
    fakebin = _make_fakebin(tmp_path)
    env = os.environ.copy()
    env['PATH'] = f"{fakebin}:{env.get('PATH','')}"
    env['QWE_DRY_RUN'] = 'true'
    env['QWE_DEBUG'] = '1'
    env['AZURE_OPENAI_KEY'] = 'mock-key'
    env['AZURE_OPENAI_ENDPOINT'] = 'https://mock.azure.ai'
    env['ORG'] = 'mock-org'
    # Set secret name to avoid interactive or org restrictions
    env['SECRET_NAME'] = 'COPILOT_PROVIDER_AZURE_OPENAI_JSON'
    script = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..', 'automate-raptor-cli.sh'))
    proc = subprocess.run([script], env=env, capture_output=True, text=True)
    # Should exit 0 in dry-run scenario
    assert proc.returncode == 0, f"automate-raptor-cli.sh failed: {proc.stdout}\n{proc.stderr}"


def test_deploy_security_dry_run(tmp_path, monkeypatch):
    # Create fakebin and run deploy-security in dry-run with 'N' confirmation
    fakebin = _make_fakebin(tmp_path)
    env = os.environ.copy()
    env['PATH'] = f"{fakebin}:{env.get('PATH','')}"
    env['QWE_DRY_RUN'] = 'true'
    env['QWE_DEBUG'] = '1'
    env['AZURE_SUBSCRIPTION_ID'] = '00000000-0000-0000-0000-000000000000'
    script = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..', 'deploy-security.sh'))
    # answer the confirmation prompt with 'n' so the deployment is skipped
    proc = subprocess.run(['bash', script], input='n\n', env=env, capture_output=True, text=True)
    assert proc.returncode == 0, f"deploy-security.sh failed: {proc.stdout}\n{proc.stderr}"
    # confirm the dry-run mechanism was used by checking stdout for the DRY_RUN log
    assert 'DRY_RUN' in proc.stdout or 'Mock az' in proc.stdout
