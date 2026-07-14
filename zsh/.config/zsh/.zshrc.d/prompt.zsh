#!/bin/zsh

# Starship prompt: 左侧目录/Git，右侧项目环境/耗时/时间。
(( $+commands[starship] )) || return 0

# 避免 zsh 为右侧填充额外空格，保证 $fill 对齐准确。
export ZLE_RPROMPT_INDENT=0
eval "$(starship init zsh)"
