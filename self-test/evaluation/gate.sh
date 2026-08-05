#!/usr/bin/env bash
# Regression gate for the harness itself. Runs the deterministic structural checks and fails
# unless every check passes or fails only for a reason recorded below as advisory.
#
# Why a gate rather than a raw check count: new checks get added over time, so comparing
# `checks_passed` against a hardcoded number hides a regression behind a rising total. This
# compares the *issues* instead — a newly broken check fails the build even when the count goes up.
#
# Portability: sticks to POSIX-ish bash so it runs on the bash 3.2 that ships with macOS
# (no mapfile, no associative arrays). Needs bash and python3. No credentials, no network.
#
#   bash self-test/evaluation/gate.sh     # or: npm test
set -eu

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
cd "$REPO_ROOT"

# Advisory failures: known, accepted, non-blocking — an escape hatch for a check that has stopped
# defending anything. Set this to an extended-regex alternation matching the FAIL lines to tolerate,
# and write the reason above each alternative. Leave it empty to require a fully green run.
#
# Empty on purpose. The suite passes 100%, including the line-margin heuristic that used to fail, so
# tolerating anything would just let a regression back in unnoticed. Adding an entry here is a real
# decision: it retires a check. Prefer fixing the code.
ADVISORY_RE=''

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if ! bash "$HERE/autoresearch-evaluate.sh" >"$WORK/out.txt" 2>&1; then
  cat "$WORK/out.txt"
  echo "" >&2
  echo "GATE FAIL: the checker itself exited non-zero." >&2
  exit 1
fi
cat "$WORK/out.txt"

passed="$(sed -n 's/^METRIC checks_passed=\([0-9]*\).*/\1/p' "$WORK/out.txt" | tail -1)"
total="$(sed -n 's/^METRIC checks_total=\([0-9]*\).*/\1/p' "$WORK/out.txt" | tail -1)"

if [ -z "$passed" ] || [ -z "$total" ]; then
  echo "" >&2
  echo "GATE FAIL: could not read checks_passed/checks_total from the checker output." >&2
  exit 1
fi

grep -E '^FAIL: ' "$WORK/out.txt" >"$WORK/fails.txt" 2>/dev/null || : >"$WORK/fails.txt"

: >"$WORK/advisory.txt"
if [ -n "$ADVISORY_RE" ]; then
  # An empty pattern would match every line, so only split when there is something to tolerate.
  grep -E "$ADVISORY_RE" "$WORK/fails.txt" >"$WORK/advisory.txt" 2>/dev/null || : >"$WORK/advisory.txt"
  grep -vE "$ADVISORY_RE" "$WORK/fails.txt" >"$WORK/unexpected.txt" 2>/dev/null || : >"$WORK/unexpected.txt"
else
  cp "$WORK/fails.txt" "$WORK/unexpected.txt"
fi

advisory_count="$(wc -l <"$WORK/advisory.txt" | tr -d ' ')"
unexpected_count="$(wc -l <"$WORK/unexpected.txt" | tr -d ' ')"

echo ""
echo "--- Gate ---"
echo "checks: $passed/$total passed; advisory failures: $advisory_count; unexpected: $unexpected_count"

if [ "$unexpected_count" -gt 0 ]; then
  echo ""
  echo "GATE FAIL: a check regressed. These failures are not on the advisory list:" >&2
  sed 's/^/  /' "$WORK/unexpected.txt" >&2
  echo "" >&2
  echo "Fix the check, or — if the check itself is wrong — add it to ADVISORY_RE in this script" >&2
  echo "with a written reason. Never widen that pattern just to make the build green." >&2
  exit 1
fi

# Every failure is advisory, so passed + advisory should account for the whole suite. If it does
# not, a check failed without printing a FAIL line and the checker itself needs fixing.
if [ "$((passed + advisory_count))" -ne "$total" ]; then
  echo ""
  echo "GATE FAIL: $passed passed + $advisory_count advisory != $total total." >&2
  echo "A check failed without reporting an issue line; the checker is unreliable until that is fixed." >&2
  exit 1
fi

echo "GATE PASS"
