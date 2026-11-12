#!/usr/bin/env python3
"""CLI lifecycle events and tmux display for theniceboy's tracker server."""
import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import time


def tmux(*args):
    return subprocess.check_output(['tmux', *args], text=True, stderr=subprocess.DEVNULL).strip()


def connect():
    sock = socket.socket(socket.AF_UNIX)
    sock.settimeout(1)
    sock.connect(str(Path(os.environ.get('XDG_RUNTIME_DIR', '/tmp')) / 'agent-tracker.sock'))
    return sock


def context(pane):
    values = tmux('display-message', '-p', '-t', pane,
                  '#{session_id}\t#{window_id}\t#{pane_id}\t#{session_name}\t#{window_name}').split('\t')
    return dict(zip(['session_id', 'window_id', 'pane', 'session', 'window'], values))


def send(command, pane, summary=''):
    message = dict(kind='command', command=command, summary=summary, **context(pane))
    with connect() as sock:
        sock.sendall((json.dumps(message) + '\n').encode())
        json.loads(sock.makefile().readline())


def state():
    with connect() as sock:
        sock.sendall(b'{"kind":"ui-register"}\n')
        return json.loads(sock.makefile().readline()).get('tasks', [])


def compact(text):
    return ' '.join(str(text or '').split())[:160]


def codex_event(data, pane):
    event = data.get('hook_event_name')
    if event == 'UserPromptSubmit':
        send('start_task', pane, 'Codex: ' + compact(data.get('prompt')))
    elif event == 'Stop':
        send('finish_task', pane, 'Codex: ' + compact(data.get('last_assistant_message') or 'Turn finished'))
    elif event == 'Interrupt':
        send('finish_task', pane, 'interrupted')
    elif event == 'SessionEnd':
        send('delete_task', pane)


def badges(tasks, live):
    running = set()
    unread = set()
    unread_count = 0
    for task in tasks:
        window = live.get(task.get('pane'))
        if not window:
            continue
        if task['status'] == 'in_progress':
            running.add(window)
        elif not task.get('acknowledged', True):
            unread.add(window)
            unread_count += 1
    return {window: (' ~' if window in running else '') + (' !' if window in unread else '')
            for window in set(live.values())}, unread_count


def listen():
    while True:
        try:
            with connect() as sock:
                sock.settimeout(None)
                sock.sendall(b'{"kind":"ui-register"}\n')
                previous = {}
                for line in sock.makefile():
                    tasks = json.loads(line).get('tasks', [])
                    try:
                        rows = tmux('list-panes', '-a', '-F', '#{pane_id}\t#{window_id}')
                    except subprocess.CalledProcessError:
                        continue
                    live = dict(row.split('\t') for row in rows.splitlines())
                    values, count = badges(tasks, live)
                    for window, value in values.items():
                        if previous.get(window) != value:
                            tmux('set-option', '-wq', '-t', window, '@tracker_badge', value)
                    previous = values
                    tmux('set-option', '-gq', '@tracker_unread', str(count))
                    for client in tmux('list-clients', '-F', '#{client_name}').splitlines():
                        tmux('refresh-client', '-S', '-t', client)
        except (OSError, ValueError, subprocess.CalledProcessError) as error:
            print(f'agent-tracker bridge: {error}', file=sys.stderr)
        time.sleep(1)


def jump(pane, client):
    target = context(pane)
    tmux('switch-client', '-c', client, '-t', target['session_id'])
    tmux('select-window', '-t', target['window_id'])
    tmux('select-pane', '-t', pane)
    send('acknowledge', pane)


def choose(mode, client):
    live = set(tmux('list-panes', '-a', '-F', '#{pane_id}').splitlines())
    tasks = [task for task in state() if task.get('pane') in live]
    tasks.sort(key=lambda task: task.get('completed_at') or task.get('started_at', ''), reverse=True)
    if mode == 'latest':
        pending = [task for task in tasks if task['status'] == 'completed' and not task['acknowledged']]
        if pending:
            jump(pending[0]['pane'], client)
        else:
            tmux('display-message', '-c', client, 'No unread agent results')
        return
    rows = []
    for task in tasks:
        status = 'RUN' if task['status'] == 'in_progress' else ('SEEN' if task['acknowledged'] else 'NEW')
        rows.append('\t'.join([task['pane'], status, compact(task['session']), compact(task['window']),
                               compact(task.get('completion_note') or task['summary'])]))
    result = subprocess.run(['fzf', '--delimiter=\t', '--with-nth=2..', '--no-multi', '--prompt=Tasks> ',
                             '--bind=alt-j:up,alt-k:down'], input='\n'.join(rows), text=True, capture_output=True)
    if result.returncode == 0:
        jump(result.stdout.split('\t', 1)[0], client)


def main():
    mode = sys.argv[1]
    try:
        if mode == 'listen':
            listen()
        elif mode in ('pick', 'latest'):
            choose(mode, sys.argv[2])
        elif mode == 'acknowledge':
            send('acknowledge', sys.argv[2])
        elif os.environ.get('TMUX') and os.environ.get('TMUX_PANE'):
            pane = os.environ['TMUX_PANE']
            if mode == 'codex':
                codex_event(json.load(sys.stdin), pane)
            elif mode == 'pi':
                data = json.loads(sys.argv[2])
                send(data['command'], pane, compact(data.get('summary')))
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        # Tracking must not turn a completed CLI turn into a hook failure.
        print(f'agent-tracker bridge: {error}', file=sys.stderr)
    finally:
        if mode == 'codex':
            print('{}')


if __name__ == '__main__':
    main()
