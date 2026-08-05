#!/usr/bin/env bash
# Verifies the factory in this repo still matches the copy published to a skills registry.
#
# The harness is the source of truth for `create-skill-autoresearch`; the registry carries a
# byte-identical published copy. Nothing used to check that, which is how the vendored
# production-grade copy sat three versions behind without anyone noticing. This is that check.
#
# Runs in CI and locally:
#   bash .github/scripts/check-parity.sh <harness-dir> <published-dir>
#   bash .github/scripts/check-parity.sh . ../agent-skills
#
# Exit 0 = identical (or the published copy is absent, which is not this repo's fault).
# Exit 1 = diverged.
set -eu

HARNESS="${1:-.}"
PUBLISHED="${2:-../agent-skills}"

SRC="$HARNESS/.agents/skills/create-skill-autoresearch"
PUB="$PUBLISHED/skills/create-skill-autoresearch"

if [ ! -d "$SRC" ]; then
  echo "check-parity: no factory at $SRC" >&2
  exit 1
fi

if [ ! -d "$PUB" ]; then
  echo "check-parity: no published copy at $PUB — skipping the diff."
  exit 0
fi

status=0

if diff -rq "$SRC" "$PUB"; then
  echo "check-parity: factory is byte-identical to the published copy."
else
  status=1
  cat >&2 <<'EOF'

check-parity: the factory and its published copy have DIVERGED.

The harness is the source of truth. Re-sync the whole directory — never edit the published copy in
place, or a stale references/ file survives — then confirm the diff is empty:

  rm -rf <published>/skills/create-skill-autoresearch
  cp -r .agents/skills/create-skill-autoresearch <published>/skills/create-skill-autoresearch
  diff -rq .agents/skills/create-skill-autoresearch <published>/skills/create-skill-autoresearch

If a change to the factory has not been published yet, this divergence is expected and clears with the
release. Say so in the pull request description.
EOF
fi

# A version bump that never reaches the registry entry installs a stale description over current
# files. These are independent fields; nothing syncs them.
src_version="$(sed -n 's/^version:[[:space:]]*//p' "$SRC/SKILL.md" | head -1)"
echo "check-parity: factory frontmatter version = ${src_version:-<none>}"

manifest="$PUBLISHED/.claude-plugin/marketplace.json"
if [ -f "$manifest" ]; then
  entry_version="$(
    python3 - "$manifest" <<'PY'
import json, sys
with open(sys.argv[1]) as fh:
    data = json.load(fh)
for plugin in data.get("plugins", []):
    if plugin.get("name") == "create-skill-autoresearch":
        print(plugin.get("version", ""))
        break
PY
  )"
  echo "check-parity: marketplace entry version  = ${entry_version:-<none>}"
  if [ -n "$entry_version" ] && [ "$src_version" != "$entry_version" ]; then
    echo "check-parity: WARNING version mismatch — bump the marketplace entry to $src_version when publishing." >&2
  fi
else
  echo "check-parity: no marketplace manifest at $manifest; nothing to compare."
fi

exit "$status"
