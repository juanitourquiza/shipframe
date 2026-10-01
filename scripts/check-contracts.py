#!/usr/bin/env python3
"""Validate required metadata and naming consistency for skills and agents."""
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def frontmatter(path):
    text = path.read_text(encoding="utf-8")
    match = re.match(r"\A---\s*\n(.*?)\n---\s*(?:\n|$)", text, re.S)
    if not match:
        raise ValueError("missing or malformed YAML frontmatter")
    fields = {}
    list_items = {}
    for number, line in enumerate(match.group(1).splitlines(), 2):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if line[0].isspace():
            if re.match(r"\s+-\s+\S", line) and fields:
                list_items[next(reversed(fields))] = True
            continue  # folded/block scalar continuation
        item = re.match(r"([A-Za-z][A-Za-z0-9_-]*):(?:\s*(.*))?$", line)
        if not item:
            raise ValueError(f"invalid top-level metadata at line {number}: {line!r}")
        key, value = item.groups()
        if key in fields:
            raise ValueError(f"duplicate metadata key '{key}'")
        fields[key] = (value or "").strip()
    return fields, list_items


def check(directory, kind, required, identity):
    errors, identities = [], {}
    paths = directory.glob("*/SKILL.md") if kind == "skill" else directory.glob("*.md")
    for path in sorted(paths):
        try:
            fields, list_items = frontmatter(path)
            missing = [key for key in required if key not in fields or (not fields[key] and key not in list_items)]
            if missing:
                errors.append(f"{path.relative_to(ROOT)}: missing/empty required metadata: {', '.join(missing)}")
                continue
            name = fields[identity].strip("'\"")
            expected = (path.parent.name,) if kind == "skill" else (path.stem, path.stem + "-agent")
            if name not in expected:
                errors.append(f"{path.relative_to(ROOT)}: metadata '{identity}' is '{name}', expected one of {', '.join(expected)}")
            if name in identities:
                errors.append(f"{path.relative_to(ROOT)}: duplicate {kind} name '{name}' (also {identities[name].relative_to(ROOT)})")
            identities[name] = path
        except (OSError, ValueError) as error:
            errors.append(f"{path.relative_to(ROOT)}: {error}")
    return errors


def validate(root=ROOT):
    global ROOT
    ROOT = Path(root).resolve()
    errors = []
    for folder, kind, required, identity in (
        (ROOT / "skills", "skill", ("name", "description"), "name"),
        (ROOT / "agents", "agent", ("name", "description", "model", "tools"), "name"),
    ):
        if not folder.is_dir():
            errors.append(f"{folder.relative_to(ROOT)}: required directory is missing")
        else:
            errors.extend(check(folder, kind, required, identity))
    return errors


if __name__ == "__main__":
    failures = validate()
    if failures:
        print("Contract validation failed:", file=sys.stderr)
        print("\n".join(f"- {failure}" for failure in failures), file=sys.stderr)
        sys.exit(1)
    print("Skill and agent metadata contracts are valid.")
