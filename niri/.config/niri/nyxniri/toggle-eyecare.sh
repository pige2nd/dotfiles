#!/usr/bin/env bash
set -euo pipefail

config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
state_home=${XDG_STATE_HOME:-"$HOME/.local/state"}
nyxniri_dir="$config_home/niri/nyxniri"
state_dir="$state_home/niri"
state_file="$state_dir/nyxniri-eyecare"
effects_link="$nyxniri_dir/effects.kdl"

mkdir -p "$state_dir"

if [[ -e "$state_file" ]]; then
  next_effect=effects_normal.kdl
  previous_effect=effects_eyecare.kdl
  next_mode=normal
  previous_night_state=$(<"$state_file")
else
  next_effect=effects_eyecare.kdl
  previous_effect=effects_normal.kdl
  next_mode=eye-care
  previous_night_state=unknown

  if command -v dms >/dev/null 2>&1; then
    night_status=$(dms ipc call night status 2>/dev/null || true)
    case "$night_status" in
      *"Night mode: enabled"*) previous_night_state=enabled ;;
      *"Night mode: disabled"*) previous_night_state=disabled ;;
    esac
  fi
fi

ln -sfn "$next_effect" "$effects_link"

if ! niri validate -c "$config_home/niri/config.kdl" >/dev/null; then
  ln -sfn "$previous_effect" "$effects_link"
  printf 'NyxNiri: refusing to activate an invalid %s configuration.\n' "$next_mode" >&2
  exit 1
fi

if ! niri msg action load-config-file >/dev/null 2>&1; then
  ln -sfn "$previous_effect" "$effects_link"
  niri msg action load-config-file >/dev/null 2>&1 || true
  printf 'NyxNiri: Niri rejected the %s mode reload; the previous effect was restored.\n' "$next_mode" >&2
  exit 1
fi

dms_warning=
if [[ "$next_mode" == eye-care ]]; then
  printf '%s\n' "$previous_night_state" >"$state_file"

  if ! command -v dms >/dev/null 2>&1 ||
    ! dms ipc call night enable >/dev/null 2>&1; then
    dms_warning='DMS night mode was unavailable; only the visual effect changed.'
  fi
else
  case "$previous_night_state" in
    enabled) night_action=enable ;;
    disabled) night_action=disable ;;
    *) night_action= ;;
  esac

  if [[ -n "$night_action" ]] &&
    { ! command -v dms >/dev/null 2>&1 ||
      ! dms ipc call night "$night_action" >/dev/null 2>&1; }; then
    ln -sfn "$previous_effect" "$effects_link"
    niri msg action load-config-file >/dev/null 2>&1 || true
    printf '%s\n' \
      'NyxNiri: DMS night mode could not be restored; eye-care mode remains active for a later retry.' >&2
    exit 1
  fi

  rm -f "$state_file"
fi

if [[ -n "$dms_warning" ]]; then
  printf 'NyxNiri: %s\n' "$dms_warning" >&2
fi
printf 'NyxNiri: %s mode enabled.\n' "$next_mode"
