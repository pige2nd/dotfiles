#!/usr/bin/env sh
set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
revision="$(cat "$root/upstream-revision")"
checkout="$HOME/.local/share/agent-tracker-source"

if [ ! -d "$checkout/.git" ]; then
  git clone --filter=blob:none --no-checkout --sparse https://github.com/theniceboy/.config.git "$checkout"
fi
git -C "$checkout" sparse-checkout set agent-tracker
git -C "$checkout" fetch origin "$revision"
git -C "$checkout" checkout --detach "$revision"
cd "$checkout/agent-tracker"
"${GO_BIN:-go}" build -o bin/ ./cmd/tracker-server ./cmd/agent
printf 'Built tracker at %s\n' "$checkout/agent-tracker"
