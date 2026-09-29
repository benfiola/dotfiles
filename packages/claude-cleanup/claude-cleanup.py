"""Browse and delete Claude Code session transcripts."""
import curses
import datetime
import json
import os
import shutil
import subprocess
import sys

CLAUDE_DIR = os.path.expanduser("~/.claude")
PROJECTS_DIR = os.path.join(CLAUDE_DIR, "projects")
FILE_HISTORY_DIR = os.path.join(CLAUDE_DIR, "file-history")


class Session:
    def __init__(self, jsonl_path, project_dir):
        self.jsonl_path = jsonl_path
        self.session_id = os.path.splitext(os.path.basename(jsonl_path))[0]
        self.project_dir = project_dir
        self.cwd = None
        self.title = None
        self.mtime = os.path.getmtime(jsonl_path)

    @property
    def data_dir(self):
        # Sibling directory holding tool-results blobs for this session, if any.
        path = os.path.join(self.project_dir, self.session_id)
        return path if os.path.isdir(path) else None

    @property
    def file_history_dir(self):
        path = os.path.join(FILE_HISTORY_DIR, self.session_id)
        return path if os.path.isdir(path) else None

    def size_bytes(self):
        total = os.path.getsize(self.jsonl_path)
        for d in (self.data_dir, self.file_history_dir):
            if d:
                for root, _, files in os.walk(d):
                    for f in files:
                        try:
                            total += os.path.getsize(os.path.join(root, f))
                        except OSError:
                            pass
        return total

    def delete(self):
        os.remove(self.jsonl_path)
        for d in (self.data_dir, self.file_history_dir):
            if d:
                shutil.rmtree(d, ignore_errors=True)


def load_session(jsonl_path, project_dir):
    sess = Session(jsonl_path, project_dir)
    first_user_text = None
    try:
        with open(jsonl_path, "r", errors="replace") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    entry = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if not isinstance(entry, dict):
                    continue

                if sess.cwd is None and "cwd" in entry:
                    sess.cwd = entry["cwd"]

                etype = entry.get("type")
                if etype == "ai-title" and entry.get("aiTitle"):
                    sess.title = entry["aiTitle"]

                if first_user_text is None and etype == "user":
                    msg = entry.get("message", {})
                    content = msg.get("content")
                    if isinstance(content, str):
                        first_user_text = content
                    elif isinstance(content, list):
                        for block in content:
                            if isinstance(block, dict) and block.get("type") == "text":
                                first_user_text = block.get("text")
                                break
    except OSError:
        pass

    if not sess.title:
        if first_user_text:
            text = " ".join(first_user_text.split())
            sess.title = (text[:77] + "...") if len(text) > 80 else text
        else:
            sess.title = "(no title)"

    sess.cwd = sess.cwd or "(unknown directory)"
    return sess


def discover_sessions():
    sessions = []
    if not os.path.isdir(PROJECTS_DIR):
        return sessions
    for name in sorted(os.listdir(PROJECTS_DIR)):
        project_dir = os.path.join(PROJECTS_DIR, name)
        if not os.path.isdir(project_dir):
            continue
        for entry in os.listdir(project_dir):
            if entry.endswith(".jsonl"):
                sessions.append(load_session(os.path.join(project_dir, entry), project_dir))
    sessions.sort(key=lambda s: s.mtime, reverse=True)
    return sessions


def fmt_time(ts):
    return datetime.datetime.fromtimestamp(ts).strftime("%Y-%m-%d %H:%M")


def fmt_size(n):
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1024:
            return f"{n:.0f}{unit}"
        n /= 1024
    return f"{n:.1f}TB"


ROW_HEIGHT = 2  # lines used per session entry (meta line + title line)


def render(stdscr, sessions, top, idx, status):
    height, width = stdscr.getmaxyx()
    list_height = height - 4
    visible = max(1, list_height // ROW_HEIGHT)

    stdscr.erase()
    header = " Claude sessions   (enter=delete  r=resume  q=quit)"
    stdscr.addstr(0, 0, header[: width - 1], curses.A_BOLD)
    stdscr.hline(1, 0, curses.ACS_HLINE, width)

    for row in range(visible):
        i = top + row
        if i >= len(sessions):
            break
        sess = sessions[i]
        attr = curses.color_pair(1) if i == idx else curses.A_NORMAL
        when = fmt_time(sess.mtime)
        size = fmt_size(sess.size_bytes())
        line1 = f"{when}  {size:>7}  {sess.cwd}"
        line2 = f"  {sess.title}"
        y = 2 + row * ROW_HEIGHT
        if y < height - 2:
            stdscr.addstr(y, 0, line1[: width - 1].ljust(width - 1), attr)
        if y + 1 < height - 2:
            stdscr.addstr(y + 1, 0, line2[: width - 1].ljust(width - 1), attr)

    stdscr.hline(height - 2, 0, curses.ACS_HLINE, width)
    if status:
        stdscr.addstr(height - 1, 0, status[: width - 1], curses.color_pair(2))
    stdscr.refresh()
    return visible


def prompt_delete_confirm(stdscr, sess):
    height, width = stdscr.getmaxyx()
    prompt = f"Delete session {sess.session_id} ({sess.cwd})? Type 'y' to confirm: "
    stdscr.move(height - 1, 0)
    stdscr.clrtoeol()
    stdscr.addstr(height - 1, 0, prompt[: width - 1], curses.color_pair(2) | curses.A_BOLD)
    curses.echo()
    curses.curs_set(1)
    try:
        answer = stdscr.getstr(height - 1, min(len(prompt), width - 1)).decode().strip().lower()
    except Exception:
        answer = ""
    curses.noecho()
    curses.curs_set(0)
    return answer == "y"


def resume_session(stdscr, sess):
    curses.endwin()
    cwd = sess.cwd if os.path.isdir(sess.cwd) else None
    try:
        proc = subprocess.Popen(["claude", "--resume", sess.session_id], cwd=cwd)
    except FileNotFoundError:
        proc = None
    if proc is not None:
        while True:
            try:
                proc.wait()
                break
            except KeyboardInterrupt:
                continue  # child owns Ctrl+C; keep waiting instead of exiting with it
    stdscr.touchwin()
    stdscr.refresh()


def run_ui(stdscr, sessions):
    curses.curs_set(0)
    stdscr.keypad(True)
    curses.use_default_colors()
    curses.init_pair(1, curses.COLOR_BLACK, curses.COLOR_YELLOW)
    curses.init_pair(2, curses.COLOR_RED, -1)

    top = 0
    idx = 0
    status = ""

    while True:
        if not sessions:
            stdscr.erase()
            stdscr.addstr(0, 0, "No Claude Code sessions found.")
            stdscr.addstr(2, 0, "Press q to quit.")
            stdscr.refresh()
            if stdscr.getch() in (ord("q"), 27):
                return None
            continue

        idx = max(0, min(idx, len(sessions) - 1))
        visible = render(stdscr, sessions, top, idx, status)
        status = ""

        if idx < top:
            top = idx
        elif idx >= top + visible:
            top = idx - visible + 1

        ch = stdscr.getch()
        if ch in (curses.KEY_UP, ord("k")):
            idx -= 1
        elif ch in (curses.KEY_DOWN, ord("j")):
            idx += 1
        elif ch == curses.KEY_NPAGE:
            idx += visible
        elif ch == curses.KEY_PPAGE:
            idx -= visible
        elif ch in (ord("q"), 27):
            return None
        elif ch in (ord("r"),):
            resume_session(stdscr, sessions[idx])
            sessions[idx] = load_session(sessions[idx].jsonl_path, sessions[idx].project_dir)
            status = f"Returned from session {sessions[idx].session_id}."
        elif ch in (curses.KEY_ENTER, 10, 13, ord("d"), curses.KEY_DC):
            sess = sessions[idx]
            if prompt_delete_confirm(stdscr, sess):
                try:
                    sess.delete()
                    sessions.pop(idx)
                    status = f"Deleted session {sess.session_id}."
                except OSError as e:
                    status = f"Failed to delete: {e}"
            else:
                status = "Cancelled."


def main():
    sessions = discover_sessions()
    curses.wrapper(run_ui, sessions)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(1)
