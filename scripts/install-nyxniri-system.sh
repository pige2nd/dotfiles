#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
session_source="$repo_dir/session-files/niri-nyxniri.desktop"
session_target=/usr/share/wayland-sessions/niri-nyxniri.desktop
wrapper_source="$repo_dir/session/.local/bin/niri-nyxniri-session"
wrapper_target=/usr/local/bin/niri-nyxniri-session

sudo install -m 0755 "$wrapper_source" "$wrapper_target"
sudo install -m 0644 "$session_source" "$session_target"
printf '已安装显示管理器可访问的启动器：%s\n' "$wrapper_target"
printf '已注册登录会话：%s\n' "$session_target"
