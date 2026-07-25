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
  niri/.config/niri/nyxniri/effects_eyecare.kdl
  niri/.config/niri/nyxniri/effects_normal.kdl
  niri/.config/niri/nyxniri/toggle-eyecare.sh
  niri/.config/niri/nyxniri/visuals.kdl
  niri/.config/niri/nyxniri/window-rules.kdl
  niri-nyxniri/.config/niri-nyxniri/config.kdl
  seeds/noctalia/config.toml.in
  noctalia/.config/noctalia/theme-sync.sh
  noctalia/.config/noctalia/wallpaper-hook.sh
  noctalia/.config/noctalia/mpv-hook.lua
  session/.local/bin/niri-nyxniri-session
  session-files/niri-nyxniri.desktop
  scripts/install-nyxniri-system.sh
  scripts/install-nyxniri-deps.sh
  scripts/prefetch-noctalia-plugins.sh
  scripts/install-nyxniri-wallpapers.sh
  tests/test-noctalia-plugins.sh
  tests/test-nyxniri-session.sh
  tests/test-session-discoverable.sh
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

required_commands=(dms fcitx5 ffmpeg jq mpv mpvpaper niri noctalia patch playerctl rg stow systemctl vicinae wechat wezterm)
for command_name in "${required_commands[@]}"; do
  command -v "$command_name" >/dev/null 2>&1 &&
    pass "$command_name is installed" || fail "$command_name is missing"
done

dms_settings="$repo_dir/dms/.config/DankMaterialShell/settings.json"
if [[ -f "$dms_settings" ]]; then
  jq -e '.barConfigs[0].visible == true' "$dms_settings" >/dev/null && pass 'DMS bar is visible' || fail 'DMS bar is not visible'
  jq -e '[.barConfigs[0].leftWidgets[] | if type == "string" then . else select(.enabled != false) | .id end] == ["launcherButton","workspaceSwitcher","focusedWindow"]' "$dms_settings" >/dev/null &&
    pass 'DMS left bar matches the NyxNiri layout' || fail 'DMS left bar differs from the NyxNiri layout'
  jq -e '.barConfigs[0].centerWidgets == ["clock"]' "$dms_settings" >/dev/null && pass 'DMS center is clock only' || fail 'DMS center has extra widgets'
  jq -e '.barConfigs[0].rightWidgets == ["music","systemTray","notificationButton","battery","controlCenterButton","powerMenuButton"]' "$dms_settings" >/dev/null &&
    pass 'DMS right bar matches the NyxNiri layout' || fail 'DMS right bar differs from the NyxNiri layout'
  jq -e '.barConfigs[0] | .transparency == 0 and .widgetTransparency == 0.8 and .spacing == 4 and .widgetOutlineEnabled == true' "$dms_settings" >/dev/null &&
    pass 'DMS bar uses NyxNiri floating capsules' || fail 'DMS bar capsule styling differs'
  jq empty "$dms_settings" >/dev/null && pass 'DMS settings JSON is valid' || fail 'DMS settings JSON is invalid'
fi

vicinae_settings="$repo_dir/vicinae/.config/vicinae/settings.json"
if [[ -f "$vicinae_settings" ]]; then
  jq empty "$vicinae_settings" >/dev/null && pass 'Vicinae settings JSON is valid' || fail 'Vicinae settings JSON is invalid'
fi

niri_config="$repo_dir/niri/.config/niri/config.kdl"
if [[ -f "$niri_config" ]] && command -v niri >/dev/null 2>&1; then
  if [[ -d "$HOME/.config/niri/dms" && -d "$HOME/.config/niri/nyxniri" ]]; then
    validate_dir=$(mktemp -d)
    cp "$niri_config" "$validate_dir/config.kdl"
    ln -s "$HOME/.config/niri/dms" "$validate_dir/dms"
    ln -s "$HOME/.config/niri/nyxniri" "$validate_dir/nyxniri"
    niri validate -c "$validate_dir/config.kdl" >/dev/null &&
      pass 'Niri config is valid' || fail 'Niri config is invalid'
    rm -rf "$validate_dir"
  else
    fail 'DMS-generated or NyxNiri Niri includes are missing'
  fi
fi

if [[ -f "$niri_config" ]]; then
  for include_path in \
    nyxniri/visuals.kdl \
    nyxniri/effects.kdl \
    nyxniri/window-rules.kdl; do
    rg -q "include \"$include_path\"" "$niri_config" &&
      pass "Niri includes $include_path" ||
      fail "Niri does not include $include_path"
  done
fi

nyxniri_config="$repo_dir/niri-nyxniri/.config/niri-nyxniri/config.kdl"
if [[ -f "$nyxniri_config" ]] && command -v niri >/dev/null 2>&1; then
  validate_dir=$(mktemp -d)
  cp "$nyxniri_config" "$validate_dir/config.kdl"
  ln -s "$HOME/.config/niri/nyxniri" "$validate_dir/nyxniri"
  niri validate -c "$validate_dir/config.kdl" >/dev/null &&
    pass 'NyxNiri session config is valid' || fail 'NyxNiri session config is invalid'
  rm -rf "$validate_dir"
fi

if [[ -f "$nyxniri_config" ]]; then
  rg -q 'spawn-at-startup "noctalia"' "$nyxniri_config" &&
    pass 'NyxNiri starts Noctalia' || fail 'NyxNiri does not start Noctalia'
  rg -q 'spawn "vicinae" "toggle"' "$nyxniri_config" &&
    pass 'NyxNiri keeps Vicinae as launcher' || fail 'NyxNiri does not keep Vicinae'
  rg -q 'spawn "wezterm"' "$nyxniri_config" &&
    pass 'NyxNiri keeps WezTerm' || fail 'NyxNiri does not keep WezTerm'
  rg -Fq 'place-within-backdrop true' "$nyxniri_config" &&
    rg -Fq 'background-color "transparent"' "$nyxniri_config" &&
    pass 'NyxNiri exposes the wallpaper through the workspace backdrop' ||
    fail 'NyxNiri workspace background hides the wallpaper'
  if rg -n 'GBM_BACKEND|__GLX_VENDOR_LIBRARY_NAME|LIBVA_DRIVER_NAME.*nvidia' "$nyxniri_config"; then
    fail 'NyxNiri contains NVIDIA-only environment variables'
  else
    pass 'NyxNiri is free of NVIDIA-only environment variables'
  fi
fi

noctalia_seed="$repo_dir/seeds/noctalia/config.toml.in"
if [[ -f "$noctalia_seed" ]]; then
  rg -Fq 'start = ["vicinae-launcher", "workspaces", "active_window"]' "$noctalia_seed" &&
    rg -Fq '[widget.vicinae-launcher]' "$noctalia_seed" &&
    rg -Fq 'command = "vicinae toggle"' "$noctalia_seed" &&
    pass 'Noctalia search capsule launches Vicinae' ||
    fail 'Noctalia search capsule does not launch Vicinae'
  rg -Fq 'center = ["clock"]' "$noctalia_seed" &&
    pass 'Noctalia center bar matches NyxNiri' || fail 'Noctalia center bar differs'
  rg -Fq 'end = ["lyrics", "tray", "wallpaper", "mpvpaper", "volume", "notifications", "session"]' "$noctalia_seed" &&
    rg -Fq 'max_chars = 10' "$noctalia_seed" &&
    ! rg -q 'capsule_group|group:media_and_lyrics' "$noctalia_seed" &&
    pass 'Noctalia uses one compact lyrics and track capsule' ||
    fail 'Noctalia media presentation is duplicated or too wide'
  rg -Fq 'enabled = ["noctalia/mpvpaper", "h465855hgg/lyrics"]' "$noctalia_seed" &&
    pass 'Noctalia wallpaper and lyrics plugins are enabled' || fail 'Noctalia plugin selection differs'
  rg -Fq 'type = "fancy_audio_visualizer"' "$noctalia_seed" &&
    pass 'Noctalia desktop audio visualizer is enabled' || fail 'Noctalia desktop audio visualizer is disabled'
  rg -Fq 'ui_scale = 1.2' "$noctalia_seed" &&
    pass 'Noctalia non-bar UI uses the NyxNiri scale' || fail 'Noctalia UI scale differs'
  rg -Fq 'telemetry_enabled = false' "$noctalia_seed" &&
    pass 'Noctalia telemetry is explicitly disabled' || fail 'Noctalia telemetry is not explicitly disabled'
  rg -q 'source = "wallpaper"' "$noctalia_seed" &&
    pass 'Noctalia Material You follows wallpaper' || fail 'Noctalia theme does not follow wallpaper'
  rg -q '@WALLPAPER_DIR@' "$noctalia_seed" &&
    pass 'Noctalia wallpaper paths are portable' || fail 'Noctalia wallpaper path is not templated'
fi

session_wrapper="$repo_dir/session/.local/bin/niri-nyxniri-session"
if [[ -f "$session_wrapper" ]]; then
  rg -Fq 'systemctl --user mask --runtime --now dms.service' "$session_wrapper" &&
    pass 'NyxNiri runtime-masks DMS at session entry' || fail 'NyxNiri does not isolate DMS'
  rg -q 'systemctl --user start dms.service' "$session_wrapper" &&
    pass 'NyxNiri restores DMS at session exit' || fail 'NyxNiri does not restore DMS'
  rg -q 'systemctl --user unset-environment' "$session_wrapper" &&
    pass 'NyxNiri clears imported session variables' || fail 'NyxNiri leaks session variables'
  if rg -Fq 'systemctl --user mask --runtime --now dms.service >/dev/null 2>&1 || true' "$session_wrapper"; then
    fail 'NyxNiri ignores DMS mask failures'
  else
    pass 'NyxNiri aborts when DMS cannot be masked'
  fi
  rg -q 'NIRI_CONFIG=.*niri-nyxniri/config.kdl' "$session_wrapper" &&
    pass 'NyxNiri uses an independent Niri config' || fail 'NyxNiri reuses the DMS config'
fi

wechat_rules="$repo_dir/niri/.config/niri/nyxniri/window-rules.kdl"
rg -Fq 'app-id=r"^wechat$"' "$wechat_rules" &&
  pass 'WeChat has a dedicated Niri rule' || fail 'WeChat Niri rule is missing'
rg -Uq 'app-id=r"\^wechat\$"\s+open-floating false\s+opacity 1\.0\s+background-effect \{\s+blur false' "$wechat_rules" &&
  pass 'WeChat is opaque with blur disabled' || fail 'WeChat visual compatibility rule differs'
rg -Uq 'app-id=r"\^wechat\$"\s+open-floating false' "$wechat_rules" &&
  pass 'WeChat explicitly opens tiled' || fail 'WeChat tiled rule is missing'

rg -q "dms keybinds set niri Mod\\+Ctrl\\+N" "$repo_dir/install.sh" &&
  pass 'NyxNiri eye-care bind is delegated to DMS' ||
  fail 'NyxNiri eye-care bind is not delegated to DMS'

if rg -n 'noctalia|kitty|fish|mpvpaper' \
  "$repo_dir/niri/.config/niri/config.kdl" \
  "$repo_dir/niri/.config/niri/nyxniri/visuals.kdl" \
  "$repo_dir/niri/.config/niri/nyxniri/effects_normal.kdl" \
  "$repo_dir/niri/.config/niri/nyxniri/effects_eyecare.kdl" \
  "$repo_dir/niri/.config/niri/nyxniri/window-rules.kdl" 2>/dev/null; then
  fail 'NyxNiri integration replaces an existing desktop component'
else
  pass 'NyxNiri integration keeps DMS, Vicinae, WezTerm and Zsh'
fi

effects_link="$HOME/.config/niri/nyxniri/effects.kdl"
if [[ -L "$effects_link" ]]; then
  effects_target=$(readlink "$effects_link")
  case "$effects_target" in
    effects_normal.kdl|effects_eyecare.kdl)
      pass "NyxNiri runtime effect selects $effects_target"
      ;;
    *)
      fail "NyxNiri runtime effect has unexpected target: $effects_target"
      ;;
  esac
else
  fail 'NyxNiri runtime effect selector is not a symlink'
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
  rg -q 'Mod\+Ctrl\+N.*Toggle Eye-care Mode.*toggle-eyecare\.sh' "$generated_binds" &&
    pass 'Super+Ctrl+N toggles NyxNiri eye-care mode' ||
    fail 'NyxNiri eye-care keybind is missing'
else
  fail 'DMS-generated Niri keybinds are missing'
fi

rg -Fq 'ExecStart=/usr/bin/env vicinae server --replace' \
  "$repo_dir/systemd/.config/systemd/user/vicinae.service" &&
  pass 'Vicinae service resolves the installed binary through PATH' ||
  fail 'Vicinae service uses a stale installation path'
rg -Fq 'XDG_DATA_DIRS=%h/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:' \
  "$repo_dir/systemd/.config/systemd/user/vicinae.service" &&
  pass 'Vicinae indexes user and system Flatpak applications' ||
  fail 'Vicinae cannot discover Flatpak desktop exports'

dms_runtime="$HOME/.config/DankMaterialShell/settings.json"
[[ ! -L "$dms_runtime" ]] &&
  pass 'DMS runtime settings are not linked to the repository' ||
  fail 'DMS runtime settings pollute the repository'

[[ ! -L "$HOME/.config/fcitx5" ]] &&
  pass 'Fcitx5 runtime settings are not linked to the repository' ||
  fail 'Fcitx5 runtime settings pollute the repository'

[[ -f "$HOME/.config/noctalia/config.toml" && ! -L "$HOME/.config/noctalia/config.toml" ]] &&
  pass 'Noctalia runtime settings are not linked to the repository' ||
  fail 'Noctalia runtime settings pollute the repository'

for hook_name in theme-sync.sh wallpaper-hook.sh mpv-hook.lua; do
  [[ -L "$HOME/.config/noctalia/$hook_name" ]] &&
    pass "Noctalia hook $hook_name is managed by Stow" ||
    fail "Noctalia hook $hook_name is not managed by Stow"
done

[[ -f /usr/share/wayland-sessions/niri-nyxniri.desktop ]] &&
  pass 'NyxNiri login session is registered' ||
  fail 'NyxNiri login session is not registered'

[[ -x /usr/local/bin/niri-nyxniri-session ]] &&
  pass 'NyxNiri launcher is visible to the display manager' ||
  fail 'NyxNiri launcher is not visible to the display manager'

managed_links=(
  .Xresources
  .config/niri/config.kdl
  .config/niri/nyxniri/visuals.kdl
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

current_desktop=${XDG_SESSION_DESKTOP:-${DESKTOP_SESSION:-}}
if [[ "${current_desktop,,}" == nyxniri ]]; then
  if systemctl --user is-active --quiet dms.service; then
    fail 'dms.service is active inside NyxNiri'
  else
    pass 'dms.service is isolated from NyxNiri'
  fi

  if noctalia msg status 2>/dev/null | jq -e '.barVisible == true' >/dev/null; then
    pass 'Noctalia bar is active inside NyxNiri'
  else
    fail 'Noctalia bar is not active inside NyxNiri'
  fi

  if "$repo_dir/tests/test-noctalia-plugins.sh" --runtime >/dev/null 2>&1; then
    pass 'Noctalia wallpaper and lyrics plugins are loaded'
  else
    fail 'Noctalia wallpaper or lyrics plugin is not loaded'
  fi

  if niri msg -j layers 2>/dev/null |
    jq -e '[.[] | select(.namespace == "noctalia-bar-bar")] | length == 1' >/dev/null; then
    pass 'NyxNiri has exactly one Noctalia bar layer'
  else
    fail 'NyxNiri does not have exactly one Noctalia bar layer'
  fi

  if niri msg -j layers 2>/dev/null |
    jq -e '[.[] | select(.namespace | test("^(dms:|quickshell$)"))] | length == 0' >/dev/null; then
    pass 'NyxNiri has no DMS layer surfaces'
  else
    fail 'NyxNiri still has DMS layer surfaces'
  fi
else
  systemctl --user is-active --quiet dms.service &&
    pass 'dms.service is active' || fail 'dms.service is not active'
fi

systemctl --user is-active --quiet vicinae.service &&
  pass 'vicinae.service is active' || fail 'vicinae.service is not active'
waybar_state=$(systemctl --user is-enabled waybar.service 2>/dev/null || true)
case "$waybar_state" in
  masked|disabled|not-found|'') pass 'Waybar is inactive by configuration or absent' ;;
  *) fail "Waybar has an unexpected enablement state: $waybar_state" ;;
esac

for script in \
  install.sh \
  scripts/install-nyxniri-system.sh \
  scripts/install-nyxniri-deps.sh \
  scripts/prefetch-noctalia-plugins.sh \
  scripts/install-nyxniri-wallpapers.sh \
  session/.local/bin/niri-nyxniri-session \
  tests/verify-desktop.sh \
  tests/test-noctalia-plugins.sh \
  tests/test-toggle-eyecare.sh \
  tests/test-nyxniri-session.sh \
  tests/test-session-discoverable.sh \
  niri/.config/niri/nyxniri/toggle-eyecare.sh; do
  if [[ -f "$repo_dir/$script" ]]; then
    bash -n "$repo_dir/$script" && pass "$script syntax" || fail "$script syntax"
  fi
done

if "$repo_dir/tests/test-noctalia-plugins.sh" >/dev/null 2>&1; then
  pass 'Noctalia plugin prefetch and compatibility fallback'
else
  fail 'Noctalia plugin prefetch and compatibility fallback'
fi

if "$repo_dir/tests/test-toggle-eyecare.sh" >/dev/null; then
  pass 'NyxNiri eye-care state transitions for DMS and Noctalia'
else
  fail 'NyxNiri eye-care state transitions'
fi

if "$repo_dir/tests/test-nyxniri-session.sh" >/dev/null; then
  pass 'NyxNiri session isolation and cleanup'
else
  fail 'NyxNiri session isolation and cleanup'
fi

if "$repo_dir/tests/test-session-discoverable.sh" >/dev/null; then
  pass 'NyxNiri display-manager discovery'
else
  fail 'NyxNiri display-manager discovery'
fi

zsh -i -c exit >/dev/null 2>&1 &&
  pass 'interactive Zsh starts without configuration errors' ||
  fail 'interactive Zsh reports a configuration error'

if (( failures > 0 )); then
  printf '\n%d verification(s) failed.\n' "$failures" >&2
  exit 1
fi

printf '\nDesktop configuration is reproducible.\n'
