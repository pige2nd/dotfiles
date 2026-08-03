#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
seed="$repo_dir/seeds/noctalia/config.toml.in"
prefetch="$repo_dir/scripts/prefetch-noctalia-plugins.sh"
migrate_status="$repo_dir/scripts/configure-noctalia-status-carousel.sh"
lyrics_patch="$repo_dir/patches/noctalia-lyrics-posix.patch"
require_runtime=false
if [[ ${1:-} == --runtime ]]; then
  require_runtime=true
elif [[ $# -gt 0 ]]; then
  printf 'usage: %s [--runtime]\n' "$0" >&2
  exit 2
fi

rg -Fq 'enabled = ["noctalia/mpvpaper", "h465855hgg/lyrics", "xx/status-carousel"]' "$seed"
rg -Fxq 'middle_click_opens_widget_settings = false' "$seed"
rg -Fq 'type = "noctalia/mpvpaper:mpvpaper"' "$seed"
rg -Fq 'type = "h465855hgg/lyrics:lyrics"' "$seed"
rg -Fq 'type = "fancy_audio_visualizer"' "$seed"
rg -Fq 'ui_scale = 1.2' "$seed"
rg -Fq 'telemetry_enabled = false' "$seed"

bash -n "$prefetch"
bash -n "$migrate_status"
rg -Fq 'git clone --filter=blob:none --no-checkout "$url" "$repo_dir"' "$prefetch"
rg -Fq 'NOCTALIA_MPV_PAPER_COMPAT_REV:-487c0288adf0d1e6f72ba96e9e2499596521249c' "$prefetch"
rg -Fq 'noctalia msg plugins update official' "$prefetch"
rg -Fq 'noctalia msg plugins update community' "$prefetch"
rg -Fq 'patch_lyrics_plugin' "$prefetch"
rg -Fq 'local fieldSeparator = string.char(31)' "$lyrics_patch"
rg -Fq 'transitionElapsed = transitionElapsed + delta * 1000' "$lyrics_patch"

test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT

run_status_migration() {
  NOCTALIA_CONFIG_FILE="$1" \
    NOCTALIA_ENABLE_PLUGIN_IPC=false \
    "$migrate_status" >/dev/null
}

legacy_resource_config="$test_root/legacy-resource.toml"
cp "$seed" "$legacy_resource_config"
sed -i \
  '/^start = .*"resources-carousel"\]$/c\start = ["vicinae-launcher", "workspaces", "ram"]' \
  "$legacy_resource_config"
sed -i '/^\[widget\.resources-carousel\]$/,/^$/c\
[widget.ram]\
type = "sysmon"\
stat = "ram_pct"\
display = "text"\
show_label = true\
label_min_width = 0\
' "$legacy_resource_config"
run_status_migration "$legacy_resource_config"
rg -Fq 'start = ["vicinae-launcher", "workspaces", "resources-carousel"]' \
  "$legacy_resource_config"
rg -Fq 'type = "xx/status-carousel:resources"' "$legacy_resource_config"
! rg -Fq '[widget.ram]' "$legacy_resource_config"

legacy_active_window_config="$test_root/legacy-active-window.toml"
cp "$legacy_resource_config" "$legacy_active_window_config"
sed -i \
  '/^start = .*"resources-carousel"\]$/c\start = ["vicinae-launcher", "workspaces", "active_window", "ram"]' \
  "$legacy_active_window_config"
sed -i '/^\[widget\.resources-carousel\]$/,/^$/c\
[widget.ram]\
type = "sysmon"\
stat = "ram_pct"\
' "$legacy_active_window_config"
run_status_migration "$legacy_active_window_config"
rg -Fq 'start = ["vicinae-launcher", "workspaces", "active_window", "resources-carousel"]' \
  "$legacy_active_window_config"

legacy_compact_toml="$test_root/legacy-compact.toml"
cp "$seed" "$legacy_compact_toml"
sed -i \
  '/^start = .*"resources-carousel"\]$/c\start = ["vicinae-launcher", "workspaces", "ram"]' \
  "$legacy_compact_toml"
sed -i '/^\[widget\.resources-carousel\]$/,/^$/c\
[widget.ram]\
type = "sysmon"\
stat = "ram_pct"' "$legacy_compact_toml"
run_status_migration "$legacy_compact_toml"
rg -Fq '[widget.resources-carousel]' "$legacy_compact_toml"
rg -Fq '[widget.status-carousel]' "$legacy_compact_toml"

partial_resource_config="$test_root/partial-resource.toml"
cp "$seed" "$partial_resource_config"
sed -i \
  '/^start = .*"resources-carousel"\]$/c\start = ["vicinae-launcher", "workspaces", "ram"]' \
  "$partial_resource_config"
partial_hash=$(sha256sum "$partial_resource_config")
if run_status_migration "$partial_resource_config" 2>/dev/null; then
  printf '%s\n' 'partially migrated resource layout was accepted' >&2
  exit 1
fi
test "$partial_hash" = "$(sha256sum "$partial_resource_config")"

late_failure_config="$test_root/late-failure.toml"
cp "$seed" "$late_failure_config"
sed -i \
  '/^start = .*"resources-carousel"\]$/c\start = ["vicinae-launcher", "workspaces", "ram"]' \
  "$late_failure_config"
sed -i '/^\[widget\.resources-carousel\]$/,/^$/c\
[widget.ram]\
type = "sysmon"\
stat = "ram_pct"\
' "$late_failure_config"
sed -i \
  's/^end = .*/end = ["custom-widget"]/' \
  "$late_failure_config"
late_failure_hash=$(sha256sum "$late_failure_config")
if run_status_migration "$late_failure_config" 2>/dev/null; then
  printf '%s\n' 'resource migration accepted a custom trailing bar layout' >&2
  exit 1
fi
test "$late_failure_hash" = "$(sha256sum "$late_failure_config")"

missing_setting_config="$test_root/missing-middle-click.toml"
cp "$seed" "$missing_setting_config"
sed -i '/^middle_click_opens_widget_settings = false$/d' "$missing_setting_config"
run_status_migration "$missing_setting_config"
rg -Fxq 'middle_click_opens_widget_settings = false' "$missing_setting_config"
test "$(rg -c '^middle_click_opens_widget_settings[[:space:]]*=' "$missing_setting_config")" -eq 1
missing_setting_hash=$(sha256sum "$missing_setting_config")
run_status_migration "$missing_setting_config"
test "$missing_setting_hash" = "$(sha256sum "$missing_setting_config")"

true_setting_config="$test_root/true-middle-click.toml"
cp "$seed" "$true_setting_config"
sed -i \
  's/^middle_click_opens_widget_settings = false$/middle_click_opens_widget_settings = true/' \
  "$true_setting_config"
run_status_migration "$true_setting_config"
rg -Fxq 'middle_click_opens_widget_settings = false' "$true_setting_config"
! rg -Fxq 'middle_click_opens_widget_settings = true' "$true_setting_config"

official_fixture="$test_root/official"
community_fixture="$test_root/community"
fake_bin="$test_root/bin"
mkdir -p "$official_fixture/mpvpaper" "$community_fixture/fixture" "$fake_bin"
printf '%s\n' \
  'id = "noctalia/mpvpaper"' \
  'name = "Video Wallpaper"' \
  'version = "1.0.6"' \
  'plugin_api = 3' >"$official_fixture/mpvpaper/plugin.toml"
printf '%s\n' 'fixture' >"$community_fixture/fixture/README"
for fixture in "$official_fixture" "$community_fixture"; do
  git -C "$fixture" init -q
  git -C "$fixture" add .
  git -C "$fixture" \
    -c user.name=NyxNiri \
    -c user.email=nyxniri@example.invalid \
    commit -qm fixture
done
compatible_rev=$(git -C "$official_fixture" rev-parse HEAD)
printf '%s\n' '#!/usr/bin/env bash' 'exit 1' >"$fake_bin/noctalia"
chmod +x "$fake_bin/noctalia"

run_prefetch_fixture() {
  PATH="$fake_bin:$PATH" \
    NOCTALIA_STATE_HOME="$test_root/state" \
    NOCTALIA_OFFICIAL_PLUGINS_URL="$official_fixture" \
    NOCTALIA_COMMUNITY_PLUGINS_URL="$community_fixture" \
    NOCTALIA_MPV_PAPER_COMPAT_REV="$compatible_rev" \
    NOCTALIA_MAX_PLUGIN_API=8 \
    "$prefetch" >/dev/null
}

run_prefetch_fixture
run_prefetch_fixture
printf '%s\n' \
  'id = "noctalia/mpvpaper"' \
  'name = "Video Wallpaper"' \
  'version = "1.0.7"' \
  'plugin_api = 9' \
  >"$test_root/state/noctalia/plugins/materialized/official/mpvpaper/plugin.toml"
run_prefetch_fixture
rg -Fq 'plugin_api = 3' \
  "$test_root/state/noctalia/plugins/materialized/official/mpvpaper/plugin.toml"
mv "$test_root/state/noctalia/plugins/sources/official/repo/.git" \
  "$test_root/state/noctalia/plugins/sources/official/repo/.git.interrupted"
run_prefetch_fixture
test -d "$test_root/state/noctalia/plugins/sources/official/repo/.git"
test -d "$test_root/state/noctalia/plugins/sources/community/repo/.git"
rg -Fq 'id = "noctalia/mpvpaper"' \
  "$test_root/state/noctalia/plugins/materialized/official/mpvpaper/plugin.toml"
if find "$test_root/state/noctalia/plugins/materialized" -name '.tmp-*' -print -quit | rg -q .; then
  printf '%s\n' 'temporary plugin exports were not cleaned up' >&2
  exit 1
fi

if noctalia msg plugins source list >/dev/null 2>&1; then
  plugins=$(noctalia msg plugins list)
  validation=$(noctalia config validate 2>&1)
  rg -q '^noctalia/mpvpaper .* enabled( |$)' <<<"$plugins"
  rg -q '^h465855hgg/lyrics .* enabled( |$)' <<<"$plugins"
  rg -q '^xx/status-carousel .* enabled( |$)' <<<"$plugins"
  if rg -q '^noctalia/mpvpaper .* incompatible( |$)' <<<"$plugins"; then
    # The catalog may advertise an API-newer update. The loaded compatible
    # export must still make the active config warning-free.
    rg -q '^noctalia/mpvpaper .* 1\.0\.6 enabled incompatible$' <<<"$plugins"
  fi
  ! rg -q '^(WARN|ERROR) ' <<<"$validation"
elif [[ "$require_runtime" == true ]]; then
  printf '%s\n' 'Noctalia is not running; runtime plugin verification is required.' >&2
  exit 1
fi

printf '%s\n' 'Noctalia plugin configuration checks passed.'
