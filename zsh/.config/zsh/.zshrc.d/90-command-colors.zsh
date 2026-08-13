# Keep command names brighter than regular ANSI green.
if (( $+parameters[FAST_HIGHLIGHT_STYLES] )); then
  FAST_HIGHLIGHT_STYLES[command]='fg=149'
  FAST_HIGHLIGHT_STYLES[alias]='fg=149'
  FAST_HIGHLIGHT_STYLES[builtin]='fg=149'
  FAST_HIGHLIGHT_STYLES[function]='fg=149'
  FAST_HIGHLIGHT_STYLES[hashed-command]='fg=149'
  FAST_HIGHLIGHT_STYLES[precommand]='fg=149'
fi
