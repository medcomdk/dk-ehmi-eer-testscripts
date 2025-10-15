#!/usr/bin/env python3
from __future__ import annotations
import argparse
import os
import re
import shutil
import subprocess
import sys
import json
from pathlib import Path
from collections import Counter, defaultdict
from typing import Any, Union

import xml.etree.ElementTree as ET
from xml.dom import minidom

DEFAULT_GENERATED_ROOT = Path("fsh-generated") / "resources"
DEFAULT_TARGET_STR = r"C:\Users\OLW\workspace-ts-ide\FHIRSandbox\EHMIEndpointRegistry"

# Match "TouchstoneHelper-DS-CBS-<WILDCARD>-CBE" and capture <WILDCARD>
_WILDCARD_RX = re.compile(r"TouchstoneHelper-DS-CBS-([A-Za-z][A-Za-z0-9_]*)-CBE")

# For filenames: allow letters, digits, dash, underscore, dot. Replace others with underscore.
_SANITIZE_NAME_RX = re.compile(r"[^A-Za-z0-9._-]+")

# FHIR XML namespaces
FHIR_NS = "http://hl7.org/fhir"
XHTML_NS = "http://www.w3.org/1999/xhtml"
ET.register_namespace("", FHIR_NS)
ET.register_namespace("xhtml", XHTML_NS)

def resolve_target_path(target_str: str) -> Path:
    if os.name == "nt":
        return Path(target_str).absolute()

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

    return Path(target_str).resolve()


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


def transform_wildcards(text: str) -> tuple[str, list[tuple[str, str]]]:
    """
    Replace every 'TouchstoneHelper-DS-CBS-<WILDCARD>-CBE' with '${<WILDCARD>}'.
    Returns (updated_text, list_of_(from,to)_pairs_per_occurrence).
    """
    pairs: list[tuple[str, str]] = []

    def _repl(m: re.Match) -> str:
        wildcard = m.group(1)
        old = m.group(0)
        new = f"${{{wildcard}}}"
        pairs.append((old, new))
        return new

    updated = _WILDCARD_RX.sub(_repl, text)
    return updated, pairs


def _extract_filename_override(parsed_json: dict) -> str | None:
    """
    Find meta.tag entry with id == 'TouchstoneHelperFileNameOverride' and return its display.
    """
    try:
        tags = parsed_json.get("meta", {}).get("tag", [])
        if isinstance(tags, list):
            for tag in tags:
                if isinstance(tag, dict) and tag.get("id") == "TouchstoneHelperFileNameOverride":
                    disp = tag.get("display")
                    if isinstance(disp, str) and disp.strip():
                        return disp.strip()
    except Exception:
        pass
    return None


def _remove_filename_override_tag(parsed_json: dict) -> bool:
    """
    Remove the meta.tag object(s) where id == 'TouchstoneHelperFileNameOverride'.
    Returns True if any removal occurred.
    """
    meta = parsed_json.get("meta")
    if not isinstance(meta, dict):
        return False

    tags = meta.get("tag")
    if not isinstance(tags, list):
        return False

    new_tags = [
        t for t in tags
        if not (isinstance(t, dict) and t.get("id") == "TouchstoneHelperFileNameOverride")
    ]

    if new_tags == tags:
        return False

    if new_tags:
        meta["tag"] = new_tags
    else:
        # If the tag array is now empty, drop it entirely
        try:
            del meta["tag"]
        except Exception:
            pass
        # If meta becomes empty, you could optionally remove meta too.
        if not meta:
            try:
                del parsed_json["meta"]
            except Exception:
                pass

    return True


def _sanitize_filename(stem: str) -> str:
    clean = _SANITIZE_NAME_RX.sub("_", stem).strip("._-")
    return clean or "renamed"


def process_file(fp: Path, dry_run: bool, backup: bool) -> dict | None:
    """
    Returns:
      {
        "pairs": list[(old,new)],
        "renamed_from": str | None,
        "renamed_to": str | None,
        "removed_override_tag": bool
      }
    """
    try:
        text = fp.read_text(encoding="utf-8")
    except Exception as e:
        print(f"⚠️  Skipping {fp} (read error: {e})")
        return None

    # Do wildcard replacements
    updated_text, pairs = transform_wildcards(text)

    # Try to parse JSON (after replacement is fine, the value types are still strings)
    rename_from = None
    rename_to = None
    removed_override_tag = False
    try:
        parsed = json.loads(updated_text)

        # 1) Decide on rename BEFORE removing the tag
        override = _extract_filename_override(parsed)
        if override:
            sanitized = _sanitize_filename(override)
            # Preserve original extension
            new_name = f"{sanitized}{fp.suffix or '.json'}"
            if fp.name != new_name:
                rename_from = fp.name
                rename_to = new_name

        # 2) Remove the override tag from the JSON
        removed_override_tag = _remove_filename_override_tag(parsed)
        if removed_override_tag:
            # Re-serialize with pretty formatting
            updated_text = json.dumps(parsed, ensure_ascii=False, indent=2)
            if not updated_text.endswith("\n"):
                updated_text += "\n"

    except Exception:
        # If parsing fails, we still proceed with text replacements,
        # but cannot rename by meta tag or remove it.
        pass

    # Only write if there are changes (content or rename)
    content_changed = (updated_text != text)
    if content_changed or rename_to:
        if not dry_run:
            try:
                if backup and content_changed:
                    bak = fp.with_suffix(fp.suffix + ".bak")
                    bak.write_text(text, encoding="utf-8")
                # Write updated content if changed
                if content_changed:
                    fp.write_text(updated_text, encoding="utf-8")
                # Perform rename if needed
                if rename_to:
                    target = fp.with_name(rename_to)
                    # If destination exists, overwrite it for determinism
                    if target.exists():
                        target.unlink()
                    fp.rename(target)
                    fp = target  # update fp so later steps would see the new name if returned
            except Exception as e:
                print(f"❌ Failed to update/rename {fp}: {e}")
                return None

    return {
        "pairs": pairs,
        "renamed_from": rename_from,
        "renamed_to": rename_to,
        "removed_override_tag": removed_override_tag,
    }


def bulk_replace(root: Path, recursive: bool, dry_run: bool, backup: bool) -> int:
    if not root.exists():
        print(f"❌ Directory not found: {root.resolve()}")
        return -1

    pattern = "*.json"
    files = (root.glob(pattern) if not recursive else root.rglob(pattern))

    total_files_changed = 0
    overall_counter: Counter[tuple[str, str]] = Counter()
    renames_overall: list[tuple[str, str, str]] = []  # (dir, old, new)

    for fp in files:
        result = process_file(fp, dry_run=dry_run, backup=backup)
        if result is None:
            continue
        pairs = result["pairs"]
        rename_from = result["renamed_from"]
        rename_to = result["renamed_to"]
        removed_override_tag = result.get("removed_override_tag", False)

        if pairs or rename_to or removed_override_tag:
            total_files_changed += 1

            # Per-file aggregation (unique pair -> count)
            file_counter = Counter(pairs)
            overall_counter.update(file_counter)

            print(f"✅ {fp.parent / (rename_to or fp.name)}:")
            for (old, new), cnt in file_counter.items():
                print(f"   • {old} → {new}  ×{cnt}")
            if rename_to:
                renames_overall.append((str(fp.parent), rename_from, rename_to))
                print(f"   • Rename: {rename_from} → {rename_to}")
            if removed_override_tag:
                print("   • Removed meta.tag 'TouchstoneHelperFileNameOverride'")

    if total_files_changed == 0:
        print("ℹ️  No replacements or renames needed.")
    else:
        print("\n— Replacement Summary (overall) —")
        total_repls = 0
        by_to: dict[str, Counter[str]] = defaultdict(Counter)
        for (old, new), cnt in overall_counter.items():
            by_to[new][old] += cnt
            total_repls += cnt

        for new, olds_counter in by_to.items():
            for old, cnt in olds_counter.items():
                print(f"{old} → {new} : {cnt} replacement(s)")

        print(f"Total replacements: {total_repls}")

        if renames_overall:
            print("\n— Rename Summary —")
            for d, old, new in renames_overall:
                print(f"{d}{os.sep}{old} → {new}")

        print(f"Files changed: {total_files_changed}")
        if dry_run:
            print("Dry run only — no files were written or renamed.")
        else:
            print("Backups saved with .bak suffix for content edits." if backup else "")

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

# ---------------------------
# FHIR JSON → XML conversion
# ---------------------------

_PRIMITIVE_TYPES = {
    "base64Binary","boolean","canonical","code","date","dateTime","decimal","id","instant",
    "integer","markdown","oid","positiveInt","string","time","unsignedInt","uri","url","uuid"
}

def _is_primitive_element(name: str, value: Any) -> bool:
    # Heuristic: FHIR primitive elements are leaf values (str/int/float/bool or {"value":...})
    return isinstance(value, (str, int, float, bool)) or (isinstance(value, dict) and "value" in value)

def _set_primitive(el: ET.Element, value: Any) -> None:
    # In FHIR XML, primitive value goes in @value
    if isinstance(value, dict) and "value" in value and len(value) == 1:
        val = value["value"]
    else:
        val = value
    el.set("value", str(val))

def _append_child(parent: ET.Element, name: str) -> ET.Element:
    return ET.SubElement(parent, f"{{{FHIR_NS}}}{name}")

def _serialize_element(parent: ET.Element, name: str, value: Any) -> None:
    # Arrays -> repeated elements
    if isinstance(value, list):
        for item in value:
            _serialize_element(parent, name, item)
        return

    el = _append_child(parent, name)

    # Primitive leaf?
    if _is_primitive_element(name, value):
        _set_primitive(el, value if not isinstance(value, dict) else value.get("value"))
        return

    # Complex object
    if isinstance(value, dict):
        for k, v in value.items():
            if v is None:
                continue
            # Special case: Narrative.text.div is XHTML that should be embedded as XML, not string
            if name == "text" and k == "div" and isinstance(v, str) and v.strip().startswith("<"):
                try:
                    # Parse XHTML fragment and graft with xhtml ns
                    div_el = ET.fromstring(v)
                    # Ensure namespace is XHTML
                    if not div_el.tag.startswith("{"):
                        div_el.tag = f"{{{XHTML_NS}}}{div_el.tag}"
                    el.append(div_el)
                except Exception:
                    # If parsing fails, fall back to a literal child with value attr
                    div = _append_child(el, "div")
                    div.set("value", v)
                continue
            _serialize_element(el, k, v)
        return

    # Otherwise (shouldn't happen often), coerce to primitive
    _set_primitive(el, value)

def json_resource_to_xml_tree(obj: dict) -> ET.ElementTree:
    if not isinstance(obj, dict) or "resourceType" not in obj:
        raise ValueError("Not a valid FHIR resource JSON: missing 'resourceType'")
    root_name = obj["resourceType"]
    root = ET.Element(f"{{{FHIR_NS}}}{root_name}")
    for key, val in obj.items():
        if key == "resourceType" or val is None:
            continue
        _serialize_element(root, key, val)
    return ET.ElementTree(root)

def write_pretty_xml(tree: ET.ElementTree, out_path: Path) -> None:
    rough = ET.tostring(tree.getroot(), encoding="utf-8", xml_declaration=True)
    # Pretty print without changing content
    parsed = minidom.parseString(rough)
    with out_path.open("wb") as f:
        f.write(parsed.toprettyxml(indent="  ", encoding="utf-8"))

def convert_fixtures_to_xml(fixtures_dir: Path, dry_run: bool) -> int:
    """
    For each *.json in fixtures_dir, write a sibling *.xml with equivalent FHIR XML.
    Returns count of XML files written.
    """
    if not fixtures_dir.exists():
        print(f"ℹ️  Fixtures directory not found (skipping XML conversion): {fixtures_dir}")
        return 0

    written = 0
    for jf in sorted(fixtures_dir.glob("*.json")):
        xf = jf.with_suffix(".xml")
        if dry_run:
            print(f"🧪 Would convert fixture to XML: {jf.name} -> {xf.name}")
            written += 1
            continue

        try:
            data = json.loads(jf.read_text(encoding="utf-8"))
            tree = json_resource_to_xml_tree(data)
            write_pretty_xml(tree, xf)
            print(f"🗜️  Converted to XML: {jf.name} -> {xf.name}")
            written += 1
        except Exception as e:
            print(f"❌ Failed to convert {jf.name} to XML: {e}")

    print(f"🧾 XML files created: {written}" + (" (dry-run)" if dry_run else ""))
    return written

def main():
    p = argparse.ArgumentParser(
        description="Run sushi, apply wildcard replacements, rename by TouchstoneHelperFileNameOverride, remove its meta.tag entry, organize Fixtures, move resources, and convert Fixtures to XML."
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
    p.add_argument("--skip-xml", action="store_true", help="Skip converting Fixtures JSON to XML.")
    args = p.parse_args()

    run_sushi(skip=args.skip_sushi, dry_run=args.dry_run)

    resources_dir = Path(args.resources).resolve()
    target_dir = resolve_target_path(args.target)

    print(f"🛠️  Applying replacements & filename overrides in: {resources_dir}")
    rep_status = bulk_replace(
        root=resources_dir,
        recursive=not args.non_recursive,
        dry_run=args.dry_run,
        backup=args.backup,
    )
    if rep_status == -1:
        sys.exit(1)

    print("🗂️  Organizing Fixture JSONs...")
    move_fixture_jsons(resources_dir, dry_run=args.dry_run)

    print(f"🚚 Moving generated resources to target (overwrite): {target_dir}")
    merge_move(resources_dir, target_dir, dry_run=args.dry_run)

    # NEW: Convert Fixtures JSON → XML in the TARGET so copies land next to the moved files
    if not args.skip_xml:
        fixtures_target = target_dir / "Fixtures"
        print(f"🔄 Converting Fixtures to XML in: {fixtures_target}")
        convert_fixtures_to_xml(fixtures_target, dry_run=args.dry_run)
    else:
        print("⏭️  Skipping XML conversion (per --skip-xml).")

    print("🎉 Done." + (" (dry-run: no changes were made)" if args.dry_run else ""))


if __name__ == "__main__":
    main()
