import os
import sys
from pathlib import Path
import shutil

# Make tools/qwe importable, mirroring existing tests
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
import agent_gen as agent_gen


def test_create_agent(tmp_path):
    repo_root = tmp_path
    (repo_root / 'tools' / 'qwe').mkdir(parents=True, exist_ok=True)
    agent_dir = agent_gen.create_agent('unit-test-agent', 'testing', repo_root=repo_root)
    assert (agent_dir / 'agent.py').exists()
    assert (agent_dir / 'start.sh').exists()
    assert (agent_dir / 'README.md').exists()
