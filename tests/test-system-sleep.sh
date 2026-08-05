#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sleep_source="$repo_dir/system-files/systemd/sleep.conf.d/99-local-deep.conf"
installer="$repo_dir/scripts/install-system-sleep.sh"
sleep_target=/etc/systemd/sleep.conf.d/99-local-deep.conf
mode=${1:---installed}

bash -n "$installer"
rg -Fxq '[Sleep]' "$sleep_source"
rg -Fxq 'MemorySleepMode=deep' "$sleep_source"

if [[ "$mode" == '--source-only' ]]; then
  printf '%s\n' 'Systemd deep suspend source configuration is valid.'
  exit 0
fi

[[ "$mode" == '--installed' ]]
[[ -r "$sleep_target" ]]
cmp -s "$sleep_source" "$sleep_target"
systemd-analyze cat-config systemd/sleep.conf |
  awk -F= '/^MemorySleepMode=/{ mode=$2 } END { exit(mode == "deep" ? 0 : 1) }'
grep -Fq '[deep]' /sys/power/mem_sleep

printf '%s\n' 'Persistent systemd deep suspend configuration is valid.'
