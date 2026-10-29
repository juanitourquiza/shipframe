"""ShipFrame plugin entrypoint for Hermes Agent.

Registers every ShipFrame skill under ``skills/`` as a namespaced, read-only
Hermes skill (``shipframe:<skill>``), so the same skill catalog that ShipFrame
installs for Claude Code, Codex CLI, and OpenCode loads inside Hermes without
copying files into ``~/.hermes/skills``.

This module is intentionally dependency-free: it touches only the local
``skills/`` directory and registers skills. No network access, no subprocesses,
no host state changes.
"""

from pathlib import Path


def register(ctx):
    skills_dir = Path(__file__).parent / "skills"
    for child in sorted(skills_dir.iterdir()):
        skill_md = child / "SKILL.md"
        if child.is_dir() and skill_md.exists():
            ctx.register_skill(child.name, skill_md)
