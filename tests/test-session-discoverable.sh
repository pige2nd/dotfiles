#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
desktop_source="$repo_dir/session-files/niri-nyxniri.desktop"
desktop_runtime=/usr/share/wayland-sessions/niri-nyxniri.desktop
expected_exec=/usr/local/bin/niri-nyxniri-session
wrapper_source="$repo_dir/session/.local/bin/niri-nyxniri-session"

source_tryexec=$(sed -n 's/^TryExec=//p' "$desktop_source")
[[ "$source_tryexec" == "$expected_exec" ]]

[[ -f "$desktop_runtime" ]]
runtime_tryexec=$(sed -n 's/^TryExec=//p' "$desktop_runtime")
[[ "$runtime_tryexec" == "$expected_exec" ]]
[[ -x "$runtime_tryexec" ]]
cmp -s "$wrapper_source" "$runtime_tryexec"

case "$runtime_tryexec" in
  /home/*)
    printf 'GDM cannot reliably traverse a private home-directory TryExec.\n' >&2
    exit 1
    ;;
esac

printf '%s\n' 'NyxNiri session launcher is visible to the display manager.'
