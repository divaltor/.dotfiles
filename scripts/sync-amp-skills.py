#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml"]
# ///
"""Mirror ~/.dotfiles/.agents/skills into the Amp User Skills repository.

Dotfiles are the source of truth. The Amp repository is overwritten, never edited.
A skill with `metadata: {scope: local}` in its frontmatter stays on this laptop.
Skills that exist only in the Amp repository are left alone; the ones this script
published are listed in `.dotfiles-managed` there, so removing a skill from
dotfiles also removes it from Amp.
"""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

import yaml

DOTFILES = Path(__file__).resolve().parent.parent
SOURCE = DOTFILES / ".agents" / "skills"
CLONE = Path.home() / ".cache/amp/repositories/ampcode.com-user-skills"
MANIFEST = ".dotfiles-managed"
NAME_RE = re.compile(r"[a-z0-9]+(-[a-z0-9]+)*")
FRONTMATTER_RE = re.compile(r"---\n(.*?)\n---\n", re.S)


def git(repo: Path, *args: str) -> str:
    result = subprocess.run(["git", "-C", str(repo), *args], capture_output=True, text=True)
    if result.returncode:
        sys.exit(f"git {' '.join(args)} failed in {repo}:\n{result.stderr.strip()}")
    return result.stdout.strip()


def problems(skill: Path) -> tuple[list[str], bool]:
    """Return what Amp would reject about a skill, and whether it is local-only."""
    skill_file = skill / "SKILL.md"
    if not skill_file.is_file():
        return ["no SKILL.md"], False
    match = FRONTMATTER_RE.match(skill_file.read_text())
    if not match:
        return ["no frontmatter"], False
    try:
        meta = yaml.safe_load(match.group(1))
    except yaml.YAMLError as error:
        return [f"invalid YAML ({str(error).splitlines()[0]})"], False

    local = (meta.get("metadata") or {}).get("scope") == "local"
    errors = []
    if meta.get("name") != skill.name:
        errors.append(f"name {meta.get('name')!r} must equal the directory name")
    if not NAME_RE.fullmatch(skill.name) or len(skill.name) > 64:
        errors.append("directory name must be lowercase kebab-case, at most 64 characters")
    description = str(meta.get("description") or "")
    if not description:
        errors.append("missing description")
    elif len(description) > 1024:
        errors.append(f"description is {len(description)} characters, the limit is 1024")
    if not local:
        for path in skill.rglob("*"):
            if path.is_file() and b"\0" in path.read_bytes():
                errors.append(f"binary file {path.relative_to(skill)} (Amp does not serve it)")
    return errors, local


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--dry-run", action="store_true", help="show what would change, then undo it")
    parser.add_argument("--no-push", action="store_true", help="commit in the clone but do not push")
    args = parser.parse_args()

    sync, local, failed = [], [], False
    for skill in sorted(p for p in SOURCE.iterdir() if p.is_dir() and not p.name.startswith(".")):
        errors, is_local = problems(skill)
        if errors:
            failed = True
            print(f"ERROR {skill.name}: " + "; ".join(errors))
        (local if is_local else sync).append(skill.name)
    if failed:
        sys.exit("Fix the skills above in dotfiles (or mark them `metadata: {scope: local}`). Nothing was synced.")

    if not CLONE.exists():
        subprocess.run(["amp", "clone", "user-skills", str(CLONE)], check=True)
    if git(CLONE, "status", "--porcelain"):
        sys.exit(f"{CLONE} has uncommitted changes; clean it before syncing.")
    git(CLONE, "fetch", "-q", "origin")
    git(CLONE, "merge", "--ff-only", "-q", "origin/main")

    manifest = CLONE / MANIFEST
    previous = set(manifest.read_text().split()) if manifest.exists() else set()
    for name in sorted(previous - set(sync)):
        shutil.rmtree(CLONE / name, ignore_errors=True)
    for name in sync:
        target = CLONE / name
        shutil.rmtree(target, ignore_errors=True)
        shutil.copytree(SOURCE / name, target, ignore=shutil.ignore_patterns(".DS_Store", ".git"))
    manifest.write_text("".join(f"{name}\n" for name in sync))

    git(CLONE, "add", "-A")
    changes = git(CLONE, "status", "--short")
    print(f"{len(sync)} synced, {len(local)} local-only ({', '.join(local) or 'none'})")
    if not changes:
        print("Amp is already up to date.")
        return
    print(changes)
    if args.dry_run:
        git(CLONE, "reset", "-q", "--hard")
        git(CLONE, "clean", "-qfd")
        print("Dry run: nothing committed.")
        return

    dirty = "+uncommitted" if git(DOTFILES, "status", "--porcelain", "--", ".agents/skills") else ""
    git(CLONE, "commit", "-q", "-m", f"Sync from dotfiles@{git(DOTFILES, 'rev-parse', '--short', 'HEAD')}{dirty}")
    if args.no_push:
        print("Committed in the clone; not pushed.")
        return
    git(CLONE, "push", "-q", "origin", "HEAD:main")
    print("Pushed. New threads pick it up; run reload_skills in a running thread.")


if __name__ == "__main__":
    main()
