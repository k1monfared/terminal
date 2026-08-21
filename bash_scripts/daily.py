#!/usr/bin/env python3
"""Open (and fill if needed) the daily loglog file for a given date."""

import os
import re
import sys
import subprocess
from datetime import date, timedelta
from pathlib import Path

# Make the local loglog parser available without requiring a pip install.
LOGLOG_REPO = Path.home() / "public" / "loglog"
if str(LOGLOG_REPO) not in sys.path:
    sys.path.insert(0, str(LOGLOG_REPO))

import loglog  # noqa: E402

DAILY_BASE = Path.home() / "Documents" / "notes" / "daily"
DATE_RE = re.compile(r"^(\d{4})-(\d{2})-(\d{2})")


def parse_date_arg(arg: str) -> date:
    """Parse a YYYY-mm-dd string into a date object."""
    try:
        year, month, day = arg.split("-")
        return date(int(year), int(month), int(day))
    except (ValueError, AttributeError):
        raise SystemExit(f"Invalid date: {arg!r}. Expected YYYY-mm-dd.")


def target_date_from_args(argv: list[str]) -> date:
    """Return the date requested on the CLI, defaulting to today."""
    if len(argv) > 2:
        raise SystemExit("Usage: daily [YYYY-mm-dd]")
    if len(argv) == 2:
        return parse_date_arg(argv[1])
    return date.today()


def month_file_path(target: date) -> Path:
    """Return the path daily/<YYYY>/daily_<YYYY>_<MM>.log for the target date."""
    year_folder = DAILY_BASE / f"{target.year}"
    return year_folder / f"daily_{target.year}_{target.month:02d}.log"


def parse_date_from_node_data(data: str) -> date | None:
    """Extract a YYYY-mm-dd date from the beginning of a node data string."""
    match = DATE_RE.match(data.strip())
    if not match:
        return None
    try:
        return date(int(match.group(1)), int(match.group(2)), int(match.group(3)))
    except ValueError:
        return None


def load_existing_date_nodes(path: Path) -> dict[str, loglog.TreeNode]:
    """Return a mapping of ISO date string -> TreeNode for top-level date entries."""
    if not path.exists():
        return {}

    try:
        root = loglog.build_tree_from_file(str(path))
    except Exception:
        return {}

    result: dict[str, loglog.TreeNode] = {}
    for child in root.children:
        entry_date = parse_date_from_node_data(child.data)
        if entry_date is not None:
            result[entry_date.isoformat()] = child
    return result


def empty_date_node(date_obj: date, child_count: int) -> loglog.TreeNode:
    """Create a new loglog date node with one empty child bullet."""
    node = loglog.TreeNode(name=f"{child_count}.", data=date_obj.isoformat())
    node.add_child(loglog.TreeNode(name="0.", data=""))
    return node


def rewrite_month_file(path: Path, target: date) -> None:
    """Rewrite the month file so every day from the 1st through target exists."""
    existing = load_existing_date_nodes(path)

    new_root = loglog.TreeNode(name="")
    new_root.type = "root"

    # Fill 1st of target month through target, preserving existing content.
    current = date(target.year, target.month, 1)
    while current <= target:
        date_str = current.isoformat()
        if date_str in existing:
            new_root.add_child(existing[date_str])
        else:
            new_root.add_child(empty_date_node(current, len(new_root.children)))
        current += timedelta(days=1)

    # Preserve any existing entries after the target date in their original order.
    future_nodes = [
        (d, node)
        for d, node in sorted(existing.items())
        if date.fromisoformat(d) > target
    ]
    for _, node in future_nodes:
        new_root.add_child(node)

    with open(path, "w", encoding="utf-8") as f:
        loglog.print_tree_to_file(new_root, f)


def open_in_editor(path: Path) -> None:
    """Open the file in the default editor, detached, mirroring note.sh behavior."""
    editor = os.environ.get("EDITOR", "code")
    subprocess.Popen(
        [editor, str(path)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )


def main(argv: list[str]) -> None:
    target = target_date_from_args(argv)
    path = month_file_path(target)

    # Ensure the year folder exists.
    path.parent.mkdir(parents=True, exist_ok=True)

    rewrite_month_file(path, target)
    open_in_editor(path)


if __name__ == "__main__":
    main(sys.argv)
