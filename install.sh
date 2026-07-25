#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if ! command -v stow >/dev/null 2>&1; then
  printf '%s\n' '错误：未找到 GNU Stow，请先安装 stow。' >&2
  exit 1
fi

packages=(wezterm zsh niri vicinae xresources systemd im rime applications)

cd "$repo_dir"
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
