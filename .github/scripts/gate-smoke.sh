#!/usr/bin/env bash
# One manual-protocol gate end to end on a tiny build workspace, with a stub run-case.sh standing in for
# the executor, then a stub panel: gate.py record, the detached gate and its --wait, a re-gate that reuses the
# cached without arm, check_gate.py, --panel,
# three --panel-receipt calls, --consensus, --finish, and the finish guard before and after. No claude, no
# network, no secrets. CI runs it on windows-latest, where gate.py runs run-case.sh through Git for
# Windows' bash and run_owned.py owns the gate through a Job Object.
#
#   PYTHON=python bash .github/scripts/gate-smoke.sh
set -euo pipefail
# The smoke plays another host: inside Claude Code, gate.py refuses --backend manual for a model-invoked skill.
unset CLAUDECODE

py="${PYTHON:-python3}"
skill="$(cd "$(dirname "$0")/../../.agents/skills/create-skill-autoresearch" && pwd)"
scripts="$skill/scripts"
ws="$(mktemp -d)"
trap 'rm -rf "$ws" || true' EXIT
native() { cygpath -w "$1" 2>/dev/null || printf '%s\n' "$1"; }
run() { "$py" -B "$(native "$scripts/$1")" --workspace "$(native "$ws")" "${@:2}"; }
guard() { printf '{"hook_event_name": "Stop", "stop_hook_active": false, "cwd": %s}' \
  "$("$py" -c 'import json, sys; print(json.dumps(sys.argv[1]))' "$(native "$ws")")" \
  | "$py" -B "$(native "$skill/hooks/finish_guard.py")"; }

mkdir -p "$ws/output/demo" "$ws/input" "$ws/work/evaluation"
printf -- '---\nname: demo\ndescription: Demo skill for the gate smoke test.\n---\n# Demo\n' > "$ws/output/demo/SKILL.md"
for n in 01 02 03; do printf 'case %s\n' "$n" > "$ws/input/input-$n.md"; done
printf 'all_cases:\n  - input/input-01.md\n  - input/input-02.md\n  - input/input-03.md\ntraining: []\n' \
  > "$ws/work/evaluation/data-split.yaml"
printf 'dimensions:\n  - name: correctness\n    weight: 0.6\n  - name: clarity\n    weight: 0.4\ntarget_score: 0.85\n' \
  > "$ws/work/evaluation/rubric.yaml"
cat > "$ws/work/evaluation/run-case.sh" <<'EOF'
#!/bin/sh
# Stub executor: reads the case, scores the with-arm 0.9 and the bare arm 0.4.
test -f "$1" || { echo "no case file $1" >&2; exit 1; }
echo "EXECUTOR=$GATE_EXECUTOR"
if [ "$2" = "with" ]; then echo "SCORE=0.9"; else echo "SCORE=0.4"; fi
EOF
chmod +x "$ws/work/evaluation/run-case.sh"

case "$(guard)" in *'"decision": "block"'*"BUILD UNFINISHED"*) ;; *) echo "finish guard did not send the build back"; exit 1 ;; esac

run gate.py record --backend manual
run gate.py --detach --backend manual --model stub-model --executor single-call --in-sample
for _ in $(seq 1 60); do
  rc=0
  run gate.py --wait --wait-timeout 10 || rc=$?
  [ "$rc" -ne 124 ] && break
done
[ "$rc" -eq 0 ] || { echo "gate exited $rc"; cat "$ws/work/pids/gate.log"; exit 1; }
out="$(run gate.py --detach --wait --backend manual --model stub-model --executor single-call --in-sample)" \
  || { echo "re-gate failed"; cat "$ws/work/pids/gate.log"; exit 1; }
case "$out" in *"reusing the cached without-skill arm for 3 of 3 cases"*) ;;
  *) echo "the re-gate did not reuse the cached without arm"; echo "$out"; exit 1 ;; esac

line="$(run check_gate.py)"
echo "$line"
case "$line" in "GATE VALID: mode=manual "*"mean gold delta=+0.500"*) ;; *) echo "unexpected gate line"; exit 1 ;; esac
run check_gate.py --panel

mkdir -p "$ws/work/experiments/panel"
for role in verifier-a verifier-b devils-advocate; do
  scores="$ws/work/experiments/panel/$role.scores.json"
  printf '{"scores": {"correctness": {"score": 8, "confidence": 0.9, "evidence": "Demo"}, "clarity": {"score": 8, "confidence": 0.9, "evidence": "Demo"}}, "pass_recommendation": "SHIP_WITH_CAVEATS", "escalation": null}\n' > "$scores"
  run check_gate.py --panel-receipt "$role" "$(native "$scores")"
done
consensus="$(run check_gate.py --consensus)"
echo "$consensus"
case "$consensus" in "PANEL CONSENSUS: SHIP WITH CAVEATS (allows SHIP WITH CAVEATS); overall=0.800"*) ;;
  *) echo "unexpected consensus line"; exit 1 ;; esac

printf '# Benchmark\n\nVerdict: SHIP\n\n%s\n%s\n' "$line" "$consensus" > "$ws/BENCHMARK.md"
if run check_gate.py --finish; then echo "--finish accepted a verdict above the consensus"; exit 1; fi
printf '# Benchmark\n\nVerdict: SHIP WITH CAVEATS\n\n%s\n%s\n' "$line" "$consensus" > "$ws/BENCHMARK.md"
run check_gate.py --finish
[ "$(guard)" = "{}" ] || { echo "finish guard held a finished build"; exit 1; }
