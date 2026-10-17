#!/usr/bin/env bash
# Offline test of .github/scripts/check-parity.sh on temp copies: identical copies with matching
# versions pass; a version mismatch and a diverged file each fail. Run by gate.sh.
#
#   bash self-test/evaluation/test-check-parity.sh
set -eu

HERE="$(cd "$(dirname "$0")" && pwd)"
PARITY="$(cd "$HERE/../.." && pwd)/.github/scripts/check-parity.sh"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/parity-test.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

failures=0
expect() { # expect <name> <wanted exit code> <harness> <published>
  set +e
  bash "$PARITY" "$3" "$4" >"$WORK/out.txt" 2>&1
  got=$?
  set -e
  if [ "$got" -ne "$2" ]; then
    echo "FAIL: $1: exit $got, wanted $2" >&2
    cat "$WORK/out.txt" >&2
    failures=$((failures + 1))
  else
    echo "ok: $1"
  fi
}

make_pair() { # make_pair <dir> <frontmatter version> <marketplace version>
  mkdir -p "$1/harness/.agents/skills/create-skill-autoresearch" "$1/published/skills" "$1/published/.claude-plugin"
  printf -- '---\nname: create-skill-autoresearch\nversion: %s\n---\n# body\n' "$2" \
    >"$1/harness/.agents/skills/create-skill-autoresearch/SKILL.md"
  cp -r "$1/harness/.agents/skills/create-skill-autoresearch" "$1/published/skills/"
  printf '{"plugins": [{"name": "create-skill-autoresearch", "version": "%s"}]}\n' "$3" \
    >"$1/published/.claude-plugin/marketplace.json"
}

make_pair "$WORK/same" 1.2.0 1.2.0
expect "identical copies, matching versions" 0 "$WORK/same/harness" "$WORK/same/published"

make_pair "$WORK/version" 1.2.0 1.1.0
expect "marketplace version differs from frontmatter" 1 "$WORK/version/harness" "$WORK/version/published"
grep -q "version MISMATCH" "$WORK/out.txt" || { echo "FAIL: mismatch not reported" >&2; failures=$((failures + 1)); }

make_pair "$WORK/diverged" 1.2.0 1.2.0
echo "edited" >>"$WORK/diverged/published/skills/create-skill-autoresearch/SKILL.md"
expect "diverged published copy" 1 "$WORK/diverged/harness" "$WORK/diverged/published"

if [ "$failures" -ne 0 ]; then
  echo "check-parity tests: $failures failed" >&2
  exit 1
fi
echo "check-parity tests: 3 passed"
