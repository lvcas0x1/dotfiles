#!/usr/bin/env python3
"""Publish this pane's agent session id for wzsession.

Claude Code and Codex both run this as a SessionStart hook; the agent whose
session is being published is named by argv[1]. wzsession's capture.lua reads
the file we drop here and rewrites the pane's command line into
`claude --resume <id>` or `codex resume <id>`, so a restored tab reopens the
same conversation instead of an empty one.

The contract (see wzsession/capture.lua, pane_session_hint):

    <wzsession dir>/panes/<WEZTERM_PANE>.json
    {"schema": 2,
     "sessions": [{"pid": 123, "agent": "claude", "session_id": "<uuid>"}, ...]}

The pid is what makes an entry trustworthy: capture.lua only believes the one
whose pid matches the pane's foreground process. Entries are kept per pid
rather than one per pane because agents nest -- a `codex` launched from inside
a Claude Code session, or a one-shot `claude -p`, publishes against the same
pane and must not erase the session the pane is actually showing.

Wiring: claude/settings.json (SessionStart) and codex/hooks.json (SessionStart).
Codex refuses to run a hook until it has been trusted once -- the first `codex`
after this file changes shows "Hooks need review"; answer "Trust all and
continue", or run `/hooks` in the TUI.

Failing is never worth blocking a session start over, so every error path
exits 0 quietly.
"""

import json
import os
import subprocess
import sys

AGENTS = ("claude", "codex")

STATE_DIR = os.environ.get("WZSESSION_DIR") or os.path.join(
    os.path.expanduser("~"), ".local", "share", "wezterm-session"
)
PANE_DIR = os.path.join(STATE_DIR, "panes")


def agent_pid(agent: str) -> int | None:
    """pid of the `agent` process this hook belongs to.

    Claude Code hands it over as CLAUDE_PID; Codex publishes no equivalent, and
    its env still carries the CLAUDE_PID of an outer Claude Code session, so the
    variable is only read for the agent that sets it. The fallback walks up from
    this process to the *nearest* matching ancestor -- nearest, not outermost,
    so a nested agent reports itself and stays distinguishable from the pane's
    own session.
    """
    if agent == "claude":
        env_pid = os.environ.get("CLAUDE_PID")
        if env_pid and env_pid.isdigit():
            return int(env_pid)

    pid = os.getppid()
    for _ in range(10):  # the hook sits a couple of levels below the agent
        if pid <= 1:
            break
        try:
            out = subprocess.run(
                ["ps", "-o", "ppid=,comm=", "-p", str(pid)],
                capture_output=True,
                text=True,
                timeout=2,
            ).stdout.split(None, 1)
        except (OSError, subprocess.SubprocessError):
            return None
        if len(out) != 2:
            return None
        parent, comm = out[0], out[1].strip()
        if os.path.basename(comm) == agent:
            return pid
        pid = int(parent) if parent.isdigit() else 0
    return None


def alive(pid: int) -> bool:
    if pid <= 0:
        return False
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


def entry_pid(entry: object) -> int:
    if not isinstance(entry, dict):
        return 0
    try:
        return int(entry.get("pid") or 0)
    except (TypeError, ValueError):
        return 0


def read_entries(path: str) -> list[dict]:
    """Live entries of one pane file, in either schema."""
    try:
        with open(path) as fh:
            data = json.load(fh)
    except (OSError, ValueError, json.JSONDecodeError):
        return []
    if not isinstance(data, dict):
        return []

    sessions = data.get("sessions")
    if not isinstance(sessions, list):
        # schema 1: one flat Claude Code entry per pane.
        if not data.get("session_id"):
            return []
        sessions = [
            {
                "pid": data.get("pid"),
                "agent": "claude",
                "session_id": data.get("session_id"),
            }
        ]

    return [e for e in sessions if entry_pid(e) and e.get("session_id")]


def write_entries(path: str, entries: list[dict]) -> None:
    tmp = f"{path}.{os.getpid()}.tmp"
    # Atomic: capture.lua may read this file while wzsession saves a tab.
    with open(tmp, "w") as fh:
        json.dump({"schema": 2, "sessions": entries}, fh)
    os.replace(tmp, path)


def prune() -> None:
    """Drop entries whose agent is gone. Nothing else cleans this directory."""
    try:
        names = os.listdir(PANE_DIR)
    except OSError:
        return
    for name in names:
        if not name.endswith(".json"):
            continue
        path = os.path.join(PANE_DIR, name)
        entries = read_entries(path)
        live = [e for e in entries if alive(entry_pid(e))]
        if len(live) == len(entries):
            continue
        try:
            if live:
                write_entries(path, live)
            else:
                os.unlink(path)
        except OSError:
            pass


def main() -> int:
    agent = sys.argv[1] if len(sys.argv) > 1 else ""
    if agent not in AGENTS:
        return 0

    pane = os.environ.get("WEZTERM_PANE")
    if not pane or not pane.isdigit():
        return 0  # not running under WezTerm; nothing to publish

    session_id = ""
    try:
        payload = json.load(sys.stdin)
        session_id = payload.get("session_id") or ""
    except (json.JSONDecodeError, ValueError, OSError):
        pass
    session_id = session_id or os.environ.get("CLAUDE_CODE_SESSION_ID") or ""
    if not session_id:
        return 0

    pid = agent_pid(agent)
    if not pid:
        return 0

    try:
        os.makedirs(PANE_DIR, exist_ok=True)
        path = os.path.join(PANE_DIR, f"{pane}.json")
        # Keep the other live agents of this pane; replace our own pid's entry.
        entries = [
            e
            for e in read_entries(path)
            if entry_pid(e) != pid and alive(entry_pid(e))
        ]
        entries.append({"pid": pid, "agent": agent, "session_id": session_id})
        write_entries(path, entries)
    except OSError:
        return 0

    prune()
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        sys.exit(0)
