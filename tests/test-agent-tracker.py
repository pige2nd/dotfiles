#!/usr/bin/env python3
"""Exercise the CLI bridge with isolated tmux and tracker sockets."""
import importlib.util
import json
import os
from pathlib import Path
import socket
import subprocess
import tempfile
import threading

root = Path(__file__).resolve().parents[1]
bridge_path = root / 'agent-tracker/bridge.py'
spec = importlib.util.spec_from_file_location('tracker_bridge', bridge_path)
bridge = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bridge)

values, count = bridge.badges([
    {'pane': '%1', 'status': 'in_progress'},
    {'pane': '%2', 'status': 'completed', 'acknowledged': False},
    {'pane': '%3', 'status': 'completed', 'acknowledged': True},
    {'pane': '%gone', 'status': 'completed', 'acknowledged': False},
], {'%1': '@1', '%2': '@1', '%3': '@2'})
assert values == {'@1': ' ~ !', '@2': ''} and count == 1
assert bridge.compact('  first\n second ') == 'first second'
assert len(bridge.compact('x' * 200)) == 160

with tempfile.TemporaryDirectory(prefix='agent-tracker-test-') as tmp:
    tmux_socket = str(Path(tmp) / 'tmux.sock')
    tmux = ['tmux', '-S', tmux_socket]
    subprocess.run(tmux + ['-f', '/dev/null', 'new-session', '-d', '-s', 'tracker-test', 'sleep 60'], check=True)
    try:
        subprocess.run(tmux + ['source-file', '-n', str(root / 'tmux/.tmux.conf')], check=True)
        config = (root / 'tmux/.tmux.conf').read_text()
        integration = config[config.index('# Agent task results:'):config.index('\nis_vim=')]
        active_config = Path(tmp) / 'tracker.conf'
        active_config.write_text(integration)
        subprocess.run(tmux + ['source-file', str(active_config)], check=True)
        assert 'bridge.py' in subprocess.check_output(tmux + ['list-keys', '-T', 'prefix', 'a'], text=True)
        assert 'bridge.py' in subprocess.check_output(tmux + ['list-keys', '-T', 'root', 'M-m'], text=True)
        for hook in ['after-select-pane', 'pane-focus-in', 'after-select-window', 'client-session-changed', 'client-attached']:
            assert 'acknowledge' in subprocess.check_output(tmux + ['show-hooks', '-g', hook], text=True)
        # Only event reporting is exercised below; avoid triggering UI hooks.
        subprocess.run(tmux + ['set-hook', '-gu', 'after-select-pane[91]'], check=True)
        pane = subprocess.check_output(tmux + ['display-message', '-p', '#{pane_id}'], text=True).strip()
        env = dict(os.environ, TMUX=f'{tmux_socket},0,0', TMUX_PANE=pane, XDG_RUNTIME_DIR=tmp)
        captured = []
        with socket.socket(socket.AF_UNIX) as server:
            server.bind(str(Path(tmp) / 'agent-tracker.sock'))
            server.listen()
            server.settimeout(5)

            def receive():
                for _ in range(8):
                    conn, _ = server.accept()
                    with conn:
                        request = json.loads(conn.makefile().readline())
                        captured.append(request)
                        conn.sendall(b'{}\n')

            listener = threading.Thread(target=receive)
            listener.start()
            events = [
                ('UserPromptSubmit', 'start_task'), ('Stop', 'finish_task'),
                ('Interrupt', 'finish_task'), ('SessionEnd', 'delete_task'),
            ]
            for event, expected in events:
                data = {'hook_event_name': event, 'prompt': 'test task', 'last_assistant_message': 'done'}
                result = subprocess.run(['python3', str(bridge_path), 'codex'], input=json.dumps(data), text=True, capture_output=True, env=env, timeout=5, check=True)
                assert result.stdout.strip() == '{}' and not result.stderr, result
                assert captured[-1]['command'] == expected
            for command in ['start_task', 'finish_task', 'delete_task']:
                subprocess.run(['python3', str(bridge_path), 'pi', json.dumps({'command': command, 'summary': 'test'})], env=env, timeout=5, check=True)
                assert captured[-1]['command'] == command
            subprocess.run(['python3', str(bridge_path), 'acknowledge', pane], env=env, timeout=5, check=True)
            listener.join(timeout=6)
            assert not listener.is_alive() and len(captured) == 8
            assert all(message['kind'] == 'command' and message['pane'] == pane and message['session'] == 'tracker-test' for message in captured)
            assert captured[-1]['command'] == 'acknowledge'
    finally:
        subprocess.run(tmux + ['kill-server'], check=True)

print('PASS: CLI lifecycle events, pane context, badges and tmux integration.')
