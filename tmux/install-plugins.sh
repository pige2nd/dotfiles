#!/usr/bin/env bash
set -euo pipefail

plugin_dir="${TMUX_PLUGIN_MANAGER_PATH:-$HOME/.tmux/plugins}"
mkdir -p "$plugin_dir"

clone_or_update() {
  local repo="$1"
  local dest="$plugin_dir/${repo##*/}"

  if [[ -d "$dest/.git" ]]; then
    git -C "$dest" pull --ff-only
  elif [[ -e "$dest" ]]; then
    printf '错误：插件路径已存在但不是 Git 仓库：%s\n' "$dest" >&2
    exit 1
  else
    git clone --depth=1 "https://github.com/$repo" "$dest"
  fi
}

clone_or_update tmux-plugins/tpm
clone_or_update tmux-plugins/tmux-resurrect
clone_or_update tmux-plugins/tmux-continuum
