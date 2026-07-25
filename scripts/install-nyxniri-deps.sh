#!/usr/bin/env bash
set -euo pipefail

keyring=/tmp/nickh-archive-keyring.deb
source_url=https://pkg.noctalia.dev/deb/noctalia-resolute.sources

wget -O "$keyring" https://pkg.noctalia.dev/deb/nickh-archive-keyring.deb
sudo dpkg -i "$keyring"
sudo wget -O /etc/apt/sources.list.d/noctalia-resolute.sources "$source_url"
sudo apt update
sudo apt install -y \
  noctalia mpv libmpv-dev libwlroots-dev inotify-tools playerctl \
  meson ninja-build pkg-config wayland-protocols

build_dir=$(mktemp -d)
trap 'rm -rf "$build_dir"' EXIT
git clone --depth 1 https://github.com/GhostNaN/mpvpaper.git "$build_dir/mpvpaper"
meson setup "$build_dir/mpvpaper/build" "$build_dir/mpvpaper" --prefix="$HOME/.local"
ninja -C "$build_dir/mpvpaper/build"
ninja -C "$build_dir/mpvpaper/build" install

printf '%s\n' 'Noctalia V5 与 mpvpaper 已安装。'
