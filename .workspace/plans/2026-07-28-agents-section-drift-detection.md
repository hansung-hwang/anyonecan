# AGENTS.md template section drift detection

- **Date**: 2026-07-28
- **Status**: Done

## Goal

Tell an existing project when the framework has **changed the body of an
`AGENTS.md` section it already has**. Today `upgrade` only detects a section
that is entirely *absent* (1.6.1's missing-section advisory); a section whose
heading matches but whose framework-authored body has moved on since the
project's last upgrade is completely silent.

## Approach

### Why this is worth building (measured, not assumed)

Counted every "heading stayed, body changed" event across the full history of
`harness-core/AGENTS.md` (10 commits touched it): **11 events, in 8 of those
10 commits.** Discounting what other mechanisms already cover:

- `Coding Rules` (1) — already excluded as project-owned.
- `Workflow Prompts` (3) — all three were new-slash-command releases, already
  covered by the existing new-command reminder.

Leaves **8 genuinely undetected events** — `Work Journal` ×4, `Steering Loop`
×2, `Handoff and Reporting` ×1, `Validation` ×1. Roughly one per release.

For comparison, the *missing-section* case that 1.6.1 built tooling for has
occurred **4 times** in the same history. **The undetected class is 2× the one
that already got tooling.** And there is a confirmed live instance, found by
hand this session: `Homographormer`'s `Work Journal` was missing a sentence
the template gained in the 1.4.0 era, and `--verify` said nothing about it.
(That specific instance was fixed by hand in `e658404`; the detection gap is
what this plan addresses.)

**n=2 bar** (this repo's own standard, used to defer `check-agent-scope` in
1.5.0 and F4 in 1.6.1): comfortably cleared. F4 was deferred at *zero*
incidents; this has 8 historical occurrences plus one live victim.

### Core design decision — hash the template, never the project

Record a hash of **each template section's body, as of the project's last
upgrade**, then compare that against the template's body *now*. The project's
own prose is never read or hashed.

This is the property that makes the feature safe. Comparing template-vs-project
body would permanently false-positive on any project that translated or
deliberately rewrote a section — `Homographormer`'s `Handoff and Reporting`
body is entirely in Korean and will never match the template. That is exactly
the recurring-noise failure mode this session just removed from the
missing-section advisory; reintroducing it in a new channel would be a
regression in disguise.

The statement the tool makes is therefore narrow and always true: *"the
framework changed this section since you last upgraded — go look."* It makes
no claim about whether the project's version is wrong.

### Storage

New key in `.harness-meta.json` (already per-project state, not manifest-owned):

```json
"agentsTemplateSections": { "Work Journal": "<sha256 of template body>", ... }
```

Reuse the existing `normalized_hash()` (CRLF/LF normalized) — this repo already
shipped a spurious-diff bug from unnormalized line endings during P2.

### Decisions — ratified 2026-07-28

1. **Per-section hashes, not one whole-file hash.** A whole-file hash is much
   cheaper but fires on project-owned section edits and `{{PLACEHOLDER}}`
   churn, and can't name *what* changed. Noise is the specific thing that
   makes an advisory get ignored.
2. **Exclusion set = the existing `_AGENTS_SECTIONS_PROJECT_OWNED`.** Do *not*
   additionally exclude `Workflow Prompts`: the new-command reminder fires on
   *file delivery*, this fires on *template text change* — overlapping but not
   identical, and excluding it leaves a silent hole if a release ever reworks
   that section's wording without adding a command. Accept the mild redundancy.
3. **First run on an existing project (no recorded hashes): record silently,
   report nothing.** "Changed since your last upgrade" is meaningless with no
   recorded last upgrade, and dumping all historical changes at once on first
   run is precisely the noise-storm that trains people to ignore the channel.
   Precedent: the pre-1.3.0 baseline fallback recorded baselines and warned
   once rather than declaring every file customized.
   - **Accepted cost, stated explicitly**: a currently-stale project
     (`Homographormer`) gets nothing on its first run and only starts being
     told from the *next* framework change onward. Considered acceptable
     because its one known drift was already fixed by hand this session.

### Version bump — **must bump to 1.7.0** (not optional, and not for cosmetic reasons)

The letter of the rule says no bump: verified against `harness-manifest.json`,
none of `upgrade.py`, `upgrade.ps1`, `upgrade.sh`, `setup.ps1`, `setup.sh`, or
`.harness-meta.json` are in `frameworkOwned` or `languageSpecific`, and
`--dry-run` (1.6.0-era) / `--verify` (1.6.1-era) both shipped bump-free on
exactly that reasoning.

**But this feature breaks the analogy, for a mechanical reason** —
`upgrade.py:143`:

```python
if old_version == new_version and has_meta and has_baselines and not read_only:
    print("OK: already up to date.")
    return 0
```

A plain (write-mode) run **returns before doing anything** when the project's
`HARNESS-VERSION` already equals the framework's. Recording the section hashes
requires a write-mode run. So without a bump:

- Every already-current project (**including `Homographormer`, now at 1.6.1**)
  hits the early return and never records a baseline — the feature is inert for
  precisely the projects it was built for.
- `--dry-run`/`--verify` skip that early return (1.6.1 fixed that), so they'd
  reach the new code — but they're read-only by contract and must not write
  `.harness-meta.json`, so they can't establish the baseline either.
- Net effect: the code ships dormant and only wakes up whenever some *future*
  release happens to bump the version for an unrelated reason.

`--dry-run` and `--verify` never had this problem because they are flags the
user passes explicitly and both deliberately bypass the early return. This
feature needs write-mode execution, so it collides with the fast-path in a way
neither precedent did.

**Conclusion**: bump `harness-core/HARNESS-VERSION` to **1.7.0** (minor — new
capability, no breaking manifest change), plus the `FRAMEWORK-CHANGELOG.md`
entry. This is a correctness requirement for the feature to function, not a
visibility preference.

## Checklist

- [x] **S0 — design decisions closed 2026-07-28.** Decisions 1-3 ratified as
      recommended. Version-bump question resolved to **bump to 1.7.0** after
      finding the `upgrade.py:143` early-return would otherwise leave the
      feature inert on already-current projects (see Version bump above) —
      the initial "no bump required" reading was correct on the rule but
      wrong on the mechanics.
- [x] **S1 — `upgrade.py`**: added `extract_sections()` and
      `changed_agents_template_sections()`; compares against
      `.harness-meta.json`'s `agentsTemplateSections`, reports changed
      sections, persists refreshed hashes only inside the existing
      `if has_meta:` write block (which `write_text()` already no-ops under
      `--dry-run`/`--verify` — no separate gating needed).
- [x] **S2 — `upgrade.ps1` parity**: added `Get-Sections`/
      `Get-ChangedAgentsTemplateSections`, wired the same way. `upgrade.sh`
      confirmed to delegate entirely to `upgrade.py` — no change needed.
- [x] **S3 — `setup.ps1`/`setup.sh`**: both record `agentsTemplateSections`
      at generation time. **Parity verified for real by running both**, not
      assumed — generated one project with each against the same 1.7.0
      template and compared the recorded maps: identical hashes, identical
      key set, identical key order. `upgrade.py --verify` against the
      `setup.sh`-generated project also reports clean, confirming the two
      sides agree end-to-end.
      - *Audit correction (post-implementation)*: this box was first marked
        done when only `setup.ps1` had actually been run — `setup.sh` was
        inferred from code review, exactly what this checklist item said not
        to do ("the 1.6.0 work found real `setup.sh`/`setup.ps1` parity
        issues, so this is not assumed"). Caught by auditing the plan
        against reality rather than re-reading it; `setup.sh` was then run
        for real and parity confirmed. The claim now matches what was done.
- [x] **S4 — verified against real projects and real generation, not
      simulation**:
      (a) a project generated fresh via `setup.ps1` — **initially reported 5
      sections "changed" seconds after being generated from the exact
      template it was stamped from.** Real bug, not a test artifact — see
      "Real bug found" below. Fixed, then reverified: zero changed/missing
      sections.
      (b) break-test: mutated `harness-core/AGENTS.md`'s `Steering Loop`
      body directly (temporary edit, `git checkout`'d back after each test),
      confirmed both `upgrade.py --verify` and `upgrade.ps1 -Verify`
      correctly named exactly that one section and nothing else.
      (c) confirmed via file diff that `--dry-run` and a real no-flag run
      with matching versions (the pre-1.7.0 early-return case) both write
      nothing to `.harness-meta.json`.
      (d) ran the real 1.6.1→1.7.0 upgrade against `Homographormer`
      (commit `3783e12`, branch `chore/harness-upgrade-1.7.0`, forked from
      `chore/harness-upgrade-1.6.1`'s tip since that branch is also
      deliberately unmerged): `agentsTemplateSections` recorded for all 6
      tracked sections, first-run-silent confirmed (nothing reported),
      `--verify` clean afterward, full `validate.sh` (mypy/ruff/pytest
      14/14) passing.
- [x] **S5 — docs + version**: `harness-core/HARNESS-VERSION` bumped to
      1.7.0; `FRAMEWORK-CHANGELOG.md` gained a full `## [1.7.0]` entry
      (not a dated "Tooling" one); `README.md`'s "two things you own"
      passage (was line 176) now states three cases, and the upgrade-output
      table gained the new advisory row.
- [x] All projects used for break-testing (`harness-core/AGENTS.md` itself,
      twice) confirmed restored via `git status` after each mutation; the
      scratch test-generation project and its `__pycache__` byproduct
      deleted after use.

### Real bug found during S4, not anticipated in the design

**PowerShell's `Get-Content` defaults to the system's active codepage, not
UTF-8.** On this box (Korean codepage), that silently mangled the em-dashes
in `harness-core/AGENTS.md`'s prose into `?` before hashing — so
`setup.ps1`'s recorded hash and `upgrade.py`'s computed hash for the *same*
unmodified section differed, and a project generated one second earlier
already showed 5 false "changed" sections. Root-caused by dumping both
scripts' extracted body bytes to files and diffing them, not by inspection.

Fixed by adding `-Encoding UTF8` to every `Get-Content` call in
`upgrade.ps1`/`setup.ps1` that reads UTF-8 template/project content — not
just the two I'd just written. This incidentally fixes a **pre-existing,
independent bug from 1.6.1**: `Get-Headings` (the missing-section check's own
reader, used by `upgrade.ps1` since 1.6.1) had the identical gap, and
`upgrade.ps1`'s read of `.harness-meta.json` itself (line ~167) was reading
`commentLanguage` values like `"한국어 (Korean)"` through the same unencoded
path and re-writing them corrupted on every real `upgrade.ps1` run against a
non-English project. Neither had been exercised before because every prior
verification of that code used ASCII English content. Re-verified after the
fix: fresh generation reports clean, both break-tests correctly name the
mutated section, real `Homographormer` run clean.

## Notes

- **Direct predecessor**: `.workspace/plans/2026-07-27-upgrade-feedback-from-eacc-1.6.0.md`,
  which built the missing-section advisory. That plan explicitly accepted the
  *renamed-heading* false positive as a known limitation but did **not**
  anticipate the body-drift gap — this plan is new territory, not a revisit.
- **Sibling work completed 2026-07-28 (same session, already committed/staged)**:
  the advisory's wording now states that matching is by exact heading text, so a
  translated heading showing up is explained rather than mysterious; and
  `Homographormer`'s `AGENTS.md` gained `File Ownership`, an English
  `Handoff and Reporting` heading, and the missing `Work Journal` sentence.
- **Deliberately still deferred**: the `.harness-meta.json` **alias map** for
  translated headings (`agentsSectionAliases`). One confirmed occurrence
  (`Homographormer`), so it stays behind the same n=2 bar. Note that if it is
  ever built, it interacts with this feature: an alias map would let the
  drift check follow a renamed heading too. Worth designing so the two don't
  collide, but not worth building now.
- **Open question for S0, not yet resolved**: what to do when a template
  section is *removed* entirely (heading disappears from the template). It has
  never happened, so this may be the same class as F4's retired-path handling —
  likely correct to leave unhandled rather than guess.
