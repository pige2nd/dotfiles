#!/usr/bin/env bash
set -euo pipefail

config_file=${NOCTALIA_CONFIG_FILE:-"${XDG_CONFIG_HOME:-"$HOME/.config"}/noctalia/config.toml"}
enable_plugin_ipc=${NOCTALIA_ENABLE_PLUGIN_IPC:-true}

if [[ ! -f "$config_file" ]]; then
  printf '错误：未找到 Noctalia 配置：%s\n' "$config_file" >&2
  exit 1
fi

original_config_file=$config_file
working_config_file=$(mktemp "${config_file}.migrate.XXXXXX")
cleanup_working_config() {
  rm -f -- "$working_config_file"
}
trap cleanup_working_config EXIT
cp --preserve=mode -- "$original_config_file" "$working_config_file"
config_file=$working_config_file

replace_exact_line() {
  local old_line=$1
  local new_line=$2
  local temporary_file
  temporary_file=$(mktemp "${config_file}.tmp.XXXXXX")
  if ! awk -v old="$old_line" -v new="$new_line" \
      '{ print ($0 == old) ? new : $0 }' "$config_file" >"$temporary_file"; then
    rm -f -- "$temporary_file"
    return 1
  fi
  chmod --reference="$config_file" "$temporary_file"
  mv -- "$temporary_file" "$config_file"
}

insert_after_exact_line() {
  local anchor=$1
  local inserted_line=$2
  local temporary_file
  temporary_file=$(mktemp "${config_file}.tmp.XXXXXX")
  if ! awk -v anchor="$anchor" -v inserted="$inserted_line" \
      '{ print; if ($0 == anchor) { print inserted; found = 1 } }
       END { if (!found) exit 1 }' "$config_file" >"$temporary_file"; then
    rm -f -- "$temporary_file"
    return 1
  fi
  chmod --reference="$config_file" "$temporary_file"
  mv -- "$temporary_file" "$config_file"
}

replace_resource_layout() {
  local old_start=$1
  local new_start=$2
  local temporary_file
  temporary_file=$(mktemp "${config_file}.tmp.XXXXXX")
  if ! awk -v old_start="$old_start" -v new_start="$new_start" '
      $0 == old_start {
        print new_start
        start_found = 1
        next
      }
      $0 == "[widget.ram]" {
        print "[widget.resources-carousel]"
        print "type = \"xx/status-carousel:resources\""
        print "cycle_seconds = 4"
        print ""
        replacing = 1
        widget_found = 1
        next
      }
      replacing && $0 ~ /^\[/ {
        replacing = 0
      }
      replacing { next }
      { print }
      END { if (!start_found || !widget_found) exit 1 }
    ' "$config_file" >"$temporary_file"; then
    rm -f -- "$temporary_file"
    return 1
  fi
  chmod --reference="$config_file" "$temporary_file"
  mv -- "$temporary_file" "$config_file"
}

# Existing Noctalia configs are mutable runtime copies. Migrate only the exact
# previous NyxNiri layout and refuse unknown customizations.
new_resource_start='start = ["vicinae-launcher", "workspaces", "resources-carousel"]'
new_resource_start_with_active='start = ["vicinae-launcher", "workspaces", "active_window", "resources-carousel"]'
has_new_start=false
has_resource_widget=false
if rg -Fq "$new_resource_start" "$config_file" ||
    rg -Fq "$new_resource_start_with_active" "$config_file"; then
  has_new_start=true
fi
if rg -Fq '[widget.resources-carousel]' "$config_file"; then
  has_resource_widget=true
fi

if [[ "$has_new_start" != "$has_resource_widget" ]]; then
  printf '%s\n' '错误：Noctalia 资源轮播配置不完整，拒绝继续修改。' >&2
  exit 1
fi

if [[ "$has_new_start" == false ]]; then
  if ! rg -Fq '[widget.ram]' "$config_file"; then
    printf '%s\n' '错误：未找到可迁移的 Noctalia RAM 组件。' >&2
    exit 1
  fi

  if rg -Fq 'start = ["vicinae-launcher", "workspaces", "ram"]' "$config_file"; then
    replace_resource_layout \
      'start = ["vicinae-launcher", "workspaces", "ram"]' \
      "$new_resource_start"
  elif rg -Fq 'start = ["vicinae-launcher", "workspaces", "active_window", "ram"]' "$config_file"; then
    replace_resource_layout \
      'start = ["vicinae-launcher", "workspaces", "active_window", "ram"]' \
      "$new_resource_start_with_active"
  else
    printf '%s\n' '错误：Noctalia 左侧 Bar 已自定义，无法安全迁移资源轮播胶囊。' >&2
    exit 1
  fi
fi

old_status_end='end = ["lyrics", "tray", "wallpaper", "mpvpaper", "volume", "notifications", "session"]'
new_status_end='end = ["lyrics", "tray", "wallpaper", "mpvpaper", "status-carousel", "notifications", "session"]'
if ! rg -Fq "$new_status_end" "$config_file"; then
  if rg -Fq "$old_status_end" "$config_file"; then
    replace_exact_line "$old_status_end" "$new_status_end"
  else
    printf '%s\n' '错误：Noctalia Bar 已自定义，无法安全迁移状态轮播胶囊。' >&2
    exit 1
  fi
fi

old_plugins='enabled = ["noctalia/mpvpaper", "h465855hgg/lyrics"]'
new_plugins='enabled = ["noctalia/mpvpaper", "h465855hgg/lyrics", "xx/status-carousel"]'
if ! rg -Fq "$new_plugins" "$config_file"; then
  if rg -Fq "$old_plugins" "$config_file"; then
    replace_exact_line "$old_plugins" "$new_plugins"
  else
    printf '%s\n' '错误：Noctalia 插件列表已自定义，无法安全启用状态轮播插件。' >&2
    exit 1
  fi
fi

if ! rg -Fq '[widget.status-carousel]' "$config_file"; then
  sed -i '/^\[widget\.tray\]$/i\
[widget.status-carousel]\
type = "xx/status-carousel:status"\
cycle_seconds = 4\
adjust_step = 5\
\
' "$config_file"
fi

# Noctalia otherwise reserves middle-click for opening widget settings and does
# not deliver the plugin's onMiddleClick handler.
middle_click_setting='middle_click_opens_widget_settings = false'
if ! rg -Fxq "$middle_click_setting" "$config_file"; then
  if rg -Fxq 'middle_click_opens_widget_settings = true' "$config_file"; then
    replace_exact_line 'middle_click_opens_widget_settings = true' "$middle_click_setting"
  elif ! rg -q '^middle_click_opens_widget_settings[[:space:]]*=' "$config_file"; then
    insert_after_exact_line '[shell]' "$middle_click_setting"
  else
    printf '%s\n' '错误：Noctalia 中键设置已自定义，无法安全启用音量静音。' >&2
    exit 1
  fi
fi

# Settings-owned plugin state overrides config.toml. Let a running shell merge
# the local plugin through its supported IPC instead of rewriting settings.toml.
if [[ "$enable_plugin_ipc" == true ]] &&
    noctalia msg plugins source list >/dev/null 2>&1; then
  chmod --reference="$original_config_file" "$working_config_file"
  mv -- "$working_config_file" "$original_config_file"
  config_file=$original_config_file
  trap - EXIT
  noctalia msg plugins enable xx/status-carousel
  noctalia msg config-reload
else
  chmod --reference="$original_config_file" "$working_config_file"
  mv -- "$working_config_file" "$original_config_file"
  config_file=$original_config_file
  trap - EXIT
fi

printf '已配置 Noctalia 状态轮播胶囊：%s\n' "$config_file"
