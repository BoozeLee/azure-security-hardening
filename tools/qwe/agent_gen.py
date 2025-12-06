#!/usr/bin/env python3
"""
Agent scaffolder for QWE - creates a minimal Python agent that talks to the QWE server.
Usage: python agent_gen.py create <agent-name> [--channel agents] [--path .]
"""
from pathlib import Path
import argparse
import textwrap
import os

AGENT_PY_TEMPLATE = textwrap.dedent('''
    #!/usr/bin/env python3
    import os
    import time
    import requests

    QWE_URL = os.environ.get('QWE_URL', 'http://127.0.0.1:9001/api/v1/agents/message')
    AGENT_NAME = "{agent_name}"
    CHANNEL = "{channel}"

    def send_qwe(message, channel=CHANNEL):
        payload = {{'agent': AGENT_NAME, 'channel': channel, 'message': message}}
        try:
            resp = requests.post(QWE_URL, json=payload, timeout=5)
            print('Send result', resp.status_code)
        except Exception as e:
            print('Send failed', e)

    def main():
        send_qwe('Agent started')
        try:
            while True:
                time.sleep(5)
        except KeyboardInterrupt:
            send_qwe('Agent shutting down')
            print('Exit')

    if __name__ == '__main__':
        main()
''')

RUN_SH_TEMPLATE = textwrap.dedent('''
    #!/usr/bin/env bash
    set -euo pipefail
    DIR="$(cd "$(dirname "$BASH_SOURCE")" && pwd)"
    PYTHON="${{PYTHON:-python3}}"
    export QWE_AGENT="{agent_name}"
    if [ -f "${{DIR}}/../../scripts/qwe-sh" ]; then
        # shellcheck source=/dev/null
        source "${{DIR}}/../../scripts/qwe-sh"
    fi
    $PYTHON -u "${{DIR}}/agent.py"
''')

README_TEMPLATE = textwrap.dedent('''
    # QWE Agent: {agent_name}

    Generated sample agent for qwe.

    To run (dry-run):
    ```bash
    QWE_URL=${{QWE_URL:-http://127.0.0.1:9001/api/v1/agents/message}} QWE_DRY_RUN=true bash ./start.sh
    ```
''')

PYTEST_TEMPLATE = textwrap.dedent('''
    import os
    import subprocess
    import time
    from pathlib import Path

    def test_agent_files_exist():
        agent_dir = Path('{rel_path}')
        assert (agent_dir / 'agent.py').exists()
        assert (agent_dir / 'start.sh').exists()
        assert (agent_dir / 'README.md').exists()

    def test_agent_start_stops_quickly():
        agent_dir = Path('{rel_path}')
        env = os.environ.copy()
        env['QWE_DRY_RUN'] = 'true'
        env['QWE_URL'] = env.get('QWE_URL', 'http://127.0.0.1:9001/api/v1/agents/message')
        p = subprocess.Popen(['bash', './start.sh'], cwd=str(agent_dir), env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        try:
            time.sleep(1)
            p.terminate()
            p.wait(timeout=2)
        except Exception:
            p.kill()
            p.wait(timeout=2)
        assert p.returncode is not None
''')


def create_agent(agent_name: str, channel: str = 'agents', repo_root: Path = Path('.')) -> Path:
    agents_dir = repo_root / 'tools' / 'qwe' / 'agents'
    agent_dir = agents_dir / agent_name
    agent_dir.mkdir(parents=True, exist_ok=True)

    # Create agent.py
    agent_py = AGENT_PY_TEMPLATE.format(agent_name=agent_name, channel=channel)
    (agent_dir / 'agent.py').write_text(agent_py)
    os.chmod(agent_dir / 'agent.py', 0o755)

    # Create start.sh
    start_sh = RUN_SH_TEMPLATE.format(agent_name=agent_name)
    (agent_dir / 'start.sh').write_text(start_sh)
    os.chmod(agent_dir / 'start.sh', 0o755)

    # README
    (agent_dir / 'README.md').write_text(README_TEMPLATE.format(agent_name=agent_name))

    # Tests
    tests_dir = repo_root / 'tools' / 'qwe' / 'tests'
    tests_dir.mkdir(parents=True, exist_ok=True)
    rel_path = f"tools/qwe/agents/{agent_name}"
    test_file = tests_dir / f"test_agent_{agent_name}.py"
    test_file.write_text(PYTEST_TEMPLATE.format(rel_path=rel_path))

    print(f'Created agent at {agent_dir}')
    return agent_dir


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['create'])
    parser.add_argument('name')
    parser.add_argument('--channel', default='agents')
    parser.add_argument('--path', default='.')
    args = parser.parse_args()
    repo_root = Path(args.path).resolve()
    if args.action == 'create':
        create_agent(args.name, args.channel, repo_root)


if __name__ == '__main__':
    main()
