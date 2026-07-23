#!/usr/bin/env python3
"""Manifest-driven upgrade logic shared by upgrade.sh (Mac/Linux).

Only touches files listed in harness-core/harness-manifest.json
("frameworkOwned" + the project's "languageSpecific" set). Never touches
AGENTS.md, CLAUDE.md, README.md, HARNESS-CHANGELOG.md, .workspace/STATUS.md,
.workspace/worklog.md, .workspace/plans/*.md (except plans/README.md), or
any build-config file (eslint.config.js, tsconfig.json, pom.xml, etc.) --
those are user-owned. Changes are left uncommitted for review.

Customization safety: each managed file has a baseline hash recorded in
.harness-meta.json (written by setup.sh, advanced here). If a project's copy
of a file no longer matches its baseline, the project customized it -- this
script leaves that file alone and writes the new template as "<file>.new"
next to it for manual merge, instead of silently discarding the
customization. Projects without a baselines map (created before this
existed) fall back to the old always-overwrite behavior once, with a
warning, and gain baseline tracking from that point on.
"""
from __future__ import annotations

import datetime
import hashlib
import json
import os
import sys


def normalized_hash(text: str) -> str:
    return hashlib.sha256(text.replace("\r\n", "\n").encode("utf-8")).hexdigest()


def main() -> int:
    project_dir = os.path.abspath(sys.argv[1])
    script_dir = os.path.abspath(sys.argv[2])
    harness_core = os.path.join(script_dir, "harness-core")
    manifest_path = os.path.join(harness_core, "harness-manifest.json")

    with open(manifest_path, "r", encoding="utf-8") as f:
        manifest = json.load(f)

    meta_path = os.path.join(project_dir, ".harness-meta.json")
    has_meta = os.path.isfile(meta_path)
    meta: dict | None = None
    if has_meta:
        with open(meta_path, "r", encoding="utf-8") as f:
            meta = json.load(f)
    language = meta.get("language") if meta else None
    has_baselines = bool(has_meta and meta.get("baselines"))

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
    elif not has_baselines:
        print("! No baseline hashes recorded (project predates 1.3.0) -- files will be overwritten")
        print("! unconditionally this one run (review with git diff). Baselines will be recorded now")
        print("! so future upgrades can detect local customizations and protect them.")

    if old_version == new_version and has_meta and has_baselines:
        print("OK: already up to date.")
        return 0

    # HARNESS-VERSION is handled separately below (unconditional marker bump,
    # no baseline/customization concept applies to it).
    files_to_update = [rel for rel in manifest.get("frameworkOwned", []) if rel != "HARNESS-VERSION"]
    if language:
        files_to_update += manifest.get("languageSpecific", {}).get(language, [])
    else:
        print("! Skipping language-specific files (scripts/validate.sh, arch tests) -- language unknown.")

    lang_pack_dir = os.path.join(script_dir, "language-packs", language) if language else None
    needs_sub = manifest.get("needsSubstitution", {})
    baselines: dict = dict(meta.get("baselines", {})) if (has_meta and meta.get("baselines")) else {}
    new_baselines: dict = {}

    def resolve_source(rel: str) -> str | None:
        if lang_pack_dir:
            p = os.path.join(lang_pack_dir, rel)
            if os.path.isfile(p):
                return p
        p = os.path.join(harness_core, rel)
        if os.path.isfile(p):
            return p
        return None

    def substitute(content: str, rel: str) -> str:
        keys = needs_sub.get(rel)
        if not keys or not meta:
            return content
        for key in keys:
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
        return content

    added: list[str] = []
    updated: list[str] = []
    overwritten: list[str] = []
    merge_needed: list[str] = []
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
            content = substitute(f.read(), rel)

        dst = os.path.join(project_dir, rel)
        new_dst = dst + ".new"
        os.makedirs(os.path.dirname(dst), exist_ok=True)

        content_normalized = content.replace("\r\n", "\n")
        new_hash = normalized_hash(content)

        existing = None
        if os.path.isfile(dst):
            with open(dst, "r", encoding="utf-8") as f:
                existing = f.read()
        # Compare with CRLF normalized to LF -- a checkout with core.autocrlf=true
        # can leave working-tree files as CRLF while every template source is LF,
        # which would otherwise report a spurious change on every run.
        existing_normalized = existing.replace("\r\n", "\n") if existing is not None else None

        if existing_normalized == content_normalized:
            # Already matches the incoming template -- nothing to write.
            # Covers "never changed" and "user already hand-merged .new" alike.
            if has_meta:
                new_baselines[rel] = new_hash
            if os.path.isfile(new_dst):
                os.remove(new_dst)
            continue

        if existing is None:
            with open(dst, "w", encoding="utf-8", newline="\n") as f:
                f.write(content)
            if has_meta:
                new_baselines[rel] = new_hash
            if os.path.isfile(new_dst):
                os.remove(new_dst)
            added.append(rel)
            continue

        baseline_hash = baselines.get(rel) if has_baselines else None

        if baseline_hash:
            existing_hash = normalized_hash(existing)
            if existing_hash == baseline_hash:
                # Unmodified since it was installed -- safe to take the new template.
                with open(dst, "w", encoding="utf-8", newline="\n") as f:
                    f.write(content)
                new_baselines[rel] = new_hash
                if os.path.isfile(new_dst):
                    os.remove(new_dst)
                updated.append(rel)
            else:
                # Project customized this file -- don't clobber it. Baseline
                # stays at the old hash so the next upgrade offers the merge again.
                with open(new_dst, "w", encoding="utf-8", newline="\n") as f:
                    f.write(content)
                merge_needed.append(rel)
        else:
            # No baseline recorded for this file (pre-1.3.0 project, or the
            # file was added to the manifest after this project's baseline
            # snapshot) -- fall back to the old unconditional-overwrite
            # behavior, once.
            with open(dst, "w", encoding="utf-8", newline="\n") as f:
                f.write(content)
            if has_meta:
                new_baselines[rel] = new_hash
            if os.path.isfile(new_dst):
                os.remove(new_dst)
            overwritten.append(rel)

    # Always advance the version marker, even if the loop above skipped it.
    with open(old_version_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(new_version + "\n")

    # Bootstrap files that should exist but never overwrite an existing one.
    bootstrap_list = list(manifest.get("bootstrapIfMissing", []))
    if language:
        bootstrap_list += manifest.get("bootstrapLanguageSpecific", {}).get(language, [])

    today = datetime.date.today().isoformat()
    bootstrapped: list[str] = []
    for rel in bootstrap_list:
        dst = os.path.join(project_dir, rel)
        if os.path.isfile(dst):
            continue
        src = resolve_source(rel)
        if not src:
            skipped.append(f"{rel} (bootstrap source not found)")
            continue
        with open(src, "r", encoding="utf-8") as f:
            content = f.read()
        sub_keys = needs_sub.get(rel)
        if sub_keys:
            for key in sub_keys:
                if key == "BASE_PACKAGE":
                    value = meta.get("basePackage") if meta else None
                elif key == "DATE":
                    value = (meta.get("createdDate") if meta else None) or today
                else:
                    value = None
                if value is not None:
                    content = content.replace("{{" + key + "}}", value)
        else:
            content = content.replace("{{DATE}}", today)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        with open(dst, "w", encoding="utf-8", newline="\n") as f:
            f.write(content)
        if has_meta:
            new_baselines[rel] = normalized_hash(content)
        bootstrapped.append(rel)

    # Persist advanced baselines (existing entries survive unless replaced
    # above -- a merge-needed file's baseline intentionally stays put).
    if has_meta:
        final_baselines = dict(baselines)
        final_baselines.update(new_baselines)
        meta["baselines"] = final_baselines
        # .harness-meta.json's own harnessVersion field must track the
        # HARNESS-VERSION file written above -- otherwise the project's
        # metadata silently reports the pre-upgrade version even though the
        # file on disk (and every framework-owned file) has moved on.
        meta["harnessVersion"] = new_version
        with open(meta_path, "w", encoding="utf-8", newline="\n") as f:
            json.dump(meta, f, indent=2, ensure_ascii=False)
            f.write("\n")

    print()
    if added:
        print(f"OK: {len(added)} file(s) added:")
        for f_ in added:
            print(f"  {f_}")
    if updated:
        print(f"OK: {len(updated)} file(s) updated:")
        for f_ in updated:
            print(f"  {f_}")
    if overwritten:
        print(f"! {len(overwritten)} file(s) overwritten (no baseline recorded -- review with git diff):")
        for f_ in overwritten:
            print(f"  {f_}")
    if bootstrapped:
        print(f"OK: {len(bootstrapped)} file(s) bootstrapped (were missing):")
        for f_ in bootstrapped:
            print(f"  {f_}")
    if not (added or updated or overwritten or bootstrapped):
        print("OK: no file content changes (already current).")
    if merge_needed:
        print()
        print(f"! {len(merge_needed)} file(s) customized locally -- left untouched, new template written as '<file>.new':")
        for f_ in merge_needed:
            print(f"  {f_}  ->  {f_}.new")
        print()
        print("! Diff each file against its '.new', merge by hand, delete the '.new', then re-run")
        print("! upgrade -- a file matching its template exactly is treated as caught up.")
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
