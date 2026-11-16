#!/usr/bin/env bash
set -euo pipefail

yazi_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_dir=$(dirname -- "$yazi_dir")
profile=default
if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
  profile=wsl
fi

stow --dir="$repo_dir" --target="$HOME" --no-folding --restow yazi
stow --dir="$yazi_dir/profiles" --target="$HOME" --no-folding --restow "$profile"
printf '已部署 Yazi 公共配置与 %s 配置。\n' "$profile"
