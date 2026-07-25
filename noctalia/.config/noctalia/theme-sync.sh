#!/usr/bin/env bash
set -euo pipefail

theme_mode=${NOCTALIA_THEME_MODE:-}
if [[ -z "$theme_mode" ]]; then
  theme_mode=$(noctalia msg theme-mode-get 2>/dev/null || printf '%s' dark)
fi

if [[ "$theme_mode" == light ]]; then
  color_scheme=prefer-light
  gtk_dark=false
else
  color_scheme=prefer-dark
  gtk_dark=true
fi

if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.interface color-scheme "$color_scheme" 2>/dev/null || true
fi

for gtk_dir in gtk-3.0 gtk-4.0; do
  settings="$HOME/.config/$gtk_dir/settings.ini"
  mkdir -p "$(dirname -- "$settings")"
  [[ -f "$settings" ]] || printf '[Settings]\n' >"$settings"
  if grep -q '^gtk-application-prefer-dark-theme=' "$settings"; then
    sed -i "s/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=$gtk_dark/" "$settings"
  else
    sed -i "/^\\[Settings\\]/a gtk-application-prefer-dark-theme=$gtk_dark" "$settings"
  fi
done
