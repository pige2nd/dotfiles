#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if ! command -v stow >/dev/null 2>&1; then
  printf '%s\n' '错误：未找到 GNU Stow，请先安装 stow。' >&2
  exit 1
fi

cd "$repo_dir"
stow --no-folding --target="$HOME" --restow zsh tmux yazi nvim
printf '%s\n' '已部署 Zsh、Starship、tmux、Yazi 和 Neovim 配置。插件安装见 README.md。'
