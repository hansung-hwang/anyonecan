#!/usr/bin/env python3
"""Manifest-driven upgrade logic shared by upgrade.sh (Mac/Linux).

Only overwrites files listed in harness-core/harness-manifest.json
("frameworkOwned" + the project's "languageSpecific" set). Never touches
AGENTS.md, CLAUDE.md, README.md, HARNESS-CHANGELOG.md, .workspace/STATUS.md,
.workspace/worklog.md, .workspace/plans/*.md (except plans/README.md), or
any build-config file (eslint.config.js, tsconfig.json, pom.xml, etc.) --
those are user-owned. Changes are left uncommitted for review.
"""
from __future__ import annotations

import datetime
import json
import os
import sys


def main() -> int:
    project_dir = os.path.abspath(sys.argv[1])
    script_dir = os.path.abspath(sys.argv[2])
    harness_core = os.path.join(script_dir, "harness-core")
    manifest_path = os.path.join(harness_core, "harness-manifest.json")

    with open(manifest_path, "r", encoding="utf-8") as f:
        manifest = json.load(f)

    meta_path = os.path.join(project_dir, ".harness-meta.json")
    has_meta = os.path.isfile(meta_path)
    meta = None
    if has_meta:
        with open(meta_path, "r", encoding="utf-8") as f:
            meta = json.load(f)
    language = meta.get("language") if meta else None

    old_version_path = os.path.join(project_dir, "HARNESS-VERSION")
    if os.path.isfile(old_version_path):
        with open(old_version_path, encoding="utf-8") as f:
            old_version = f.read().strip()
    else:
        old_version = "unknown (pre-versioning)"
    with open(os.path.join(harness_core, "HARNESS-VERSION"), encoding="utf-8") as f:
        new_version = f.read().strip()

    print(f"Project     : {project_dir}")
    print(f"Old version : {old_version}")
    print(f"New version : {new_version}")
    print(f"Language    : {language or 'unknown (no .harness-meta.json)'}")
    print()

    if not has_meta:
        print("! .harness-meta.json not found -- this project predates harness versioning.")
        print("! Language-specific files and any file needing {{...}} re-substitution will be skipped.")

    if old_version == new_version and has_meta:
        print("OK: already up to date.")
        return 0

    files_to_update = list(manifest.get("frameworkOwned", []))
    if language:
        files_to_update += manifest.get("languageSpecific", {}).get(language, [])
    else:
        print("! Skipping language-specific files (scripts/validate.sh, arch tests) -- language unknown.")

    lang_pack_dir = os.path.join(script_dir, "language-packs", language) if language else None
    needs_sub = manifest.get("needsSubstitution", {})

    def resolve_source(rel: str) -> str | None:
        if lang_pack_dir:
            p = os.path.join(lang_pack_dir, rel)
            if os.path.isfile(p):
                return p
        p = os.path.join(harness_core, rel)
        if os.path.isfile(p):
            return p
        return None

    changed: list[str] = []
    skipped: list[str] = []

    for rel in files_to_update:
        src = resolve_source(rel)
        if not src:
            skipped.append(f"{rel} (no source found in harness-core or language pack)")
            continue
        sub_keys = needs_sub.get(rel)
        if sub_keys and not meta:
            skipped.append(f"{rel} (needs {{...}} substitution but no .harness-meta.json)")
            continue
        with open(src, "r", encoding="utf-8") as f:
            content = f.read()
        if sub_keys:
            for key in sub_keys:
                # DATE uses the project's original creation date (from
                # .harness-meta.json), not today's date -- an ADR records when
                # the decision was made, not when the framework was upgraded.
                if key == "BASE_PACKAGE":
                    value = meta.get("basePackage")
                elif key == "DATE":
                    value = meta.get("createdDate")
                else:
                    value = None
                if value is not None:
                    content = content.replace("{{" + key + "}}", value)
        dst = os.path.join(project_dir, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        existing = None
        if os.path.isfile(dst):
            with open(dst, "r", encoding="utf-8") as f:
                existing = f.read()
        # Compare with CRLF normalized to LF -- a checkout with core.autocrlf=true
        # can leave working-tree files as CRLF while every template source is LF,
        # which would otherwise report a spurious change on every run.
        existing_normalized = existing.replace("\r\n", "\n") if existing is not None else None
        content_normalized = content.replace("\r\n", "\n")
        if existing_normalized != content_normalized:
            with open(dst, "w", encoding="utf-8", newline="\n") as f:
                f.write(content)
            changed.append(rel)

    # Always advance the version marker, even if the loop above skipped it.
    with open(old_version_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(new_version + "\n")
    if "HARNESS-VERSION" not in changed:
        changed.append("HARNESS-VERSION")

    # Bootstrap files that should exist but never overwrite an existing one.
    today = datetime.date.today().isoformat()
    for rel in manifest.get("bootstrapIfMissing", []):
        dst = os.path.join(project_dir, rel)
        if os.path.isfile(dst):
            continue
        src = resolve_source(rel)
        if not src:
            skipped.append(f"{rel} (bootstrap source not found)")
            continue
        with open(src, "r", encoding="utf-8") as f:
            content = f.read()
        content = content.replace("{{DATE}}", today)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        with open(dst, "w", encoding="utf-8", newline="\n") as f:
            f.write(content)
        changed.append(f"{rel} (bootstrapped)")

    print()
    if changed:
        print(f"OK: {len(changed)} file(s) updated:")
        for f_ in changed:
            print(f"  {f_}")
    else:
        print("OK: no file content changes (already current).")
    if skipped:
        print()
        print(f"! Skipped ({len(skipped)}):")
        for f_ in skipped:
            print(f"  {f_}")

    print()
    print("! Changes are NOT committed. Review with 'git diff' inside the project, then commit.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
