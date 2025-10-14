#!/usr/bin/env python3
from __future__ import annotations
import argparse
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

# D = Dollarsign. CS = Curly bracket Start. CX = Touchstone Placeholder CX. CE = Curly bracket End.
REPLACEMENTS = {
    "D-CS-C1-CE": "${C1}",
    "D-CS-C2-CE": "${C2}",
    "D-CS-C3-CE": "${C3}",
    "D-CS-C4-CE": "${C4}",
    "D-CS-C5-CE": "${C5}",
    "D-CS-C6-CE": "${C6}",
    "D-CS-C7-CE": "${C7}",
    "D-CS-C8-CE": "${C8}",
    "D-CS-C9-CE": "${C9}",
    "D-CS-C10-CE": "${C10}",
    "D-CS-C11-CE": "${C11}",
    "D-CS-C12-CE": "${C12}",
    "D-CS-C13-CE": "${C13}",
    "D-CS-C14-CE": "${C14}",
    "D-CS-C15-CE": "${C15}",
    "D-CS-C16-CE": "${C16}",
    "D-CS-C17-CE": "${C17}",
    "D-CS-C18-CE": "${C18}",
    "D-CS-C19-CE": "${C19}",
    "D-CS-C20-CE": "${C20}",
    "1970-01-01T00:00:00.000+02:00": "${CURRENTDATETIME}",
}

DEFAULT_GENERATED_ROOT = Path("fsh-generated") / "resources"
DEFAULT_TARGET_STR = r"C:\Users\OLW\workspace-ts-ide\FHIRSandbox\EHMIEndpointRegistry"


def resolve_target_path(target_str: str) -> Path:
    """
    Return a usable absolute Path for the target directory.
    - On Windows, 'C:\\...' is already absolute.
    - On POSIX (macOS/Linux), if a Windows-style path is provided, try a WSL mapping:
      'C:\\Users\\...' -> '/mnt/c/Users/...'. If that doesn't exist, error out.
    """
    # If we're on Windows, just use it
    if os.name == "nt":
        return Path(target_str).absolute()

    # POSIX: detect Windows-style path like 'C:\...' or 'C:/...'
    m = re.match(r"^([A-Za-z]):[\\/](.*)$", target_str)
    if m:
        drive, rest = m.groups()
        wsl_path = Path("/mnt") / drive.lower() / Path(rest.replace("\\", "/"))
        if not wsl_path.exists():
            print(
                "❌ Target looks like a Windows path but this system is not Windows and "
                f"WSL mount not found: {wsl_path}\n"
                "   - If you're in WSL, ensure the drive is mounted (e.g., /mnt/c).\n"
                "   - Otherwise, pass a valid POSIX path via --target."
            )
            sys.exit(1)
        return wsl_path.resolve()

    # Otherwise, treat as normal POSIX path
    p = Path(target_str)
    # Make it absolute relative to cwd
    return p.resolve()


def run_sushi(skip: bool, dry_run: bool) -> None:
    if skip:
        print("⏭️  Skipping `sushi .` (per --skip-sushi).")
        return
    if dry_run:
        print("🧪 Would run: sushi .")
        return
    print("🍣 Running `sushi .` ...")
    try:
        proc = subprocess.run(["sushi", "."], check=True, capture_output=True, text=True)
        if proc.stdout:
            print(proc.stdout.strip())
        if proc.stderr:
            print(proc.stderr.strip())
        print("✅ sushi finished successfully.")
    except FileNotFoundError:
        print("❌ `sushi` command not found. Is Sushi in your PATH?")
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print("❌ `sushi .` failed:")
        if e.stdout:
            print(e.stdout)
        if e.stderr:
            print(e.stderr)
        sys.exit(e.returncode or 1)


def process_file(fp: Path, dry_run: bool, backup: bool) -> dict[str, int] | None:
    try:
        text = fp.read_text(encoding="utf-8")
    except Exception as e:
        print(f"⚠️  Skipping {fp} (read error: {e})")
        return None

    counts: dict[str, int] = {}
    updated = text
    for old, new in REPLACEMENTS.items():
        c = updated.count(old)
        if c:
            counts[old] = c
            updated = updated.replace(old, new)

    if not counts:
        return {}

    if not dry_run:
        try:
            if backup:
                bak = fp.with_suffix(fp.suffix + ".bak")
                bak.write_text(text, encoding="utf-8")
            fp.write_text(updated, encoding="utf-8")
        except Exception as e:
            print(f"❌ Failed to write {fp}: {e}")
            return None

    return counts


def bulk_replace(root: Path, recursive: bool, dry_run: bool, backup: bool) -> int:
    if not root.exists():
        print(f"❌ Directory not found: {root.resolve()}")
        return -1

    pattern = "*.json"
    files = (root.glob(pattern) if not recursive else root.rglob(pattern))

    total_files_changed = 0
    total_counts = {k: 0 for k in REPLACEMENTS.keys()}

    for fp in files:
        result = process_file(fp, dry_run=dry_run, backup=backup)
        if result is None:
            continue
        if result:
            total_files_changed += 1
            pretty = ", ".join([f"{k}×{v}" for k, v in result.items()])
            print(f"✅ {fp}: {pretty}")
            for k, v in result.items():
                total_counts[k] += v

    if total_files_changed == 0:
        print("ℹ️  No replacements needed.")
    else:
        print("\n— Replacement Summary —")
        for k, v in total_counts.items():
            print(f"{k} → {REPLACEMENTS[k]} : {v} replacement(s)")
        print(f"Files changed: {total_files_changed}")
        if dry_run:
            print("Dry run only — no files were written.")
        else:
            print("Backups saved with .bak suffix." if backup else "")

    return total_files_changed


def move_fixture_jsons(resources_dir: Path, dry_run: bool) -> None:
    fixtures_dir = resources_dir / "Fixtures"
    if dry_run:
        print(f"🧪 Would ensure directory exists: {fixtures_dir}")
    else:
        fixtures_dir.mkdir(parents=True, exist_ok=True)

    moved = 0
    for fp in resources_dir.glob("*.json"):
        if fp.stem.endswith("Fixture"):
            dest = fixtures_dir / fp.name
            if dry_run:
                print(f"🧪 Would move Fixture JSON: {fp} -> {dest}")
            else:
                try:
                    if dest.exists():
                        dest.unlink()
                    shutil.move(str(fp), str(dest))
                    moved += 1
                except Exception as e:
                    print(f"❌ Failed to move {fp} -> {dest}: {e}")

    print(f"📦 Fixture JSONs moved: {moved}" + (" (dry-run)" if dry_run else ""))


def merge_move(src: Path, dst: Path, dry_run: bool) -> None:
    """
    Move files/dirs from src into dst, overwriting/merging as needed.
    Skips anything whose name starts with 'ImplementationGuide'.
    """
    if dry_run:
        print(f"🧪 Would ensure target directory exists: {dst}")
    else:
        dst.mkdir(parents=True, exist_ok=True)

    for item in src.iterdir():
        name = item.name
        if name.startswith("ImplementationGuide"):
            print(f"⤴️  Skipping (per rule): {item}")
            continue

        target = dst / name
        if item.is_file():
            if dry_run:
                print(f"🧪 Would move file: {item} -> {target} (overwrite if exists)")
            else:
                try:
                    target.parent.mkdir(parents=True, exist_ok=True)
                    if target.exists():
                        target.unlink()
                    shutil.move(str(item), str(target))
                except Exception as e:
                    print(f"❌ Failed to move file {item} -> {target}: {e}")
        elif item.is_dir():
            if dry_run:
                print(f"🧪 Would merge/move directory: {item} -> {target} (overwrite contents)")
            else:
                try:
                    if target.exists() and not target.is_dir():
                        target.unlink()
                    shutil.copytree(item, target, dirs_exist_ok=True)
                    shutil.rmtree(item)
                except Exception as e:
                    print(f"❌ Failed to merge/move dir {item} -> {target}: {e}")
        else:
            print(f"⚠️  Skipping non-file: {item}")


def main():
    p = argparse.ArgumentParser(
        description="Run sushi, apply replacements, organize Fixtures, and move resources."
    )
    p.add_argument(
        "--resources",
        default=str(DEFAULT_GENERATED_ROOT),
        help="Path to fsh-generated/resources (default: fsh-generated/resources)",
    )
    p.add_argument(
        "--target",
        default=DEFAULT_TARGET_STR,
        help=r"Destination folder to receive generated resources "
             r'(default: C:\Users\OLW\workspace-ts-ide\FHIRSandbox\EHMIEndpointRegistry)',
    )
    p.add_argument(
        "--non-recursive",
        action="store_true",
        help="Only replace in the top of --resources (no subfolders).",
    )
    p.add_argument("--dry-run", action="store_true", help="Show actions, do not modify files.")
    p.add_argument("--backup", action="store_true", help="Save a .bak copy before writing.")
    p.add_argument("--skip-sushi", action="store_true", help="Do not run `sushi .` first.")
    args = p.parse_args()

    # 1) Run sushi
    run_sushi(skip=args.skip_sushi, dry_run=args.dry_run)

    resources_dir = Path(args.resources).resolve()
    target_dir = resolve_target_path(args.target)

    # 2) Apply replacements to JSON under fsh-generated/resources
    print(f"🛠️  Applying replacements in: {resources_dir}")
    rep_status = bulk_replace(
        root=resources_dir,
        recursive=not args.non_recursive,
        dry_run=args.dry_run,
        backup=args.backup,
    )
    if rep_status == -1:
        sys.exit(1)

    # 3) Move *Fixture.json into .../Fixtures
    print("🗂️  Organizing Fixture JSONs...")
    move_fixture_jsons(resources_dir, dry_run=args.dry_run)

    # 4) Move/Merge everything from resources into target, overwriting
    print(f"🚚 Moving generated resources to target (overwrite): {target_dir}")
    merge_move(resources_dir, target_dir, dry_run=args.dry_run)

    print("🎉 Done." + (" (dry-run: no changes were made)" if args.dry_run else ""))


if __name__ == "__main__":
    main()
