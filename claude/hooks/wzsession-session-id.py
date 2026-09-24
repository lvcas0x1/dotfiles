#!/usr/bin/env python3
"""Publish this pane's Claude Code session id for wzsession.

Claude Code runs this as a SessionStart hook. wzsession's capture.lua reads the
file we drop here and rewrites the pane's `claude` command line into
`claude --resume <id>`, so a restored tab reopens the same conversation instead
of an empty one.

The contract (see wzsession/capture.lua, pane_session_hint):

    <wzsession dir>/panes/<WEZTERM_PANE>.json
    {"pid": <pid of the claude process owning the pane>, "session_id": "<uuid>"}

The pid is what makes the hint trustworthy: capture.lua only believes the file
when that pid matches the pane's foreground process. A nested claude (say a
one-shot `claude -p` fired from inside a session) writes to the same pane file
but runs under a different pid, so it is ignored rather than clobbering the
real session id.

Failing is never worth blocking a session start over, so every error path
exits 0 quietly.
"""

import json
import os
import subprocess
import sys

STATE_DIR = os.environ.get("WZSESSION_DIR") or os.path.join(
    os.path.expanduser("~"), ".local", "share", "wezterm-session"
)
PANE_DIR = os.path.join(STATE_DIR, "panes")


def claude_pid() -> int | None:
    """pid of the claude process this hook belongs to.

    CLAUDE_PID is the direct answer. The fallback walks up from this process to
    the *nearest* claude ancestor -- nearest, not outermost, so a nested claude
    reports itself and stays distinguishable from the pane's own session.
    """
    env_pid = os.environ.get("CLAUDE_PID")
    if env_pid and env_pid.isdigit():
        return int(env_pid)

    pid = os.getppid()
    for _ in range(10):  # the hook sits a couple of levels below claude at most
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
        if os.path.basename(comm) == "claude":
            return pid
        pid = int(parent) if parent.isdigit() else 0
    return None


def alive(pid: int) -> bool:
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


def prune() -> None:
    """Drop hints whose claude is gone. Nothing else cleans this directory."""
    try:
        entries = os.listdir(PANE_DIR)
    except OSError:
        return
    for name in entries:
        if not name.endswith(".json"):
            continue
        path = os.path.join(PANE_DIR, name)
        try:
            with open(path) as fh:
                pid = int(json.load(fh).get("pid", 0))
        except (OSError, ValueError, TypeError, json.JSONDecodeError):
            continue
        if pid and not alive(pid):
            try:
                os.unlink(path)
            except OSError:
                pass


def main() -> int:
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

    pid = claude_pid()
    if not pid:
        return 0

    try:
        os.makedirs(PANE_DIR, exist_ok=True)
        path = os.path.join(PANE_DIR, f"{pane}.json")
        tmp = f"{path}.{os.getpid()}.tmp"
        # Atomic: capture.lua may read this file while wzsession saves a tab.
        with open(tmp, "w") as fh:
            json.dump({"pid": pid, "session_id": session_id}, fh)
        os.replace(tmp, path)
    except OSError:
        return 0

    prune()
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        sys.exit(0)
