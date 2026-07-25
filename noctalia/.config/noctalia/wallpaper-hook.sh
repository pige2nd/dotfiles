#!/usr/bin/env bash
set -euo pipefail

wallpaper=${NOCTALIA_WALLPAPER_PATH:-}
if [[ -z "$wallpaper" ]]; then
  wallpaper=$(noctalia msg wallpaper-get 2>/dev/null || true)
fi

case "${wallpaper,,}" in
  *.mp4|*.webm|*.mkv|*.mov|*.gif) ;;
  *) exit 0 ;;
esac

[[ -f "$wallpaper" ]] || exit 0
command -v ffmpeg >/dev/null 2>&1 || exit 0

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/noctalia/mpvpaper"
mkdir -p "$cache_dir"
hash=$(printf '%s' "$wallpaper" | sha256sum | cut -d' ' -f1)
thumbnail="$cache_dir/$hash.jpg"

if [[ ! -f "$thumbnail" ]]; then
  temporary="$thumbnail.tmp.jpg"
  if ffmpeg -loglevel error -y -ss 1 -i "$wallpaper" -frames:v 1 "$temporary"; then
    mv "$temporary" "$thumbnail"
  else
    rm -f "$temporary"
    exit 0
  fi
fi

# The static frame lets Noctalia extract a Material You palette while the
# mpvpaper plugin continues rendering the actual video.
current=$(noctalia msg wallpaper-get 2>/dev/null || true)
[[ "$current" == "$thumbnail" ]] || noctalia msg wallpaper-set "$thumbnail" >/dev/null 2>&1 || true
