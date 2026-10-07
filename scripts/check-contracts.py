#!/usr/bin/env python3
"""Validate required metadata and naming consistency for skills and agents."""
import json
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
    routing_path = ROOT / "routing.json"
    try:
        routing = json.loads(routing_path.read_text(encoding="utf-8"))
        if routing.get("schemaVersion") != 2:
            errors.append("routing.json: schemaVersion must be 2")
        intents = routing.get("intents")
        aliases = routing.get("aliases")
        variants = routing.get("host_variants")
        qa_gate = routing.get("qa_gate")
        if not isinstance(intents, dict) or not intents:
            errors.append("routing.json: intents must be a non-empty object")
            intents = {}
        if not isinstance(aliases, dict):
            errors.append("routing.json: aliases must be an object")
            aliases = {}
        if not isinstance(variants, dict):
            errors.append("routing.json: host_variants must be an object")
            variants = {}
        if (not isinstance(qa_gate, dict) or not isinstance(qa_gate.get("tokens"), list)
                or not qa_gate["tokens"] or not all(isinstance(token, str) and token for token in qa_gate["tokens"])):
            errors.append("routing.json: qa_gate.tokens must be a non-empty list")

        skill_names, agent_names = set(), set()
        for path in (ROOT / "skills").glob("*/SKILL.md"):
            try:
                skill_names.add(frontmatter(path)[0].get("name", "").strip("'\""))
            except (OSError, ValueError):
                pass
        for path in (ROOT / "agents").glob("*.md"):
            try:
                agent_names.add(frontmatter(path)[0].get("name", "").strip("'\""))
            except (OSError, ValueError):
                pass

        for canonical, targets in aliases.items():
            if canonical not in skill_names:
                errors.append(f"routing.json: alias canonical target '{canonical}' is not a skill")
            if not isinstance(targets, list) or not targets:
                errors.append(f"routing.json: aliases['{canonical}'] must be a non-empty list")
                continue
            for target in targets:
                if not isinstance(target, str) or target not in agent_names:
                    errors.append(f"routing.json: alias target '{target}' is not a known agent")

        qa_tokens = qa_gate.get("tokens", []) if isinstance(qa_gate, dict) else []
        qa_tokens = [token for token in qa_tokens if isinstance(token, str)]

        def check_sequence(sequence, context):
            if not isinstance(sequence, str) or not sequence.strip():
                errors.append(f"routing.json: {context} must be a non-empty sequence")
                return
            for raw_step in re.split(r"\s*(?:→|·)\s*", sequence):
                step = re.sub(r"\([^)]*\)", " ", raw_step).strip()
                step = re.sub(r"\s+if fixes are requested\s*$", "", step, flags=re.I).strip()
                qa_matches = [token for token in qa_tokens if re.search(rf"\b{re.escape(token)}\b", step, re.I)]
                if qa_matches:
                    remainder = step
                    for token in qa_matches:
                        remainder = re.sub(rf"\b{re.escape(token)}\b", " ", remainder, flags=re.I)
                    if re.sub(r"\bor\b", " ", remainder, flags=re.I).strip():
                        errors.append(f"routing.json: {context} has unknown QA step text '{step}'")
                elif step not in skill_names and step not in agent_names:
                    errors.append(f"routing.json: {context} references unknown skill/agent '{step}'")

        for intent, sequence in intents.items():
            check_sequence(sequence, f"intent '{intent}'")
        for intent, variant in variants.items():
            if intent not in intents:
                errors.append(f"routing.json: host variant references unknown intent '{intent}'")
            if not isinstance(variant, dict) or not isinstance(variant.get("agents"), str):
                errors.append(f"routing.json: host_variants['{intent}'].agents must be a sequence")
                continue
            for name in re.findall(r"\b[a-z][a-z0-9-]+\b", variant["agents"]):
                if name not in skill_names and name not in agent_names:
                    errors.append(f"routing.json: host variant for '{intent}' references unknown skill/agent '{name}'")
            check_sequence(variant["agents"], f"host variant '{intent}' agents")
            check_sequence(variant.get("expands_to"), f"host variant '{intent}' expands_to")
    except (OSError, json.JSONDecodeError) as error:
        errors.append(f"routing.json: cannot read routing contract: {error}")
    return errors


if __name__ == "__main__":
    failures = validate()
    if failures:
        print("Contract validation failed:", file=sys.stderr)
        print("\n".join(f"- {failure}" for failure in failures), file=sys.stderr)
        sys.exit(1)
    print("Skill and agent metadata contracts are valid.")
