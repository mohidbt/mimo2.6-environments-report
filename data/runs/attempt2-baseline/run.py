"""Untouched baseline using the same dataset setup and reward API as the runner."""
import dataclasses
import hashlib
import json
import logging
import subprocess
import sys
import time
import traceback
from pathlib import Path

import yaml
from mimoagent.environments.utils import make_dataset_env

out = Path(sys.argv[1])
out.mkdir(parents=True, exist_ok=False)
logging.basicConfig(level=logging.INFO, stream=sys.stdout)
checkout = Path('/home/exedev/mimoagent')
config_path = Path('/home/exedev/attempt2.yaml')
row_path = Path('/home/exedev/format-code-task-002572.jsonl')

def command(args):
    p = subprocess.run(args, cwd=checkout, text=True, capture_output=True, timeout=30)
    return {'returncode': p.returncode, 'stdout': p.stdout, 'stderr': p.stderr}

def save(name, value):
    (out / name).write_text(json.dumps(value, indent=2, default=str) + '\n')

config = yaml.safe_load(config_path.read_text())
assert config['model']['model_kwargs']['api_key'] == '${MERGE_GATEWAY_API_KEY}'
(out / 'attempt2.yaml').write_bytes(config_path.read_bytes())
(out / row_path.name).write_bytes(row_path.read_bytes())
rows = [json.loads(x) for x in row_path.read_text().splitlines() if x.strip()]
assert len(rows) == 1
instance = rows[0]
save('manifest.json', {
    'started_utc': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
    'commit': command(['git', 'rev-parse', 'HEAD']),
    'status': command(['git', 'status', '--short']),
    'image': command(['docker', 'image', 'inspect', instance['docker_image']]),
    'row_sha256': hashlib.sha256(row_path.read_bytes()).hexdigest(),
    'config_sha256': hashlib.sha256(config_path.read_bytes()).hexdigest(),
    'python': sys.version,
    'method': 'make_dataset_env -> setup_environment -> calculate_reward; no agent or model',
})
(out / 'checkout.diff').write_text(command(['git', 'diff', '--binary'])['stdout'])
env = make_dataset_env(instance, **config['environment'])
save('effective_environment.json', dataclasses.asdict(env.env.config))
result = {'stage': 'setup', 'agent_started': False}
started = time.monotonic()

def snapshot(label):
    cid = env.env.container_id
    if not cid:
        return
    save(label + '-inspect.json', command(['docker', 'inspect', cid]))
    save(label + '-memory.json', command([
        'docker', 'exec', cid, 'sh', '-c',
        'for f in memory.current memory.peak memory.max memory.swap.max memory.events; '
        'do echo "$f"; cat "/sys/fs/cgroup/$f"; done',
    ]))

try:
    print('Starting untouched baseline setup', flush=True)
    env.setup_environment()
    result['setup_seconds'] = time.monotonic() - started
    snapshot('after-setup')
    save('before-reward-worktree.json', env.execute('git status --porcelain', cwd=instance['cwd']))
    save('before-reward-conftest.json', env.execute(
        'if test -e tests/pytests/unit/modules/conftest.py; then '
        'sha256sum tests/pytests/unit/modules/conftest.py; else echo ABSENT; fi', cwd=instance['cwd']))
    result['stage'] = 'reward'
    save('progress.json', result)
    print('Setup completed; starting official reward', flush=True)
    env.attach_rollout(agent=None, task=instance['problem_statement'], result='')
    reward, output, extra = env.calculate_reward()
    result.update(reward=reward, reward_extra_info=extra, stage='complete')
    (out / 'verifier.log').write_text(output)
    save('reward_extra_info.json', extra)
    print(json.dumps(result, default=str), flush=True)
except Exception as exc:
    result.update(exception_type=type(exc).__name__, exception=str(exc), traceback=traceback.format_exc())
    traceback.print_exc()
finally:
    result['elapsed_seconds'] = time.monotonic() - started
    try:
        snapshot('final')
    except Exception as exc:
        result['snapshot_error'] = repr(exc)
    save('result.json', result)
    env.env.cleanup()
    print('Baseline artifacts saved; container cleanup requested', flush=True)
