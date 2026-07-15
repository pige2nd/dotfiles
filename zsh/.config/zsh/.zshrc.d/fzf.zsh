#!/bin/zsh

(( $+commands[fzf] )) || return 0

# fzf 的通用外观。
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border=rounded'

# Ctrl+T 的替代键是 Alt+T；预览文件时优先使用 bat。
export FZF_CTRL_T_OPTS="--walker=file,dir,follow,hidden --walker-skip=.git,node_modules,target --preview 'if [ -d {} ]; then eza --tree --level=2 --color=always -- {}; else bat --style=numbers --color=always --line-range=:300 -- {}; fi'"

# Alt+C：模糊选择目录并进入，预览目录树。
export FZF_ALT_C_OPTS="--walker=dir,follow,hidden --walker-skip=.git,node_modules,target --preview 'eza --tree --level=2 --color=always -- {}'"

# 官方 Zsh 集成：Ctrl+R / Ctrl+T / Alt+C。
source <(fzf --zsh)

# `fzf --zsh` binds Tab to its own `**` completion. Restore fzf-tab so that
# ordinary Zsh completion (commands, options, files, etc.) opens its fuzzy menu.
bindkey -M emacs '^I' fzf-tab-complete
bindkey -M viins '^I' fzf-tab-complete

# WezTerm 会优先拦截 Ctrl+R 和 Ctrl+T，因此提供 Alt+R / Alt+T。
bindkey -M emacs '\er' fzf-history-widget
bindkey -M vicmd '\er' fzf-history-widget
bindkey -M viins '\er' fzf-history-widget
bindkey -M emacs '\et' fzf-file-widget
bindkey -M vicmd '\et' fzf-file-widget
bindkey -M viins '\et' fzf-file-widget
