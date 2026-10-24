#!/usr/bin/env python3
"""Idempotently wire ShipFrame's local CI include and root-level MR job rules."""
from __future__ import annotations

import argparse
import os
import re
import sys
import tempfile
from pathlib import Path

INCLUDE = ".gitlab/ci/shipframe-review.yml"
INCLUDE_MARKER = "# shipframe-pr-review-managed-include"
JOB = "shipframe-ai-mr-review"
JOB_MARKER = "# shipframe-pr-review-managed-job"
JOB_BLOCK = (
    f"\n{JOB}:\n"
    "  extends: .shipframe-ai-mr-review-template\n"
    "  rules:\n"
    '    - if: \'$CI_PIPELINE_SOURCE == "merge_request_event" && $CI_MERGE_REQUEST_EVENT_TYPE == "detached" && $CI_MERGE_REQUEST_SOURCE_PROJECT_ID == $CI_PROJECT_ID\'\n'
    "    - when: never\n"
    f"{JOB_MARKER}\n"
)


def ensure_mr_pipeline_allowed(lines: list[str]) -> None:
    start = next((i for i, line in enumerate(lines) if re.match(r"^workflow:\s*$", line.rstrip("\r\n"))), None)
    if start is None:
        return
    end = next((i for i in range(start + 1, len(lines)) if lines[i].strip() and not lines[i].startswith((" ", "\t", "#"))), len(lines))
    if "merge_request_event" not in "".join(lines[start:end]):
        raise ValueError(
            "existing top-level workflow rules do not allow merge_request_event; "
            "add a compatible MR workflow rule, then rerun the installer"
        )


def add_include(source: str) -> str:
    lines = source.splitlines(keepends=True)
    if INCLUDE in source:
        return source
    include_index = next((i for i, line in enumerate(lines) if re.match(r"^include:\s*(?:#.*)?$", line.rstrip("\r\n"))), None)
    if include_index is None:
        prefix = "---\n" if lines and lines[0].strip() == "---" else ""
        body = "".join(lines[1:]) if prefix else source
        return prefix + f"include:\n  - local: '{INCLUDE}' {INCLUDE_MARKER}\n" + body

    inline = lines[include_index].split(":", 1)[1].strip()
    if inline:
        if inline.startswith("[") and inline.endswith("]"):
            entries = inline[1:-1].strip()
            lines[include_index] = f"include: [{entries}, {{ local: '{INCLUDE}' }}] {INCLUDE_MARKER}\n"
            return "".join(lines)
        if inline.startswith("#"):
            pass
        else:
            lines[include_index] = f"include:\n  - {inline}\n"
            lines.insert(include_index + 1, f"  - local: '{INCLUDE}' {INCLUDE_MARKER}\n")
            return "".join(lines)

    end = include_index + 1
    while end < len(lines):
        line = lines[end]
        if line.strip() and not line.startswith((" ", "\t", "#")):
            break
        end += 1
    children = [line for line in lines[include_index + 1 : end] if line.strip() and not line.lstrip().startswith("#")]
    if children and not any(re.match(r"^\s*-\s", line) for line in children):
        raise ValueError("top-level include is a mapping, not a list; add the local include manually to avoid rewriting existing CI YAML")
    lines.insert(end, f"  - local: '{INCLUDE}' {INCLUDE_MARKER}\n")
    return "".join(lines)


def updated_content(path: Path) -> str:
    source = path.read_text(encoding="utf-8") if path.exists() else ""
    lines = source.splitlines(keepends=True)
    ensure_mr_pipeline_allowed(lines)
    job_match = re.search(rf"^{re.escape(JOB)}:\s*$", source, re.MULTILINE)
    if job_match and JOB_MARKER not in source:
        raise ValueError(f"a {JOB} job already exists; rename it before installing ShipFrame's managed job")
    if INCLUDE not in source:
        source = add_include(source)
    if JOB_MARKER not in source:
        if source and not source.endswith("\n"):
            source += "\n"
        source += JOB_BLOCK
    return source


def remove_managed(path: Path) -> None:
    if not path.exists():
        return
    source = path.read_text(encoding="utf-8")
    generated = f"include:\n  - local: '{INCLUDE}' {INCLUDE_MARKER}\n" + JOB_BLOCK
    if source == generated:
        path.unlink()
        return
    source = re.sub(
        rf"(?m)^\n?{re.escape(JOB)}:\n(?:[ \t].*\n)*{re.escape(JOB_MARKER)}\n?",
        "\n",
        source,
    )
    lines = source.splitlines(keepends=True)
    lines = [line for line in lines if not (INCLUDE_MARKER in line and INCLUDE in line)]
    result = "".join(lines)
    if result == "include:\n":
        result = ""
    if result:
        path.write_text(result, encoding="utf-8")
    else:
        path.unlink()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--remove", action="store_true")
    parser.add_argument("config", type=Path)
    parser.add_argument("template", type=Path, nargs="?")
    args = parser.parse_args()
    if args.remove:
        remove_managed(args.config)
        return 0
    try:
        result = updated_content(args.config)
        if args.template is not None:
            result_template = args.template.read_text(encoding="utf-8")
            # Keep template installation atomic with respect to safety checks.
            if ".shipframe-ai-mr-review-template:" not in result_template:
                raise ValueError("GitLab review template must define the hidden ShipFrame job")
    except (OSError, ValueError) as exc:
        print(f"Error: could not safely update {args.config}: {exc}", file=sys.stderr)
        return 2
    if args.check:
        return 0
    args.config.parent.mkdir(parents=True, exist_ok=True)
    fd, temp_name = tempfile.mkstemp(prefix=f".{args.config.name}.", dir=args.config.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(result)
        os.replace(temp_name, args.config)
    finally:
        if os.path.exists(temp_name):
            os.unlink(temp_name)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
