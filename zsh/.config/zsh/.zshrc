#!/bin/zsh

# .zshrc - interactive Zsh configuration based on getantidote/zdotdir.

# Lazy-load Zsh functions managed by this dotfiles package.
ZFUNCDIR=${ZDOTDIR:-$HOME}/.zfunctions
fpath=($ZFUNCDIR $fpath)
autoload -Uz $ZFUNCDIR/*(.:t)

# User style settings.
[[ ! -f ${ZDOTDIR:-$HOME}/.zstyles ]] || source "${ZDOTDIR:-$HOME}/.zstyles"

# Keep Antidote itself and generated plugin code outside the Stow-managed tree.
ANTIDOTE_HOME=${ANTIDOTE_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/antidote}
if [[ ! -r "$ANTIDOTE_HOME/antidote.zsh" ]]; then
  command git clone --depth=1 https://github.com/mattmc3/antidote.git "$ANTIDOTE_HOME"
fi
source "$ANTIDOTE_HOME/antidote.zsh"

# Generate the static bundle only when the declarative plugin list changes.
ZSH_PLUGIN_CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/zsh
ZSH_PLUGIN_BUNDLE=$ZSH_PLUGIN_CACHE/.zsh_plugins.zsh
ZSH_PLUGIN_LIST=${ZDOTDIR:-$HOME}/.zsh_plugins.txt
if [[ ! -r "$ZSH_PLUGIN_BUNDLE" || "$ZSH_PLUGIN_LIST" -nt "$ZSH_PLUGIN_BUNDLE" ]]; then
  mkdir -p "$ZSH_PLUGIN_CACHE"
  antidote bundle < "$ZSH_PLUGIN_LIST" >| "$ZSH_PLUGIN_BUNDLE"
fi
source "$ZSH_PLUGIN_BUNDLE"

# Source modular configuration files.
for _rc in ${ZDOTDIR:-$HOME}/.zshrc.d/*.zsh; do
  [[ $_rc:t == '~'* ]] || source "$_rc"
done
unset _rc
