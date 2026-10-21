#!/usr/bin/env python3
"""Shell-command hook: block pattern-based process kills, on every host whose hooks can block a command.

A name-pattern kill (`pkill -f gate`, `killall python3`, `pgrep -f x | xargs kill`, `kill $(pgrep x)`)
also hits sibling builds and the user's own
processes; the factory's run_owned.py stops only the job it recorded. One script, two input/output
contracts (references/hosts.md):

  Claude Code, Codex  PreToolUse, stdin {"tool_name": ..., "tool_input": {"command": ...}}.
                      Block: exit 2, reason on stderr. Allow: exit 0, no output.
  Cursor              beforeShellExecution, stdin {"hook_event_name": "beforeShellExecution",
                      "command": ..., "cwd": ..., "sandbox": ...}. Always answers JSON on stdout,
                      exit 0: {"permission": "deny", "user_message", "agent_message"} or
                      {"permission": "allow"} (Cursor blocks a permission hook that prints nothing).

hooks/kill-guard runs it with whichever Python 3 the machine has; OpenCode runs it through
hooks/opencode-kill-guard.js. Input it cannot read is let through, with {"permission": "allow"} on
stdout for Cursor's sake: the guard must never stop every shell call. A command that only mentions one
of these words (a grep for `pkill`) is blocked too, and so is one call that mentions a lister and a
`kill` beside any redirect, a heredoc body included: write such files with the editor tool or in a
separate call. The message says what to run instead.

It is a best-effort tripwire for honest mistakes, not a sandbox: it sees one tool call at a time, so a
listing written to a file in one call and killed from it in the next passes. run_owned.py and the rule
"stop only what you started, by its recorded PID" are the contract.

Quotes, backslashes and line continuations are removed first, so `p'k'ill`, `"pkill"` and `\\pkill` do not
hide a kill. `kill` counts only as a word of its own, never inside `kill-guard`/`kill_guard`. Blocked:
  pkill, killall                              anywhere as a word (any path: /usr/bin/pkill)
  fuser -k                                    kills whatever holds a file or port
  a process lister and a kill in one call     lister: pgrep, pidof, lsof, ps; kill: kill, xargs kill
The last rule is conservative: renames, copies and variables between the listing and the kill do not
matter. It allows one form only: every kill is a simple command (not piped into) whose targets are
literal PIDs, job specs or flags (`ps aux | head; kill 1234`, `ps -o pgid= -p 42; kill -TERM -- -42`), and
nothing in the call keeps a listing: no $( … ), backticks, <( … ), `>` (other than >&N or >/dev/null),
`tee` or `$x =`. So `ps aux > f; kill 4242` and
`ps aux | head; kill $PID` are blocked: run the kill in a call of its own.
"""

from __future__ import annotations

import json
import os
import re
import sys


if os.name == "nt":  # the host gets its "allow" answer, so no shell call or turn is held
    print("kill guard: native Windows is not supported; run the factory inside WSL", file=sys.stderr)
    print(json.dumps({"permission": "allow"}))
    sys.exit(0)

MESSAGE = ("Blocked by create-skill-autoresearch's kill guard. Use scripts/run_owned.py stop <name>; "
           "pattern kills hit unrelated processes. To stop one known process, kill its PID "
           "(kill <pid>) in a call that lists no processes.")
NAME_KILLS = [re.compile(r"\b(?:pkill|killall)\b"), re.compile(r"\bfuser\b.*\s-\w*k")]
LISTER = re.compile(r"\b(?:pgrep|pidof|lsof|ps)\b")
# `kill` as a command word: not `kill-guard` or `kill_guard` (this hook's own files).
KILLER = re.compile(r"(?<![\w-])kill(?![\w-])")
KEPT = re.compile(r"\$\(|[<>]\(|`|>(?!&\d|\s*/dev/null\b)|\btee\b|\$\w+\s*=")
WRAPPERS = re.compile(r"^(?:(?:sudo|command|builtin|exec)\s+)*")
KILL_WORD = re.compile(r"(?:\S*/)?kill")
LITERAL_ARG = re.compile(r"-?\d+(?:,\d+)*|%[\w%+-]*|--|-[A-Za-z]+\d*|[A-Z]+\d*")
CURSOR_EVENT = "beforeShellExecution"
ALLOW = {"permission": "allow"}


def normalise(command: str) -> str:
    """Quotes, line continuations and backslashes removed; line breaks kept (they separate commands). Bash
    deletes a backslash-newline pair outright, so `pki\\<newline>ll` is `pkill`: the halves are joined."""
    return re.sub(r"[\"'\\]", "", re.sub(r"\\\r?\n", "", command))


def simple_commands(text: str) -> list[str]:
    """Split on `;`, `&&`, `||`, `&` and line breaks outside $( … ), ( … ), { … } and ` … `; a pipeline
    stays one command, and a line break after `|` or inside a substitution continues it."""
    parts, buf, depth, tick = [], [], 0, False
    i = 0
    while i < len(text):
        ch, pair = text[i], text[i:i + 2]
        if ch == "`":
            tick = not tick
        elif ch in "({":
            depth += 1
        elif ch in ")}":
            depth = max(0, depth - 1)
        elif depth == 0 and not tick:
            prev, nxt = text[i - 1:i], text[i + 1:i + 2]
            if pair in ("&&", "||"):
                parts.append("".join(buf))
                buf, i = [], i + 2
                continue
            if ch == ";" or (ch == "&" and prev not in "<>" and nxt != ">"):
                parts.append("".join(buf))
                buf, i = [], i + 1
                continue
            if ch in "\r\n":
                if "".join(buf).rstrip().endswith("|"):
                    ch = " "
                else:
                    parts.append("".join(buf))
                    buf, i = [], i + 1
                    continue
        buf.append(" " if ch in "\r\n" else ch)
        i += 1
    parts.append("".join(buf))
    return [p.strip() for p in parts if p.strip()]


def _literal_kill(segment: str) -> bool:
    words = WRAPPERS.sub("", segment.strip()).split()
    return bool(words) and bool(KILL_WORD.fullmatch(words[0])) and all(LITERAL_ARG.fullmatch(w) for w in words[1:])


def _listing_and_kill(text: str) -> bool:
    if not (LISTER.search(text) and KILLER.search(text)):
        return False
    if KEPT.search(text):
        return True
    return any(KILLER.search(segment) and (i > 0 or not _literal_kill(segment))
               for command in simple_commands(text) for i, segment in enumerate(command.split("|")))


def is_pattern_kill(command: str) -> bool:
    text = normalise(command)
    return any(p.search(c) for c in simple_commands(text) for p in NAME_KILLS) or _listing_and_kill(text)


def main() -> int:
    try:
        event = json.load(sys.stdin)
    except (json.JSONDecodeError, UnicodeDecodeError):
        event = None
    if not isinstance(event, dict):
        print(json.dumps(ALLOW))
        return 0
    if event.get("hook_event_name") == CURSOR_EVENT or ("command" in event and "tool_input" not in event):
        command = event.get("command")
        blocked = isinstance(command, str) and is_pattern_kill(command)
        reply = {"permission": "deny", "user_message": MESSAGE, "agent_message": MESSAGE} if blocked else ALLOW
        print(json.dumps(reply))
        return 0
    command = (event.get("tool_input") or {}).get("command")
    if isinstance(command, str) and is_pattern_kill(command):
        print(MESSAGE, file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
