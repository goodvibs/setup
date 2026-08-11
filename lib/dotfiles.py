#!/usr/bin/env python3
"""Manifest-driven dotfiles manager."""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:  # pragma: no cover - Python < 3.11
    print("dotfiles: Python 3.11+ required (tomllib)", file=sys.stderr)
    sys.exit(1)


@dataclass
class RepoSpec:
    url: str
    kind: str = "submodule"


@dataclass
class Entry:
    name: str
    source: str
    target: str
    description: str = ""
    optional: bool = False
    repo: RepoSpec | None = None


@dataclass
class Manifest:
    configs_root: str
    entries: list[Entry]


@dataclass
class ApplyOptions:
    dry_run: bool = False
    force: bool = False
    backup: bool = False
    interactive: bool = False
    verbose: bool = False


@dataclass
class LinkStatus:
    entry: Entry
    target: str
    state: str
    detail: str = ""


SETUP_ROOT = Path(__file__).resolve().parent.parent
MANIFEST_PATH = SETUP_ROOT / "manifest.toml"
SKIP_LOCAL_NAMES = {".gitignore", ".DS_Store"}


def run_cmd(cmd: list[str], *, dry_run: bool = False, check: bool = True) -> subprocess.CompletedProcess[str]:
    if dry_run:
        print(f"DRY: {' '.join(cmd)}")
        return subprocess.CompletedProcess(cmd, 0, "", "")
    return subprocess.run(cmd, text=True, capture_output=True, check=check)


def load_manifest(path: Path = MANIFEST_PATH) -> Manifest:
    with path.open("rb") as handle:
        data = tomllib.load(handle)

    repo = data.get("repo", {})
    entries: list[Entry] = []
    seen_targets: set[str] = set()
    for raw in data.get("entry", []):
        name = raw["name"]
        target = raw.get("target")
        if not isinstance(target, str) or not target:
            raise ValueError(f"entry {name!r}: missing or invalid 'target' (non-empty string required)")
        if target in seen_targets:
            raise ValueError(f"duplicate manifest target: {target!r}")
        seen_targets.add(target)

        repo_spec = None
        if "repo" in raw:
            repo_spec = RepoSpec(
                url=raw["repo"]["url"],
                kind=raw["repo"].get("kind", "submodule"),
            )
        entries.append(
            Entry(
                name=name,
                source=raw["source"],
                target=target,
                description=raw.get("description", ""),
                optional=raw.get("optional", False),
                repo=repo_spec,
            )
        )
    return Manifest(configs_root=repo.get("configs_root", "configs"), entries=entries)


def expand_path(raw: str, home: Path | None = None) -> Path:
    home = home or Path.home()
    if raw.startswith("~/"):
        return home / raw[2:]
    if raw == "~":
        return home
    return Path(os.path.expandvars(raw)).expanduser()


def source_path(entry: Entry, setup_root: Path = SETUP_ROOT) -> Path:
    return setup_root / entry.source


def managed_config_basenames(
    manifest: Manifest,
    home: Path | None = None,
    setup_root: Path = SETUP_ROOT,
) -> set[str]:
    home = home or Path.home()
    config_dir = home / ".config"
    names: set[str] = set()
    for entry in manifest.entries:
        if entry.optional and not source_path(entry, setup_root).exists():
            continue
        path = expand_path(entry.target, home)
        if path == config_dir or config_dir in path.parents:
            names.add(path.relative_to(config_dir).parts[0])
    return names


def backup_target(target: Path, *, dry_run: bool = False) -> None:
    ts = datetime.now().strftime("%Y%m%d-%H%M%S")
    backup = target.with_name(f"{target.name}.bak.{ts}")
    if dry_run:
        print(f"DRY: mv {target} {backup}")
        return
    target.rename(backup)


def remove_target(target: Path, *, dry_run: bool = False) -> None:
    if dry_run:
        print(f"DRY: rm -rf {target}")
        return
    if target.is_symlink() or target.is_file():
        target.unlink()
    elif target.is_dir():
        shutil.rmtree(target)


def is_same_symlink(src: Path, dst: Path) -> bool:
    return dst.is_symlink() and dst.resolve() == src.resolve()


def confirm(message: str) -> bool:
    answer = input(f"{message} [y/N] ").strip().lower()
    return answer in {"y", "yes"}


def ensure_parent(path: Path, *, dry_run: bool = False) -> None:
    if dry_run:
        print(f"DRY: mkdir -p {path.parent}")
        return
    path.parent.mkdir(parents=True, exist_ok=True)


def link_one(src: Path, dst: Path, opts: ApplyOptions) -> tuple[bool, str]:
    src = src.resolve()
    if not src.exists():
        if opts.verbose:
            return False, f"missing source: {src}"
        return False, f"missing source: {src}"

    if is_same_symlink(src, dst):
        return True, "ok"

    if dst.exists() or dst.is_symlink():
        if opts.interactive and not confirm(f"Replace {dst}?"):
            return False, "skipped (interactive)"
        if opts.backup:
            backup_target(dst, dry_run=opts.dry_run)
        elif opts.force:
            remove_target(dst, dry_run=opts.dry_run)
        else:
            return False, "conflict (use --force or --backup)"

    ensure_parent(dst, dry_run=opts.dry_run)
    if opts.dry_run:
        print(f"DRY: ln -s {src} {dst}")
        return True, "linked (dry-run)"

    dst.symlink_to(src)
    return True, f"linked -> {src}"


def apply_manifest(
    manifest: Manifest,
    opts: ApplyOptions,
    *,
    setup_root: Path = SETUP_ROOT,
    home: Path | None = None,
) -> list[LinkStatus]:
    home = home or Path.home()

    results: list[LinkStatus] = []
    for entry in manifest.entries:
        src = source_path(entry, setup_root)
        if not src.exists() and entry.optional:
            results.append(LinkStatus(entry, entry.target, "optional-missing", f"source missing: {src}"))
            continue
        if not src.exists():
            results.append(LinkStatus(entry, entry.target, "error", f"source missing: {src}"))
            continue

        dst = expand_path(entry.target, home)
        ok, detail = link_one(src, dst, opts)
        state = "ok" if ok and detail == "ok" else ("linked" if ok else "error")
        if ok and detail not in {"ok"}:
            print(f"{entry.name}: {dst} {detail}")
        elif opts.verbose and detail == "ok":
            print(f"{entry.name}: {dst} ok")
        results.append(LinkStatus(entry, entry.target, state, detail))
    return results


def sync_submodules(*, setup_root: Path = SETUP_ROOT, dry_run: bool = False) -> int:
    cmd = ["git", "-C", str(setup_root), "submodule", "update", "--init", "--recursive"]
    if dry_run:
        print(f"DRY: {' '.join(cmd)}")
        return 0
    result = subprocess.run(cmd)
    return result.returncode


def audit_manifest(
    manifest: Manifest,
    *,
    setup_root: Path = SETUP_ROOT,
    home: Path | None = None,
) -> dict[str, list[str]]:
    home = home or Path.home()
    ok: list[str] = []
    drift: list[str] = []
    repo_only: list[str] = []
    orphans: list[str] = []

    for entry in manifest.entries:
        src = source_path(entry, setup_root)
        if not src.exists():
            if entry.optional:
                repo_only.append(f"{entry.name}: optional source missing ({entry.source})")
            else:
                drift.append(f"{entry.name}: source missing in repo ({entry.source})")
            continue

        dst = expand_path(entry.target, home)
        if is_same_symlink(src, dst):
            ok.append(f"{entry.name}: {dst}")
        elif not dst.exists() and not dst.is_symlink():
            drift.append(f"{entry.name}: not linked ({dst})")
        else:
            if dst.is_symlink():
                drift.append(f"{entry.name}: wrong symlink {dst} -> {os.readlink(dst)} (want {src})")
            else:
                drift.append(f"{entry.name}: path exists but is not symlink ({dst})")

    notable_home_files = {".bashrc", ".profile", ".fzf.bash", ".fzf.zsh", ".npmrc", ".hidpi-disable"}
    home_dotfiles = sorted(
        item.name
        for item in home.iterdir()
        if item.name.startswith(".") and item.is_file() and not item.is_symlink()
    )
    ignored_home_files = {
        ".bash_history",
        ".claude.json",
        ".DS_Store",
        ".CFUserTextEncoding",
        ".lesshst",
        ".localized",
        ".psql_history",
        ".python_history",
        ".viminfo",
        ".zsh_history",
        ".zshDDPMenv",
    }
    for name in home_dotfiles:
        if name in ignored_home_files or name.startswith(".zcompdump"):
            continue
        if name in notable_home_files:
            orphans.append(f"home file not in manifest: ~/{name}")

    config_dir = home / ".config"
    if config_dir.is_dir() and not config_dir.is_symlink():
        managed = managed_config_basenames(manifest, home, setup_root)
        for item in sorted(config_dir.iterdir(), key=lambda p: p.name):
            if item.name in managed or item.name in SKIP_LOCAL_NAMES:
                continue
            if item.name.startswith("."):
                continue
            orphans.append(f"local .config entry not in manifest: ~/.config/{item.name}")

    return {"ok": ok, "drift": drift, "repo_only": repo_only, "orphans": orphans}


def print_audit(report: dict[str, list[str]]) -> int:
    sections = [
        ("OK", report["ok"]),
        ("DRIFT", report["drift"]),
        ("REPO ONLY / OPTIONAL", report["repo_only"]),
        ("ORPHANS (candidates to adopt or ignore)", report["orphans"]),
    ]
    for title, items in sections:
        print(f"\n{title} ({len(items)})")
        if not items:
            print("  (none)")
            continue
        for item in items:
            print(f"  - {item}")

    if report["drift"]:
        return 1
    return 0


def cmd_apply(args: argparse.Namespace) -> int:
    manifest = load_manifest()
    opts = ApplyOptions(
        dry_run=args.dry_run,
        force=args.force,
        backup=args.backup,
        interactive=args.interactive,
        verbose=args.verbose,
    )
    results = apply_manifest(manifest, opts)
    errors = [r for r in results if r.state == "error"]
    if errors:
        for err in errors:
            print(f"ERROR {err.entry.name} {err.target}: {err.detail}", file=sys.stderr)
        return 1
    print("Done.")
    return 0


def cmd_audit(args: argparse.Namespace) -> int:
    manifest = load_manifest()
    report = audit_manifest(manifest)
    return print_audit(report)


def cmd_status(args: argparse.Namespace) -> int:
    manifest = load_manifest()
    report = audit_manifest(manifest)
    print(f"Setup root: {SETUP_ROOT}")
    print(f"Manifest:   {MANIFEST_PATH}")
    print(f"Entries:    {len(manifest.entries)}")
    print(f"Linked OK:  {len(report['ok'])}")
    print(f"Drift:      {len(report['drift'])}")
    print(f"Optional:   {len(report['repo_only'])}")
    print(f"Orphans:    {len(report['orphans'])}")
    if report["drift"]:
        print("\nRun `./bin/dotfiles audit` for details.")
        return 1
    return 0


def cmd_sync(args: argparse.Namespace) -> int:
    return sync_submodules(dry_run=args.dry_run)


def cmd_bootstrap(args: argparse.Namespace) -> int:
    code = sync_submodules(dry_run=args.dry_run)
    if code != 0:
        return code
    args.force = args.force or True
    return cmd_apply(args)


def cmd_add(args: argparse.Namespace) -> int:
    manifest = load_manifest()
    name = args.name
    if any(entry.name == name for entry in manifest.entries):
        print(f"Entry already exists: {name}", file=sys.stderr)
        return 1

    config_dir = SETUP_ROOT / "configs" / name
    if config_dir.exists():
        print(f"Config directory already exists: {config_dir}", file=sys.stderr)
        return 1

    target = args.target
    if args.dry_run:
        print(f"DRY: mkdir {config_dir}")
        print(f"DRY: append manifest entry {name} -> {target}")
        return 0

    config_dir.mkdir(parents=True)
    (config_dir / ".gitkeep").touch()

    block = [
        "",
        "[[entry]]",
        f'name = "{name}"',
        f"source = \"configs/{name}\"",
        f'target = "{target}"',
    ]
    if args.description:
        block.append(f'description = "{args.description}"')
    if args.optional:
        block.append("optional = true")

    with MANIFEST_PATH.open("a", encoding="utf-8") as handle:
        handle.write("\n".join(block) + "\n")

    print(f"Created {config_dir}")
    print(f"Updated {MANIFEST_PATH}")
    print("Next: add config files, commit, then run `./bin/dotfiles apply`")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="dotfiles",
        description="Manifest-driven dotfiles manager. With no command, print link health summary.",
    )
    sub = parser.add_subparsers(dest="command")

    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("-n", "--dry-run", action="store_true")
    common.add_argument("-v", "--verbose", action="store_true")

    apply_p = sub.add_parser("apply", parents=[common], help="Create/update symlinks from manifest")
    apply_p.add_argument("-f", "--force", action="store_true")
    apply_p.add_argument("-b", "--backup", action="store_true")
    apply_p.add_argument("-i", "--interactive", action="store_true")
    apply_p.set_defaults(func=cmd_apply)

    audit_p = sub.add_parser("audit", help="Report manifest vs filesystem drift")
    audit_p.set_defaults(func=cmd_audit)

    sync_p = sub.add_parser("sync", parents=[common], help="Init/update git submodules")
    sync_p.set_defaults(func=cmd_sync)

    bootstrap_p = sub.add_parser("bootstrap", parents=[common], help="sync + apply (new machine setup)")
    bootstrap_p.add_argument("-f", "--force", action="store_true")
    bootstrap_p.add_argument("-b", "--backup", action="store_true")
    bootstrap_p.set_defaults(func=cmd_bootstrap)

    add_p = sub.add_parser("add", help="Scaffold a new config entry")
    add_p.add_argument("name")
    add_p.add_argument(
        "--target",
        required=True,
        help="Symlink target: the tool's single native config path",
    )
    add_p.add_argument("--description", default="")
    add_p.add_argument("--optional", action="store_true")
    add_p.add_argument("-n", "--dry-run", action="store_true")
    add_p.set_defaults(func=cmd_add)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        func = args.func if hasattr(args, "func") else cmd_status
        return func(args)
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
