#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
failures=0

pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1" >&2; failures=$((failures + 1)); }

require_file() {
  if [[ -f "$repo_dir/$1" ]]; then pass "$1 exists"; else fail "$1 is missing"; fi
}

required_files=(
  niri/.config/niri/config.kdl
  dms/.config/DankMaterialShell/settings.json
  vicinae/.config/vicinae/settings.json
  xresources/.Xresources
  im/.config/fcitx5/config
  im/.config/fcitx5/profile
  rime/.local/share/fcitx5/rime/rime_mint.custom.yaml
  applications/.local/share/applications/wechat.desktop
  systemd/.config/systemd/user/vicinae.service
  manifests/apt-packages.txt
  manifests/vicinae-extensions.txt
  patches/dms-notification-timeout.patch
  docs/ARCHITECTURE.md
  docs/MIGRATION.md
)

for path in "${required_files[@]}"; do require_file "$path"; done

required_commands=(dms fcitx5 jq niri patch rg stow systemctl vicinae wechat wezterm)
for command_name in "${required_commands[@]}"; do
  command -v "$command_name" >/dev/null 2>&1 &&
    pass "$command_name is installed" || fail "$command_name is missing"
done

dms_settings="$repo_dir/dms/.config/DankMaterialShell/settings.json"
if [[ -f "$dms_settings" ]]; then
  jq -e '.barConfigs[0].visible == true' "$dms_settings" >/dev/null && pass 'DMS bar is visible' || fail 'DMS bar is not visible'
  jq -e '.barConfigs[0].spacing == 0' "$dms_settings" >/dev/null && pass 'DMS bar is attached to the screen edge' || fail 'DMS bar is floating away from the screen edge'
  jq -e '.barConfigs[0].centerWidgets == ["clock"]' "$dms_settings" >/dev/null && pass 'DMS center is clock only' || fail 'DMS center has extra widgets'
  jq -e '.barConfigs[0].rightWidgets == ["systemTray","notificationButton","battery","controlCenterButton","powerMenuButton"]' "$dms_settings" >/dev/null && pass 'DMS right widgets include background-app visibility' || fail 'DMS right widgets differ'
  jq empty "$dms_settings" >/dev/null && pass 'DMS settings JSON is valid' || fail 'DMS settings JSON is invalid'
fi

vicinae_settings="$repo_dir/vicinae/.config/vicinae/settings.json"
if [[ -f "$vicinae_settings" ]]; then
  jq empty "$vicinae_settings" >/dev/null && pass 'Vicinae settings JSON is valid' || fail 'Vicinae settings JSON is invalid'
fi

niri_config="$repo_dir/niri/.config/niri/config.kdl"
if [[ -f "$niri_config" ]] && command -v niri >/dev/null 2>&1; then
  if [[ -d "$HOME/.config/niri/dms" ]]; then
    validate_dir=$(mktemp -d)
    cp "$niri_config" "$validate_dir/config.kdl"
    ln -s "$HOME/.config/niri/dms" "$validate_dir/dms"
    niri validate -c "$validate_dir/config.kdl" >/dev/null &&
      pass 'Niri config is valid' || fail 'Niri config is invalid'
    rm -rf "$validate_dir"
  else
    fail 'DMS-generated Niri includes are missing'
  fi
fi

if command -v rg >/dev/null 2>&1; then
  if rg -n '/home/xx|/usr/local/bin/vicinae|FlClash|flclash' \
    "$repo_dir/niri" "$repo_dir/dms" "$repo_dir/vicinae" "$repo_dir/systemd" \
    "$repo_dir/install.sh" 2>/dev/null; then
    fail 'portable configuration contains a machine-specific or excluded path'
  else
    pass 'portable configuration has no machine-specific or FlClash paths'
  fi
fi

for extension in store.vicinae.fuzzy-files store.vicinae.niri store.vicinae.process-manager; do
  [[ -d "$HOME/.local/share/vicinae/extensions/$extension" ]] &&
    pass "Vicinae extension $extension is installed" ||
    fail "Vicinae extension $extension is missing"
done

[[ -f "$HOME/.local/share/fcitx5/rime/rime_mint.schema.yaml" ]] &&
  pass 'Rime Mint schema is installed' || fail 'Rime Mint schema is missing'
[[ -f "$HOME/.local/share/fcitx5/rime/wanxiang-lts-zh-hans.gram" ]] &&
  pass 'Rime grammar model is installed' || fail 'Rime grammar model is missing'

wechat_desktop="$repo_dir/applications/.local/share/applications/wechat.desktop"
grep -q 'QT_QPA_PLATFORM=xcb' "$wechat_desktop" &&
  pass 'WeChat is forced through XWayland' || fail 'WeChat XWayland override is missing'

generated_binds="$HOME/.config/niri/dms/binds.kdl"
if [[ -f "$generated_binds" ]]; then
  rg -q 'spawn "vicinae" "toggle"' "$generated_binds" &&
    pass 'Super+Space launches Vicinae' || fail 'Vicinae keybind is missing'
else
  fail 'DMS-generated Niri keybinds are missing'
fi

dms_runtime="$HOME/.config/DankMaterialShell/settings.json"
[[ ! -L "$dms_runtime" ]] &&
  pass 'DMS runtime settings are not linked to the repository' ||
  fail 'DMS runtime settings pollute the repository'

[[ ! -L "$HOME/.config/fcitx5" ]] &&
  pass 'Fcitx5 runtime settings are not linked to the repository' ||
  fail 'Fcitx5 runtime settings pollute the repository'

managed_links=(
  .Xresources
  .config/niri/config.kdl
  .config/systemd/user/vicinae.service
  .config/vicinae/settings.json
  .config/wezterm/wezterm.lua
  .local/share/applications/wechat.desktop
  .local/share/fcitx5/rime/rime_mint.custom.yaml
  .pam_environment
)
for managed_path in "${managed_links[@]}"; do
  [[ -L "$HOME/$managed_path" ]] &&
    pass "$managed_path is managed by Stow" ||
    fail "$managed_path is not managed by Stow"
done

if patch --dry-run --reverse -d / -p0 < "$repo_dir/patches/dms-notification-timeout.patch" >/dev/null 2>&1; then
  pass 'DMS notification patch is fully applied'
else
  fail 'DMS notification patch is missing or incomplete'
fi

for service in dms.service vicinae.service; do
  systemctl --user is-active --quiet "$service" &&
    pass "$service is active" || fail "$service is not active"
done
waybar_state=$(systemctl --user is-enabled waybar.service 2>/dev/null || true)
case "$waybar_state" in
  masked|disabled|not-found|'') pass 'Waybar is inactive by configuration or absent' ;;
  *) fail "Waybar has an unexpected enablement state: $waybar_state" ;;
esac

for script in install.sh tests/verify-desktop.sh; do
  if [[ -f "$repo_dir/$script" ]]; then
    bash -n "$repo_dir/$script" && pass "$script syntax" || fail "$script syntax"
  fi
done

zsh -i -c exit >/dev/null 2>&1 &&
  pass 'interactive Zsh starts without configuration errors' ||
  fail 'interactive Zsh reports a configuration error'

if (( failures > 0 )); then
  printf '\n%d verification(s) failed.\n' "$failures" >&2
  exit 1
fi

printf '\nDesktop configuration is reproducible.\n'
