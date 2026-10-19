#!/usr/bin/env bash
# One manual-protocol gate end to end on a tiny build workspace, with a stub run-case.sh standing in for
# the executor: gate.py record, the detached gate and its wait, check_gate.py, --panel and --finish. No
# claude, no network, no secrets. CI runs it on windows-latest, where gate.py runs run-case.sh through
# Git for Windows' bash and run_owned.py owns the gate through a Job Object.
#
#   PYTHON=python bash .github/scripts/gate-smoke.sh
set -euo pipefail

py="${PYTHON:-python3}"
scripts="$(cd "$(dirname "$0")/../../.agents/skills/create-skill-autoresearch/scripts" && pwd)"
ws="$(mktemp -d)"
trap 'rm -rf "$ws" || true' EXIT
native() { cygpath -w "$1" 2>/dev/null || printf '%s\n' "$1"; }
run() { "$py" -B "$(native "$scripts/$1")" --workspace "$(native "$ws")" "${@:2}"; }

mkdir -p "$ws/output/demo" "$ws/input" "$ws/work/evaluation"
printf -- '---\nname: demo\ndescription: Demo skill for the gate smoke test.\n---\n# Demo\n' > "$ws/output/demo/SKILL.md"
for n in 01 02 03; do printf 'case %s\n' "$n" > "$ws/input/input-$n.md"; done
printf 'all_cases:\n  - input/input-01.md\n  - input/input-02.md\n  - input/input-03.md\ntraining: []\n' \
  > "$ws/work/evaluation/data-split.yaml"
cat > "$ws/work/evaluation/run-case.sh" <<'EOF'
#!/bin/sh
# Stub executor: reads the case, scores the with-arm 0.9 and the bare arm 0.4.
test -f "$1" || { echo "no case file $1" >&2; exit 1; }
if [ "$2" = "with" ]; then echo "SCORE=0.9"; else echo "SCORE=0.4"; fi
EOF
chmod +x "$ws/work/evaluation/run-case.sh"

run gate.py record --backend manual
run gate.py --detach --backend manual --model stub-model --executor single-call --in-sample
for _ in $(seq 1 60); do
  rc=0
  run run_owned.py wait gate --timeout 10 || rc=$?
  [ "$rc" -ne 124 ] && break
done
[ "$rc" -eq 0 ] || { echo "gate exited $rc"; cat "$ws/work/pids/gate.log"; exit 1; }

line="$(run check_gate.py)"
echo "$line"
case "$line" in "GATE VALID: mode=manual "*"mean gold delta=+0.500"*) ;; *) echo "unexpected gate line"; exit 1 ;; esac
run check_gate.py --panel
printf '# Benchmark\n\nVerdict: SHIP WITH CAVEATS\n\n%s\n' "$line" > "$ws/BENCHMARK.md"
run check_gate.py --finish
