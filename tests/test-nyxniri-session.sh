#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
wrapper="$repo_dir/session/.local/bin/niri-nyxniri-session"
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT

mock_bin="$fixture/bin"
mock_log="$fixture/session.log"
test_home="$fixture/home"
mkdir -p "$mock_bin" "$test_home/.config/niri/nyxniri" "$test_home/.local/state/niri"
touch "$test_home/.config/niri/nyxniri/effects_normal.kdl"
ln -s effects_eyecare.kdl "$test_home/.config/niri/nyxniri/effects.kdl"
printf '%s\n' disabled >"$test_home/.local/state/niri/nyxniri-eyecare"

cat >"$mock_bin/systemctl" <<'EOF'
#!/usr/bin/env bash
printf 'systemctl %s\n' "$*" >>"$MOCK_LOG"
if [[ "$*" == '--user mask --runtime --now dms.service' && "${MOCK_MASK_FAIL:-0}" == 1 ]]; then
  exit 1
fi
EOF
cat >"$mock_bin/dms" <<'EOF'
#!/usr/bin/env bash
printf 'dms %s\n' "$*" >>"$MOCK_LOG"
EOF
cat >"$mock_bin/noctalia" <<'EOF'
#!/usr/bin/env bash
printf 'noctalia %s\n' "$*" >>"$MOCK_LOG"
EOF
cat >"$mock_bin/niri-session" <<'EOF'
#!/usr/bin/env bash
printf 'niri-session NIRI_CONFIG=%s DESKTOP_SESSION=%s\n' \
  "$NIRI_CONFIG" "$DESKTOP_SESSION" >>"$MOCK_LOG"
exit 7
EOF
chmod +x "$mock_bin"/*

export HOME="$test_home"
export PATH="$mock_bin:$PATH"
export MOCK_LOG="$mock_log"

set +e
"$wrapper"
wrapper_status=$?
set -e
[[ "$wrapper_status" == 7 ]]
grep -Fxq 'dms ipc call night disable' "$mock_log"
grep -Fxq 'systemctl --user mask --runtime --now dms.service' "$mock_log"
grep -Fq "niri-session NIRI_CONFIG=$test_home/.config/niri-nyxniri/config.kdl DESKTOP_SESSION=NyxNiri" "$mock_log"
grep -Fxq 'systemctl --user unset-environment NIRI_CONFIG XDG_SESSION_DESKTOP DESKTOP_SESSION' "$mock_log"
grep -Fxq 'systemctl --user unmask --runtime dms.service' "$mock_log"
[[ $(tail -n 1 "$mock_log") == 'systemctl --user start dms.service' ]]
[[ $(readlink "$test_home/.config/niri/nyxniri/effects.kdl") == effects_normal.kdl ]]
[[ ! -e "$test_home/.local/state/niri/nyxniri-eyecare" ]]

: >"$mock_log"
MOCK_MASK_FAIL=1 "$wrapper" >/dev/null 2>&1 && exit 1
if grep -q '^niri-session ' "$mock_log"; then
  printf '%s\n' 'NyxNiri started even though DMS could not be stopped.' >&2
  exit 1
fi

printf '%s\n' 'NyxNiri isolates DMS, cleans its environment, and restores fallback state.'
