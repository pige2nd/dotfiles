#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if ! command -v stow >/dev/null 2>&1; then
  printf '%s\n' '错误：未找到 GNU Stow，请先安装 stow。' >&2
  exit 1
fi

packages=(wezterm zsh niri niri-nyxniri noctalia session vicinae xresources systemd im rime applications)

cd "$repo_dir"
# Earlier NyxNiri revisions deployed Noctalia hooks as ordinary files. Migrate
# only byte-identical copies; never overwrite a locally edited hook.
for hook_name in theme-sync.sh wallpaper-hook.sh mpv-hook.lua; do
  hook_source="$repo_dir/noctalia/.config/noctalia/$hook_name"
  hook_target="$HOME/.config/noctalia/$hook_name"
  if [[ -f "$hook_target" && ! -L "$hook_target" ]]; then
    if cmp -s "$hook_source" "$hook_target"; then
      unlink "$hook_target"
    else
      printf '错误：保留已修改的 Noctalia Hook：%s\n' "$hook_target" >&2
      printf '%s\n' '请先备份或合并该文件，再重新运行 install.sh。' >&2
      exit 1
    fi
  fi
done

# Never fold a whole runtime-capable directory into the repository. DMS,
# Vicinae, Rime and desktop applications may create sibling files later.
stow --no-folding --restow "${packages[@]}"

# The active NyxNiri effect is runtime state. Keep the switchable symlink out
# of Git so eye-care toggles never write back into the Stow-managed repository.
nyxniri_dir="$HOME/.config/niri/nyxniri"
effects_link="$nyxniri_dir/effects.kdl"
if [[ ! -e "$effects_link" && ! -L "$effects_link" ]]; then
  ln -s effects_normal.kdl "$effects_link"
fi

# The independent NyxNiri config reuses the same visual/rule files and
# eye-care selector without changing the regular DMS-owned Niri config.
nyxniri_session_dir="$HOME/.config/niri-nyxniri"
mkdir -p "$nyxniri_session_dir"
if [[ ! -e "$nyxniri_session_dir/nyxniri" && ! -L "$nyxniri_session_dir/nyxniri" ]]; then
  ln -s ../niri/nyxniri "$nyxniri_session_dir/nyxniri"
fi

# Noctalia rewrites config.toml, so deploy a runtime copy from a portable seed.
noctalia_seed="$repo_dir/seeds/noctalia/config.toml.in"
noctalia_target="$HOME/.config/noctalia"
wallpaper_dir="$HOME/Pictures/Wallpapers"
video_wallpaper_dir="$wallpaper_dir/video"
mkdir -p "$noctalia_target" "$video_wallpaper_dir"
if [[ ! -e "$noctalia_target/config.toml" ]]; then
  sed \
    -e "s|@WALLPAPER_DIR@|$wallpaper_dir|g" \
    -e "s|@VIDEO_WALLPAPER_DIR@|$video_wallpaper_dir|g" \
    "$noctalia_seed" >"$noctalia_target/config.toml"
else
  printf '保留已有 Noctalia 配置：%s\n' "$noctalia_target/config.toml"
fi

# DMS rewrites settings.json at runtime, so install a copy rather than a Stow
# symlink. The repository remains the reproducible seed, not runtime state.
dms_source="$repo_dir/dms/.config/DankMaterialShell/settings.json"
dms_target="$HOME/.config/DankMaterialShell/settings.json"
mkdir -p "$(dirname -- "$dms_target")"
if [[ -L "$dms_target" ]]; then
  unlink "$dms_target"
fi
install -m 0644 "$dms_source" "$dms_target"

# Fcitx5 also normalizes its configuration files while running. Seed a normal
# directory so those writes remain machine-local.
fcitx_source="$repo_dir/im/.config/fcitx5"
fcitx_target="$HOME/.config/fcitx5"
if [[ -L "$fcitx_target" ]]; then
  unlink "$fcitx_target"
fi
mkdir -p "$fcitx_target"
cp -a "$fcitx_source/." "$fcitx_target/"

systemctl --user daemon-reload
systemctl --user enable --now vicinae.service
systemctl --user enable --now dms.service

# DMS owns Niri's generated bind file. Store the override through its CLI.
dms keybinds set niri Mod+Space 'spawn vicinae toggle' \
  --desc 'Vicinae Launcher'
dms keybinds set niri Mod+Ctrl+N \
  'spawn ~/.config/niri/nyxniri/toggle-eyecare.sh' \
  --desc 'Toggle Eye-care Mode'

# Waybar may stay installed as an emergency fallback, but is not active.
if systemctl --user list-unit-files waybar.service --no-legend 2>/dev/null | grep -q '^waybar.service'; then
  # The package enables Waybar globally; a user mask is required to override it.
  systemctl --user mask --now waybar.service
fi

printf '%s\n' '已启用 Niri、DMS、Vicinae、Fcitx5、WezTerm 和 Zsh 配置。'
