#!/usr/bin/env python3
"""Build the curated ShipFrame OpenAI/Codex skills-only plugin bundle."""

from __future__ import annotations

import argparse
import json
import shutil
import struct
import zlib
from pathlib import Path

PLUGIN_NAME = "shipframe"
DISPLAY_NAME = "ShipFrame"
DESCRIPTION = "AI coding workflows for teams that plan, prove, and ship."
PUBLISHER = "Juan Urquiza"
WEBSITE = "https://shipframe.hackeruna.com/"
REPOSITORY = "https://github.com/juanitourquiza/shipframe"
LICENSE = "MIT"
ICON_SIZE = 512
CURATED_SKILLS = [
    "project-memory-refresh",
    "feature-discovery",
    "plan-expert",
    "implement-task",
    "code-review",
    "create-pr",
    "bug-diagnosis",
    "release-checklist",
    "project-profile",
    "project-release",
    "deploy-evidence",
    "handoff",
    "init-project",
    "codebase-design",
    "tdd",
    "research",
    "frontend-release",
    "backend-release",
    "a11y-auditor",
    "client-copy-review",
    "mcp-debugging",
    "generate-readme",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build ShipFrame's curated OpenAI/Codex skills-only plugin."
    )
    parser.add_argument(
        "--output-dir",
        default="dist/openai-plugin",
        help="Directory where the bundle folder and zip archive are generated.",
    )
    parser.add_argument(
        "--no-zip",
        action="store_true",
        help="Only generate the expanded plugin folder; skip the zip archive.",
    )
    return parser.parse_args()


def repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def read_version(root: Path) -> str:
    plugin_json = root / ".claude-plugin" / "plugin.json"
    with plugin_json.open(encoding="utf-8") as fh:
        return json.load(fh)["version"]


def manifest(version: str) -> dict[str, object]:
    return {
        "name": PLUGIN_NAME,
        "version": version,
        "description": DESCRIPTION,
        "author": {
            "name": PUBLISHER,
            "url": "https://github.com/juanitourquiza",
        },
        "homepage": WEBSITE,
        "repository": REPOSITORY,
        "license": LICENSE,
        "keywords": [
            "shipframe",
            "ai-coding",
            "workflow",
            "skills",
            "codex",
            "code-review",
            "release-evidence",
        ],
        "skills": "./skills/",
        "interface": {
            "displayName": DISPLAY_NAME,
            "shortDescription": DESCRIPTION,
            "longDescription": (
                "ShipFrame packages team-ready AI coding workflows for Codex and ChatGPT: "
                "refresh project context, discover requirements, plan implementation work, "
                "diagnose bugs, run TDD and accessibility workflows, review diffs, "
                "prepare frontend/backend releases, collect deploy evidence, "
                "generate READMEs, and create handoffs without adding an MCP server."
            ),
            "developerName": PUBLISHER,
            "category": "Productivity",
            "capabilities": ["Skills", "Code review", "Planning", "TDD", "Accessibility", "Release evidence"],
            "websiteURL": WEBSITE,
            "composerIcon": "./assets/icon.png",
            "logo": "./assets/logo.png",
            "defaultPrompt": [
                "Plan this feature before implementation.",
                "Review this diff before I open a PR.",
                "Prepare release evidence for this deploy.",
            ],
            "brandColor": "#111827",
        },
    }


def png_chunk(kind: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)


def write_png(path: Path, *, size: int, background: tuple[int, int, int], accent: tuple[int, int, int]) -> None:
    """Write a dependency-free square ShipFrame PNG icon."""
    pixels: list[bytes] = []
    stripe_top = int(size * 0.38)
    stripe_bottom = int(size * 0.62)
    dot_center = size // 2
    dot_radius = int(size * 0.075)
    corner_radius = int(size * 0.18)

    for y in range(size):
        row = bytearray()
        for x in range(size):
            # Rounded dark card over transparent-like dark background, kept opaque for portal compatibility.
            outside_corner = False
            for cx, cy in ((corner_radius, corner_radius), (size - corner_radius - 1, corner_radius), (corner_radius, size - corner_radius - 1), (size - corner_radius - 1, size - corner_radius - 1)):
                if (x < corner_radius or x >= size - corner_radius or y < corner_radius or y >= size - corner_radius):
                    if (x - cx) ** 2 + (y - cy) ** 2 > corner_radius ** 2:
                        outside_corner = True
            color = background if not outside_corner else (17, 24, 39)
            if stripe_top <= y <= stripe_bottom and not outside_corner:
                color = (248, 250, 252)
            if (x - dot_center) ** 2 + (y - dot_center) ** 2 <= dot_radius ** 2:
                color = accent
            row.extend(color)
        pixels.append(b"\x00" + bytes(row))

    raw = b"".join(pixels)
    png = b"\x89PNG\r\n\x1a\n"
    png += png_chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0))
    png += png_chunk(b"IDAT", zlib.compress(raw, 9))
    png += png_chunk(b"IEND", b"")
    path.write_bytes(png)


def write_assets(bundle_root: Path) -> None:
    assets_dir = bundle_root / "assets"
    assets_dir.mkdir()
    write_png(
        assets_dir / "icon.png",
        size=ICON_SIZE,
        background=(31, 41, 55),
        accent=(132, 204, 22),
    )
    shutil.copy2(assets_dir / "icon.png", assets_dir / "logo.png")


def copy_skill(root: Path, bundle_root: Path, skill_name: str) -> None:
    source = root / "skills" / skill_name
    if not (source / "SKILL.md").is_file():
        raise FileNotFoundError(f"Missing canonical skill: {source}/SKILL.md")
    destination = bundle_root / "skills" / skill_name
    shutil.copytree(source, destination, symlinks=False)


def build() -> tuple[Path, Path | None]:
    args = parse_args()
    root = repo_root()
    output_dir = (root / args.output_dir).resolve()
    bundle_root = output_dir / PLUGIN_NAME
    archive_path = output_dir / f"{PLUGIN_NAME}-openai-plugin.zip"

    if bundle_root.exists():
        shutil.rmtree(bundle_root)
    output_dir.mkdir(parents=True, exist_ok=True)

    (bundle_root / ".codex-plugin").mkdir(parents=True)
    (bundle_root / "skills").mkdir()
    with (bundle_root / ".codex-plugin" / "plugin.json").open("w", encoding="utf-8") as fh:
        json.dump(manifest(read_version(root)), fh, indent=2)
        fh.write("\n")

    for skill_name in CURATED_SKILLS:
        copy_skill(root, bundle_root, skill_name)

    write_assets(bundle_root)

    for optional_file in ("LICENSE", "THIRD_PARTY_NOTICES.md"):
        source = root / optional_file
        if source.is_file():
            shutil.copy2(source, bundle_root / optional_file)

    if args.no_zip:
        return bundle_root, None

    if archive_path.exists():
        archive_path.unlink()
    created_archive = shutil.make_archive(
        str(archive_path.with_suffix("")), "zip", root_dir=output_dir, base_dir=PLUGIN_NAME
    )
    return bundle_root, Path(created_archive)


def main() -> None:
    bundle_root, archive_path = build()
    print(f"OpenAI plugin bundle folder: {bundle_root}")
    if archive_path is not None:
        print(f"OpenAI plugin archive: {archive_path}")
    print("Bundled skills:")
    for skill_name in CURATED_SKILLS:
        print(f"- {skill_name}")


if __name__ == "__main__":
    main()
