#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
session_source="$repo_dir/session-files/niri-nyxniri.desktop"
session_target=/usr/share/wayland-sessions/niri-nyxniri.desktop

if [[ ! -x "$HOME/.local/bin/niri-nyxniri-session" ]]; then
  printf '%s\n' '错误：请先运行仓库根目录的 ./install.sh。' >&2
  exit 1
fi

temporary=$(mktemp)
trap 'rm -f "$temporary"' EXIT
sed "s|@HOME@|$HOME|g" "$session_source" >"$temporary"
sudo install -m 0644 "$temporary" "$session_target"
printf '已注册登录会话：%s\n' "$session_target"
