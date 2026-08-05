#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sleep_source="$repo_dir/system-files/systemd/sleep.conf.d/99-local-deep.conf"
sleep_target=/etc/systemd/sleep.conf.d/99-local-deep.conf

if ! grep -qw deep /sys/power/mem_sleep; then
  printf '%s\n' '错误：这台电脑不支持 deep 挂起模式。' >&2
  exit 1
fi

sudo install -d -m 0755 /etc/systemd/sleep.conf.d
sudo install -m 0644 "$sleep_source" "$sleep_target"
printf '%s\n' deep | sudo tee /sys/power/mem_sleep >/dev/null

"$repo_dir/tests/test-system-sleep.sh"
printf '已将 systemd 挂起模式设为 deep：%s\n' "$sleep_target"
