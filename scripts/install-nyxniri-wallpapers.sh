#!/usr/bin/env bash
set -euo pipefail

source_dir=${1:-}
destination="$HOME/Pictures/Wallpapers"

if [[ -z "$source_dir" ]]; then
  printf '用法：%s /path/to/NyxNiri/Wallpapers\n' "$0" >&2
  exit 2
fi
if [[ ! -d "$source_dir" ]]; then
  printf '错误：壁纸目录不存在：%s\n' "$source_dir" >&2
  exit 1
fi

mkdir -p "$destination"
cp -a --update=none "$source_dir/." "$destination/"
printf 'NyxNiri 壁纸已补充到 %s（已有同名文件未覆盖）。\n' "$destination"
