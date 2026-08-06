#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
seed="$repo_dir/seeds/noctalia/config.toml.in"
plugin_dir="$repo_dir/noctalia/.local/share/noctalia/plugins/status-carousel"
helper="$plugin_dir/status-carousel"
wezterm_config="$repo_dir/wezterm/.config/wezterm/wezterm.lua"
wezterm_mappings="$repo_dir/wezterm/.config/wezterm/mappings.lua"
tab_config="$repo_dir/wezterm/.config/wezterm/tab.lua"
tab_title_test="$repo_dir/tests/wezterm-tab-title.lua"
wezterm_test_bin="${WEZTERM_TEST_BIN:-wezterm}"
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT
proc_fixture="$test_root/proc"
mkdir -p "$proc_fixture"

rg -q '^start = \["vicinae-launcher", "workspaces"(, "active_window")?, "resources-carousel"\]$' "$seed"
rg -Fq '[widget.resources-carousel]' "$seed"
rg -Fq 'type = "xx/status-carousel:resources"' "$seed"
! rg -Fq '[widget.ram]' "$seed"

rg -Fq 'id = "resources"' "$plugin_dir/plugin.toml"
rg -Fq 'entry = "resources.luau"' "$plugin_dir/plugin.toml"
test -f "$plugin_dir/resources.luau"

printf '%s\n' \
  'MemTotal:       1000 kB' \
  'MemAvailable:    250 kB' >"$proc_fixture/meminfo"
printf '%s\n' 'cpu 100 0 100 800 0 0 0 0 1000 500' >"$proc_fixture/stat.before"
printf '%s\n' 'cpu 150 0 150 900 0 0 0 0 2000 1000' >"$proc_fixture/stat.after"

ram_status=$(NYXNIRI_PROC_ROOT="$proc_fixture" "$helper" read ram)
cpu_status=$(
  NYXNIRI_PROC_ROOT="$proc_fixture" \
    NYXNIRI_CPU_STAT_BEFORE="$proc_fixture/stat.before" \
    NYXNIRI_CPU_STAT_AFTER="$proc_fixture/stat.after" \
    NYXNIRI_CPU_SAMPLE_SECONDS=0 \
    "$helper" read cpu
)
[[ "$ram_status" == 'ram|75|active' ]]
[[ "$cpu_status" == 'cpu|50|active' ]]

printf '%s\n' 'MemTotal:       1000 kB' >"$proc_fixture/meminfo"
if NYXNIRI_PROC_ROOT="$proc_fixture" "$helper" read ram >/dev/null 2>&1; then
  printf '%s\n' 'RAM reader accepted a fixture without MemAvailable' >&2
  exit 1
fi
printf '%s\n' 'intr 123' >"$proc_fixture/stat.before"
if NYXNIRI_PROC_ROOT="$proc_fixture" \
    NYXNIRI_CPU_STAT_BEFORE="$proc_fixture/stat.before" \
    NYXNIRI_CPU_STAT_AFTER="$proc_fixture/stat.after" \
    NYXNIRI_CPU_SAMPLE_SECONDS=0 \
    "$helper" read cpu >/dev/null 2>&1; then
  printf '%s\n' 'CPU reader accepted a fixture without an aggregate CPU row' >&2
  exit 1
fi
cp "$proc_fixture/stat.after" "$proc_fixture/stat.before"
if NYXNIRI_PROC_ROOT="$proc_fixture" \
    NYXNIRI_CPU_STAT_BEFORE="$proc_fixture/stat.before" \
    NYXNIRI_CPU_STAT_AFTER="$proc_fixture/stat.after" \
    NYXNIRI_CPU_SAMPLE_SECONDS=0 \
    "$helper" read cpu >/dev/null 2>&1; then
  printf '%s\n' 'CPU reader accepted snapshots with no elapsed CPU time' >&2
  exit 1
fi

rg -Fq "'https://github.com/yriveiro/wezterm-tabs'" "$tab_config"
rg -Fq "local tab_title = require 'tab-title'" "$tab_config"
rg -Fq 'local original_on = wezterm.on' "$tab_config"
rg -Fq 'tabs.apply_to_config(config, {' "$tab_config"
rg -Fq 'wezterm.color.get_builtin_schemes()[config.color_scheme]' "$tab_config"
rg -Fq 'config.color_schemes[config.color_scheme] = scheme' "$tab_config"
rg -Fq 'tab_bar_at_bottom = false' "$tab_config"
rg -Fq 'hide_tab_bar_if_only_one_tab = false' "$tab_config"
rg -Fq 'tab_max_width = 24' "$tab_config"
rg -Uq 'zoom_indicator = \{\n[[:space:]]+enabled = false' "$tab_config"
rg -Fq 'config.show_new_tab_button_in_tab_bar = true' "$tab_config"
rg -Fq "config.window_decorations = 'TITLE | RESIZE'" "$tab_config"
! rg -q 'update-status|status_update_interval' "$tab_config"

rg -Fq "local primary_font = 'SF Mono'" "$wezterm_config"
rg -Fq "is_windows and 'Microsoft YaHei UI' or 'Noto Sans Mono CJK SC'" "$wezterm_config"
rg -Fq "local symbol_font = 'Symbols Nerd Font Mono'" "$wezterm_config"
rg -Fq "local emoji_font = 'Noto Color Emoji'" "$wezterm_config"
rg -Fq "config.default_prog = { 'cmd.exe' }" "$wezterm_config"
rg -Fq "label = 'CMD'" "$wezterm_config"
rg -Fq "label = 'PowerShell'" "$wezterm_config"
rg -Fq "args = { 'powershell.exe', '-NoLogo' }" "$wezterm_config"
rg -Fq "DomainName = 'WSL:Ubuntu'" "$wezterm_config"
rg -Fq "domain.default_cwd = '~'" "$wezterm_config"
rg -Fq "config.window_close_confirmation = 'NeverPrompt'" "$wezterm_config"
rg -Fq "config.skip_close_confirmation_for_processes_named = {}" "$wezterm_config"
rg -Fq "CloseCurrentTab { confirm = true }" "$wezterm_mappings"
rg -Fq "CloseCurrentPane { confirm = true }" "$wezterm_mappings"
rg -Fq "flags = 'LAUNCH_MENU_ITEMS'" "$wezterm_mappings"
rg -Fq "flags = 'FUZZY|LAUNCH_MENU_ITEMS|DOMAINS'" "$wezterm_mappings"

NYXNIRI_REPO_DIR="$repo_dir" \
  "$wezterm_test_bin" --config-file "$tab_title_test" show-keys >/dev/null

printf '%s\n' 'Static wezterm-tabs and rotating Noctalia resource bars are configured.'
