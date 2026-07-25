#!/usr/bin/env bash
set -euo pipefail

state_home=${NOCTALIA_STATE_HOME:-${XDG_STATE_HOME:-"$HOME/.local/state"}}
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
sources_dir="$state_home/noctalia/plugins/sources"
materialized_dir="$state_home/noctalia/plugins/materialized"
official_url=${NOCTALIA_OFFICIAL_PLUGINS_URL:-https://github.com/noctalia-dev/official-plugins}
community_url=${NOCTALIA_COMMUNITY_PLUGINS_URL:-https://github.com/noctalia-dev/community-plugins}
mpvpaper_compatible_rev=${NOCTALIA_MPV_PAPER_COMPAT_REV:-487c0288adf0d1e6f72ba96e9e2499596521249c}
staging_root=
backup_target=
clone_recovery_dir=
clone_recovery_target=
mpvpaper_target=

patch_lyrics_plugin() {
  local lyrics_target="$materialized_dir/community/lyrics"
  local lyrics_patch="$repo_dir/patches/noctalia-lyrics-posix.patch"

  [[ -f "$lyrics_target/lyrics_service.luau" && -f "$lyrics_target/lyrics.luau" ]] || return 0
  if rg -Fq 'local fieldSeparator = string.char(31)' "$lyrics_target/lyrics_service.luau" &&
      rg -Fq 'transitionElapsed = transitionElapsed + delta * 1000' "$lyrics_target/lyrics.luau" &&
      ! sed -n '/if playing then/,+2p' "$lyrics_target/lyrics.luau" |
        rg -Fq 'transitionElapsed = transitionElapsed + delta * 1000'; then
    return 0
  fi

  patch --batch --forward -p1 -d "$lyrics_target" <"$lyrics_patch"
  printf '%s\n' '已应用歌词插件的 POSIX shell 与暂停动画兼容补丁。'
}

cleanup_staging() {
  if [[ -n "$backup_target" && -e "$backup_target" ]]; then
    if [[ ! -e "$mpvpaper_target" ]]; then
      mv "$backup_target" "$mpvpaper_target"
    else
      rm -rf -- "$backup_target"
    fi
  fi
  if [[ -n "$staging_root" && -d "$staging_root" ]]; then
    rm -rf -- "$staging_root"
  fi
  if [[ -n "$clone_recovery_dir" && -e "$clone_recovery_dir" ]]; then
    if [[ -e "$clone_recovery_target" ]]; then
      rm -rf -- "$clone_recovery_target"
    fi
    mv "$clone_recovery_dir" "$clone_recovery_target"
  fi
}
trap cleanup_staging EXIT HUP INT TERM

prefetch_source() {
  local name=$1
  local url=$2
  local source_dir="$sources_dir/$name"
  local repo_dir="$source_dir/repo"
  local recovery_dir="$source_dir/.incomplete-repo.$$"

  mkdir -p "$source_dir"
  if [[ -d "$repo_dir/.git" ]] &&
      git -C "$repo_dir" rev-parse --verify HEAD >/dev/null 2>&1; then
    git -C "$repo_dir" fetch --filter=blob:none origin
  else
    if [[ -e "$repo_dir" ]]; then
      mv "$repo_dir" "$recovery_dir"
      clone_recovery_dir="$recovery_dir"
      clone_recovery_target="$repo_dir"
    fi
    # Noctalia starts both first-use clones concurrently and gives each roughly
    # 20 seconds. Fetch them sequentially here so a slow GitHub route can recover.
    if git clone --filter=blob:none --no-checkout "$url" "$repo_dir"; then
      if [[ -e "$recovery_dir" ]]; then
        rm -rf -- "$recovery_dir"
        clone_recovery_dir=
        clone_recovery_target=
      fi
    else
      if [[ -e "$repo_dir" ]]; then
        rm -rf -- "$repo_dir"
      fi
      if [[ -e "$recovery_dir" ]]; then
        mv "$recovery_dir" "$repo_dir"
        clone_recovery_dir=
        clone_recovery_target=
      fi
      return 1
    fi
  fi

  git -C "$repo_dir" rev-parse --verify HEAD >/dev/null
  printf '已预取 Noctalia 插件源：%s\n' "$name"
}

prefetch_source official "$official_url"
prefetch_source community "$community_url"

# Noctalia 5.0.0-beta.4 (the current Ubuntu package) supports plugin APIs 3-8,
# while mpvpaper 1.0.7 targets API 9. Seed the last compatible official export.
# Noctalia deliberately preserves this copy while the catalog is incompatible,
# and replaces it normally once a newer shell supports the current plugin.
mpvpaper_target="$materialized_dir/official/mpvpaper"
mpvpaper_manifest="$mpvpaper_target/plugin.toml"
max_plugin_api=${NOCTALIA_MAX_PLUGIN_API:-}
if [[ -z "$max_plugin_api" ]] &&
    dpkg-query -W -f='${Version}' noctalia 2>/dev/null | rg -q '5\.0\.0~beta\.4'; then
  max_plugin_api=8
fi
needs_compatible_mpvpaper=false
if [[ ! -f "$mpvpaper_manifest" ]]; then
  needs_compatible_mpvpaper=true
else
  materialized_id=$(sed -n 's/^id = "\([^"]*\)"/\1/p' "$mpvpaper_manifest" | head -n 1)
  materialized_api=$(sed -n 's/^plugin_api = \([0-9][0-9]*\)/\1/p' "$mpvpaper_manifest" | head -n 1)
  if [[ "$materialized_id" != noctalia/mpvpaper || -z "$materialized_api" ]]; then
    needs_compatible_mpvpaper=true
  elif [[ -n "$max_plugin_api" && "$materialized_api" -gt "$max_plugin_api" ]]; then
    needs_compatible_mpvpaper=true
  fi
fi

if [[ "$needs_compatible_mpvpaper" == true ]]; then
  official_repo="$sources_dir/official/repo"
  mkdir -p "$materialized_dir/official"
  staging_root=$(mktemp -d "$materialized_dir/official/.tmp-mpvpaper-compat.XXXXXX")
  if git -C "$official_repo" \
      --work-tree "$staging_root" \
      checkout "$mpvpaper_compatible_rev" -- mpvpaper; then
    if [[ -e "$mpvpaper_target" ]]; then
      backup_target="$materialized_dir/official/.old-mpvpaper-compat.$$"
      mv "$mpvpaper_target" "$backup_target"
      if ! mv "$staging_root/mpvpaper" "$mpvpaper_target"; then
        mv "$backup_target" "$mpvpaper_target"
        exit 1
      fi
      rm -rf -- "$backup_target"
      backup_target=
    else
      mv "$staging_root/mpvpaper" "$mpvpaper_target"
    fi
    rmdir "$staging_root"
    staging_root=
    printf '%s\n' '已安装 Noctalia beta.4 兼容的 mpvpaper 1.0.6；Shell 升级后会自动更新。'
  else
    exit 1
  fi
fi

if noctalia msg plugins source list >/dev/null 2>&1; then
  noctalia msg config-reload
  noctalia msg plugins update official
  noctalia msg plugins update community
  # Source updates are asynchronous, but the repositories were fetched above;
  # give Noctalia time to export the local revision before patching that copy.
  sleep 2
  patch_lyrics_plugin
  printf '%s\n' '已通知运行中的 Noctalia 刷新插件源。'
else
  patch_lyrics_plugin
fi
