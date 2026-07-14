#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if ! command -v stow >/dev/null 2>&1; then
  printf '%s\n' '错误：未找到 GNU Stow，请先安装 stow。' >&2
  exit 1
fi

cd "$repo_dir"
stow --restow wezterm zsh
printf '%s\n' '已启用 wezterm 和 zsh 配置。'
