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


# Headings seeded once at generation and expected to diverge with real
# project content immediately -- never worth reporting as "missing" even
# though they exist in harness-core/AGENTS.md too.
_AGENTS_SECTIONS_PROJECT_OWNED = {
    "Key Invariants (do not break)",
    "Architecture",
    "Coding Rules",
    "Prohibited",
}


def extract_headings(path: str) -> list[str]:
    """Top-level ('## ') Markdown heading text, in file order."""
    if not os.path.isfile(path):
        return []
    headings = []
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            if line.startswith("## "):
                headings.append(line[3:].strip())
    return headings


def missing_agents_sections(project_dir: str, harness_core: str) -> list[str]:
    """Framework-authored AGENTS.md sections the template has that the
    project's copy doesn't. AGENTS.md is user-owned (upgrade never writes
    it), so a section added by a later framework release never reaches an
    existing project on its own -- this is advisory-only, derived from the
    template itself rather than a hand-maintained list, so it can't drift
    the way a separately-tracked list would.
    """
    template_headings = [
        h for h in extract_headings(os.path.join(harness_core, "AGENTS.md"))
        if h not in _AGENTS_SECTIONS_PROJECT_OWNED
    ]
    if not template_headings:
        return []
    project_headings = set(extract_headings(os.path.join(project_dir, "AGENTS.md")))
    return [h for h in template_headings if h not in project_headings]


def main() -> int:
    argv = sys.argv[1:]
    dry_run = "--dry-run" in argv
    verify = "--verify" in argv
    # Both are read-only (nothing written); --verify additionally always runs
    # the full per-file classification (see the early-return note below) and
    # exits non-zero if a previously-delivered file has since gone missing.
    read_only = dry_run or verify
    positional = [a for a in argv if a not in ("--dry-run", "--verify")]
    if len(positional) < 2:
        print("Usage: upgrade.py <project_dir> <script_dir> [--dry-run] [--verify]", file=sys.stderr)
        return 1
    project_dir = os.path.abspath(positional[0])
    script_dir = os.path.abspath(positional[1])
    harness_core = os.path.join(script_dir, "harness-core")

    def write_text(path: str, content: str) -> None:
        if read_only:
            return
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write(content)

    def remove_if_exists(path: str) -> None:
        if read_only:
            return
        if os.path.isfile(path):
            os.remove(path)
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
    if dry_run:
        print("Mode        : DRY RUN -- nothing will be written")
    elif verify:
        print("Mode        : VERIFY -- read-only check, nothing will be written")
    print()

    if not has_meta:
        print("! .harness-meta.json not found -- this project predates harness versioning.")
        print("! Language-specific files and any file needing {{...}} re-substitution will be skipped.")
    elif not has_baselines:
        print("! No baseline hashes recorded (project predates 1.3.0) -- files will be overwritten")
        print("! unconditionally this one run (review with git diff). Baselines will be recorded now")
        print("! so future upgrades can detect local customizations and protect them.")

    if old_version == new_version and has_meta and has_baselines and not read_only:
        print("OK: already up to date.")
        return 0
    # --dry-run/--verify never take this shortcut, even when the version
    # marker already matches -- a version string agreeing tells you nothing
    # about whether individual managed files still match their templates
    # (one could have been hand-reverted, or deleted, since the last real
    # run). Both modes always run the full per-file classification below.

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
    newly_managed: list[str] = []
    skipped: list[str] = []
    # Subset of `added` that isn't just "not delivered yet" -- these have a
    # baseline recorded (meaning a past upgrade wrote them) but the file is
    # gone from disk now, so something removed it after the fact. Drives
    # --verify's exit code; a real/dry-run report still shows these under
    # `added` as normal (self-healing on a real run is unaffected).
    missing: list[str] = []

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
            remove_if_exists(new_dst)
            continue

        if existing is None:
            write_text(dst, content)
            if has_meta:
                new_baselines[rel] = new_hash
            remove_if_exists(new_dst)
            added.append(rel)
            if has_baselines and rel in baselines:
                missing.append(rel)
            continue

        baseline_hash = baselines.get(rel) if has_baselines else None

        if baseline_hash:
            existing_hash = normalized_hash(existing)
            if existing_hash == baseline_hash:
                # Unmodified since it was installed -- safe to take the new template.
                write_text(dst, content)
                new_baselines[rel] = new_hash
                remove_if_exists(new_dst)
                updated.append(rel)
            else:
                # Project customized this file -- don't clobber it. Baseline
                # stays at the old hash so the next upgrade offers the merge again.
                write_text(new_dst, content)
                merge_needed.append(rel)
        elif has_baselines:
            # A baselines map exists (this project is on 1.3.0+ tracking) but
            # this path has no entry in it, and the file exists on disk
            # anyway -- the project authored it itself after its last
            # upgrade. The framework has no baseline to compare against, so
            # treat it like a customized file rather than assume it's safe to
            # overwrite: never clobber it, offer the template as ".new".
            write_text(new_dst, content)
            newly_managed.append(rel)
        else:
            # No baselines map at all -- a genuine pre-1.3.0 project. Fall
            # back to the old unconditional-overwrite behavior, once, same as
            # always; baseline tracking starts from here.
            write_text(dst, content)
            if has_meta:
                new_baselines[rel] = new_hash
            remove_if_exists(new_dst)
            overwritten.append(rel)

    # Always advance the version marker, even if the loop above skipped it.
    write_text(old_version_path, new_version + "\n")

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
        write_text(dst, content)
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
        write_text(meta_path, json.dumps(meta, indent=2, ensure_ascii=False) + "\n")

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
    if missing:
        print()
        print(f"! {len(missing)} of the above 'added' file(s) were previously delivered by an upgrade")
        print("! and are now missing from the project (not just pending delivery) -- possible accidental")
        print("! deletion. A real run restores them from the template:")
        for f_ in missing:
            print(f"  {f_}")
    if merge_needed:
        print()
        print(f"! {len(merge_needed)} file(s) customized locally -- left untouched, new template written as '<file>.new':")
        for f_ in merge_needed:
            print(f"  {f_}  ->  {f_}.new")
        print()
        print("! Diff each file against its '.new', merge by hand, delete the '.new', then re-run")
        print("! upgrade -- a file matching its template exactly is treated as caught up.")
    if newly_managed:
        print()
        print(f"! {len(newly_managed)} file(s) newly managed by the framework -- your existing file was kept, new template written as '<file>.new':")
        for f_ in newly_managed:
            print(f"  {f_}  ->  {f_}.new")
        print()
        print("! This path was added to harness-manifest.json after your project's last upgrade, and you already")
        print("! have a file there -- the framework can't tell if it's yours or a stale copy, so it was not")
        print("! touched. Diff each file against its '.new', merge by hand, delete the '.new', then re-run upgrade.")
    if skipped:
        print()
        print(f"! Skipped ({len(skipped)}):")
        for f_ in skipped:
            print(f"  {f_}")

    new_commands = [f_ for f_ in added if f_.startswith(".claude/commands/") and f_.endswith(".md")]
    if new_commands:
        print()
        print(f"! {len(new_commands)} new slash command(s) added -- these are user-owned to register, upgrade")
        print("! cannot edit them for you:")
        for f_ in new_commands:
            print(f"  {f_}")
        print("!   - AGENTS.md -> Workflow Prompts table")
        print("!   - CLAUDE.md -> Claude Code Extras command list")

    missing_sections = missing_agents_sections(project_dir, harness_core)
    if missing_sections:
        print()
        print(f"! {len(missing_sections)} AGENTS.md section(s) from the current template are missing from this")
        print("! project's AGENTS.md -- it's user-owned, so upgrade never writes it for you. Add by hand")
        print("! (see harness-core/AGENTS.md for the current wording), or ignore if deliberately dropped:")
        for h in missing_sections:
            print(f"  ## {h}")

    print()
    if verify:
        if missing:
            print(f"FAIL: --verify found {len(missing)} previously-delivered file(s) missing. See above.")
        else:
            print("OK: --verify found no missing files (customized/newly-managed files above are fine --")
            print("    they're a legitimate state, not a failure).")
        return 1 if missing else 0
    if dry_run:
        print("! DRY RUN -- nothing was written. Re-run without --dry-run to apply.")
    else:
        print("! Changes are NOT committed. Review with 'git diff' inside the project, then commit.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
