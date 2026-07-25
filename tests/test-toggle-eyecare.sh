#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
script="$repo_dir/niri/.config/niri/nyxniri/toggle-eyecare.sh"
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT

config_home="$fixture/config"
state_home="$fixture/state"
nyxniri_dir="$config_home/niri/nyxniri"
mock_log="$fixture/desktop-calls.log"

mkdir -p "$nyxniri_dir" "$state_home"
touch \
  "$config_home/niri/config.kdl" \
  "$nyxniri_dir/effects_normal.kdl" \
  "$nyxniri_dir/effects_eyecare.kdl"
ln -s effects_normal.kdl "$nyxniri_dir/effects.kdl"

niri() {
  printf 'niri %s\n' "$*" >>"$MOCK_LOG"
  if [[ "$1" == validate ]]; then
    return 0
  fi
  if [[ "${MOCK_NIRI_FAIL_LOAD:-0}" == 1 ]]; then
    return 1
  fi
}

dms() {
  printf 'dms %s\n' "$*" >>"$MOCK_LOG"
  if [[ "$*" == "ipc call night status" ]]; then
    printf 'Night mode: %s\n' "${MOCK_NIGHT_STATUS:-disabled}"
    return 0
  fi
  [[ "${MOCK_DMS_FAIL:-0}" != 1 ]]
}

noctalia() {
  printf 'noctalia %s\n' "$*" >>"$MOCK_LOG"
  if [[ "$*" == "config export full" ]]; then
    printf '[nightlight]\nforce = %s\n' "${MOCK_NOCTALIA_FORCE:-false}"
    return 0
  fi
  [[ "${MOCK_NOCTALIA_FAIL:-0}" != 1 ]]
}

export -f niri dms noctalia
export MOCK_LOG="$mock_log"
export XDG_CONFIG_HOME="$config_home"
export XDG_STATE_HOME="$state_home"

MOCK_NIGHT_STATUS=enabled "$script" >/dev/null
[[ $(readlink "$nyxniri_dir/effects.kdl") == effects_eyecare.kdl ]]
[[ $(<"$state_home/niri/nyxniri-eyecare") == enabled ]]

"$script" >/dev/null
[[ $(readlink "$nyxniri_dir/effects.kdl") == effects_normal.kdl ]]
[[ ! -e "$state_home/niri/nyxniri-eyecare" ]]
[[ $(tail -n 1 "$mock_log") == 'dms ipc call night enable' ]]

MOCK_NIGHT_STATUS=disabled "$script" >/dev/null
MOCK_DMS_FAIL=1 "$script" >/dev/null 2>&1 && exit 1
[[ $(readlink "$nyxniri_dir/effects.kdl") == effects_eyecare.kdl ]]
[[ $(<"$state_home/niri/nyxniri-eyecare") == disabled ]]

"$script" >/dev/null
[[ $(readlink "$nyxniri_dir/effects.kdl") == effects_normal.kdl ]]
[[ ! -e "$state_home/niri/nyxniri-eyecare" ]]

MOCK_NIRI_FAIL_LOAD=1 MOCK_NIGHT_STATUS=disabled \
  "$script" >/dev/null 2>&1 && exit 1
[[ $(readlink "$nyxniri_dir/effects.kdl") == effects_normal.kdl ]]
[[ ! -e "$state_home/niri/nyxniri-eyecare" ]]

XDG_SESSION_DESKTOP=NyxNiri NIRI_CONFIG="$config_home/niri/config.kdl" \
  "$script" >/dev/null
[[ $(readlink "$nyxniri_dir/effects.kdl") == effects_eyecare.kdl ]]
[[ $(<"$state_home/niri/nyxniri-eyecare") == noctalia-unforced ]]
[[ $(tail -n 1 "$mock_log") == 'noctalia msg nightlight-force-toggle' ]]

XDG_SESSION_DESKTOP=NyxNiri NIRI_CONFIG="$config_home/niri/config.kdl" \
  "$script" >/dev/null
[[ $(readlink "$nyxniri_dir/effects.kdl") == effects_normal.kdl ]]
[[ ! -e "$state_home/niri/nyxniri-eyecare" ]]
[[ $(tail -n 1 "$mock_log") == 'noctalia msg nightlight-force-toggle' ]]

toggle_count=$(grep -c '^noctalia msg nightlight-force-toggle$' "$mock_log")
MOCK_NOCTALIA_FORCE=true XDG_SESSION_DESKTOP=NyxNiri \
  NIRI_CONFIG="$config_home/niri/config.kdl" "$script" >/dev/null
[[ $(<"$state_home/niri/nyxniri-eyecare") == noctalia-forced ]]
[[ $(grep -c '^noctalia msg nightlight-force-toggle$' "$mock_log") == "$toggle_count" ]]

XDG_SESSION_DESKTOP=NyxNiri NIRI_CONFIG="$config_home/niri/config.kdl" \
  "$script" >/dev/null
[[ ! -e "$state_home/niri/nyxniri-eyecare" ]]
[[ $(grep -c '^noctalia msg nightlight-force-toggle$' "$mock_log") == "$toggle_count" ]]

MOCK_NOCTALIA_FAIL=1 XDG_SESSION_DESKTOP=NyxNiri \
  NIRI_CONFIG="$config_home/niri/config.kdl" \
  "$script" >/dev/null 2>&1 && exit 1
[[ $(readlink "$nyxniri_dir/effects.kdl") == effects_normal.kdl ]]
[[ ! -e "$state_home/niri/nyxniri-eyecare" ]]

printf '%s\n' 'Eye-care toggle preserves DMS state and rolls back failed transitions.'
