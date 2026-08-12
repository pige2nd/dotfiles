#!/bin/zsh

# Starship prompt: 左侧目录/Git，右侧项目环境/耗时/时间。
(( $+commands[starship] )) || return 0

# 避免 zsh 为右侧填充额外空格，保证 $fill 对齐准确。
export ZLE_RPROMPT_INDENT=0
# 环境名统一交给 Starship，避免 conda activate 再修改左侧提示符。
export CONDA_CHANGEPS1=false
eval "$(starship init zsh)"

# 跳过新 shell 的首个提示符，之后每次显示提示符前插入空行。
# 因此执行命令和空回车都会分隔，但新终端顶部不会留白。
autoload -Uz add-zsh-hook
typeset -gi _xx_prompt_seen=0

_xx_prompt_separate_output() {
  if (( _xx_prompt_seen )); then
    print
  else
    _xx_prompt_seen=1
  fi
}

add-zsh-hook precmd _xx_prompt_separate_output
