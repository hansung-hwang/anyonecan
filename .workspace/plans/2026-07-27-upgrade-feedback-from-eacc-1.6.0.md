# Framework fixes surfaced by the agentic-eacc-mcp-server 1.3.0 → 1.6.0 upgrade

- **Date**: 2026-07-27
- **Status**: Done

## Goal

Four framework weaknesses surfaced during a real upgrade of a generated project
(`agentic-eacc-mcp-server`, Python, 1.3.0 → 1.6.0, merged as `30e8715` in that repo).
None of them broke the upgrade — it completed and validated cleanly — but each one
either cost manual work that the tooling should have done, or silently degrades a
project over time. This plan fixes the three that have real evidence behind them and
records the fourth as a deliberate deferral.

Evidence is from that one upgrade only (**n=1**). Where a fix would add durable
mechanism rather than remove a defect, that matters — see F4 and the Notes.

## Findings

| # | Finding | Evidence | Class |
|---|---|---|---|
| F1 | Python pack's `STDLIB_ROOTS` is a hand-written partial list of the stdlib | 30 names hardcoded vs. 297 in `sys.stdlib_module_names`; missing `calendar`/`zoneinfo` | Real defect, affects every Python project |
| F2 | `upgrade` can't verify a project — "already up to date" is a version-string comparison, not a file check | `upgrade.py:96` returns before classifying any file; verifying 27 files this session required a throwaway script | Tooling gap |
| F3 | New `AGENTS.md` **sections** never reach existing projects and aren't even reported | 1.4.0 (`7b36860`), 1.5.0 (`2044a28`), 1.6.0 (`bf3e429`) each added one; upgrade reminds about new *commands* only | Tooling + docs gap |
| F4 | No retirement path for a framework-owned file that a release removes or renames | `remove_if_exists` is used only for `.new` cleanup; nothing deletes a dropped manifest path | Latent — no incident yet |

### F1 — the one that actually cost a project something

`language-packs/python/tests/arch/test_dependencies.py` guards "the domain layer must
not import external libraries" with a hardcoded allowlist. It omits `calendar` and
`zoneinfo`, so `domain/clock.py` and `domain/relative_date.py` — ordinary stdlib usage —
were flagged as violations.

The damage isn't the false positive; it's what the project had to do about it. The only
fix available was editing a **framework-owned** file, which permanently reclassifies it
as "customized." That file now regenerates a `.new` on every future upgrade, forever.
A framework defect converted itself into recurring per-upgrade toil for the project that
hit it. (Recorded in that project's worklog under 2026-07-27; the same two names had
already been re-added by hand once before, during its 1.2.0 → 1.3.0 upgrade — so this
has now cost the same project manual work **twice**.)

The allowlist already contains `os`, `sys`, `io`, `logging`, `urllib`, `http` and
`threading` — it was never trying to keep the domain layer free of I/O or networking,
only free of *third-party* packages. So it isn't a curated policy list that
happens to be short; it's an incomplete enumeration of something Python can enumerate
itself. `sys.stdlib_module_names` exists since 3.10 and the pack requires `>=3.12`.

## Approach

**F1, F2 and F3 are worth doing. F4 is not, yet.**

### F1 — replace the allowlist with `sys.stdlib_module_names`

Swap the hardcoded set for `sys.stdlib_module_names`, preserving the layer-name and
`__future__` handling already present. This removes the entire class of false positive
rather than adding two more names to a list that will go stale again.

**This edits a `languageSpecific` framework-owned path**
(`language-packs/python/tests/arch/test_dependencies.py`), so per `AGENTS.md` →
Framework Versioning it needs a version bump + `FRAMEWORK-CHANGELOG.md` entry.
**Patch (1.6.1)** — it's a fix, not new capability.

Trade-off accepted: `sys.stdlib_module_names` also admits `socket`, `subprocess`,
`ctypes` into the domain layer. The list already admitted `urllib`/`http`/`threading`,
so this widens a door that was never closed, and the test's stated purpose ("must not
import external libraries") is unchanged. A project wanting a stricter domain layer
should express that as a deny-list in its own `*project-rules*` test — which is exactly
the split 1.6.0 established.

Does **not** retroactively fix eacc-mcp-server: its file is already customized, so 1.6.1
will arrive as a `.new`. But once merged, that project's file becomes byte-identical to
the template and the recurring `.new` ends permanently. Worth telling that project.

### F2 — `upgrade --verify`

A read-only mode that skips the version short-circuit and classifies every managed path:
identical / customized / **missing** / newly-managed. Exit non-zero only on missing files
(a customized file is a legitimate state, not an error).

Reuses the existing per-file classification; the work is restructuring `main()` so the
classification loop is reachable without the write path, then routing `--verify` and
`--dry-run` through it. Same three entry points as `--dry-run` (`upgrade.py`,
`upgrade.sh`, `-Verify` for `upgrade.ps1`).

`upgrade.py`/`.ps1`/`.sh` are framework-repo tooling, not in `harness-manifest.json` and
never copied into a project — **no version bump**, same precedent as the `--dry-run`
work (see FRAMEWORK-CHANGELOG "Tooling - 2026-07-26").

### F3 — report missing `AGENTS.md` sections, don't deliver them

Keep `AGENTS.md` user-owned and never machine-edited — that decision is right and isn't
in question. The gap is only that the framework knows which sections it authored and
says nothing.

Compare the project's `## ` headings against `harness-core/AGENTS.md`'s and print the
ones absent, as advisory output next to the existing new-command reminder. **Derive it
from the template** — do not add an `agentsSections` list to the manifest. A
hand-maintained list of section names is precisely the drift failure mode `AGENTS.md`'s
own Framework Versioning section warns about, and it has already bitten this repo twice.

Known limitation, accepted: a project that renames a heading gets a false positive.
It's advisory text, so the cost is one confusing line, not a broken upgrade. Skip
`{{TEAM_ROLES_SECTION}}` (Team-mode only) and the seeded-but-project-owned headings
(`Key Invariants`, `Coding Rules`, `Prohibited`, `Architecture`) — only report sections
whose body is framework-authored boilerplate.

README also needs correcting: "Two things you own that the framework can't update for
you" currently frames the entire gap as new slash commands (README:176–179, and step 5
of the upgrade workflow at README:294). Sections are the larger half of that gap and go
unmentioned.

### F4 — deferred, deliberately

If a release renames or drops a framework-owned file, every existing project keeps the
orphan indefinitely, and any config pointing at the old path silently rots.

Real, but **zero incidents so far** — no framework release has yet retired a managed
path. Building a `retired` manifest key plus safe-deletion logic (baseline check, don't
delete a customized file, report what was removed) is durable mechanism for a
hypothetical. This repo's own precedent is an **n=2 bar** for exactly this call: 1.5.0
declined to build `check-agent-scope` on the same reasoning, and said so in the changelog
rather than staying silent.

Deferring on the same terms. **Un-defer trigger**: the first release that actually needs
to retire a managed path — at that point it's n=1 with a concrete shape to design
against, which beats guessing now. Recorded here so the decision is visible rather than
forgotten.

### Considered and rejected

**CRLF/LF handling.** Diffing the project's CRLF files against LF templates showed
whole-file changes until `--strip-trailing-cr` was passed. This is *not* a framework
defect — `normalized_hash()` already normalizes line endings before comparing, so the
tool was always correct; only my ad-hoc `diff` invocations were noisy. Noted so it isn't
re-investigated.

## Checklist

- [x] F1 — `sys.stdlib_module_names` in `language-packs/python/tests/arch/test_dependencies.py`
- [x] F1 — verify against a real generated Python project: `zoneinfo`/`calendar` in domain pass, a genuine third-party import still fails
- [x] F1 — bump `harness-core/HARNESS-VERSION` to 1.6.1 + `FRAMEWORK-CHANGELOG.md` entry
- [x] F2 — restructure `upgrade.py` so classification is reachable without writes; add `--verify`
- [x] F2 — mirror into `upgrade.sh` / `upgrade.ps1` (`-Verify`); confirm all three agree on one project
- [x] F2 — verify `--verify` catches a deliberately deleted managed file (exit non-zero) and a customized one (exit zero)
- [x] F3 — missing-section detection + advisory output in all three entry points
- [x] F3 — correct README:176–179 and the step-5 text at README:294
- [x] F4 — record the deferral + un-defer trigger in `FRAMEWORK-CHANGELOG.md`
- [x] `pnpm validate` + `node scripts/check-sync.mjs` green
- [x] Tell agentic-eacc-mcp-server that 1.6.1 ends its recurring `test_dependencies.py` `.new` — **applied and merged** the same day (`a8df888` on that project's `master`). Took the template wholesale; `--verify` confirms the file is no longer listed as customized, leaving `scripts/validate.ps1` as its only remaining one. Predicted outcome held exactly.

## Verification log (what actually ran, not just what the plan intended)

- **F1**: `test_domain_purity` passed against the real project with the new template swapped in
  (`calendar`/`zoneinfo` no longer need a manual re-add); a negative control (injecting a real
  `numpy` import into a domain file) still failed the same test. Trial files discarded, `git
  status` clean afterward.
- **F2**: tested all three entry points against the real project at three states — (a) as-is: 2
  genuinely customized files reported, exit 0; (b) `.claude/commands/adr.md` deliberately
  deleted: reported under both `added` and the new missing-file warning, `--verify`/`-Verify`
  exited 1, confirmed nothing was actually written to disk despite the report; (c) a baseline
  entry removed + file deleted (simulating "never delivered yet"): reported under `added` only,
  no missing-file warning, exit 0. All three states restored via `git checkout` and confirmed
  clean. `upgrade.py`, `upgrade.ps1` (PowerShell 5.1), and `upgrade.sh` all produced matching
  classifications.
- **F3**: `missing_agents_sections`/`Get-MissingAgentsSections` unit-tested directly (real
  project → empty list; synthetic pre-1.4.0-shaped `AGENTS.md` → both expected sections
  flagged, nothing else). End-to-end: temporarily removed the real project's "Handoff and
  Reporting" section, ran `--dry-run` (Python) and `-DryRun` (PowerShell) — both printed the
  correct advisory and nothing else changed; restored via `git checkout`, confirmed clean both
  times.
- **This repo**: `pnpm validate` (check-sync + typecheck + lint + vitest) green after all three
  fixes landed together.

## Notes

- **Verification standard**: this repo's changelog repeatedly stresses "verified with real
  disposable projects, not simulation." F1 and F2 both need a real generated project, not
  a reasoned argument that the code looks right. F1 especially — the whole finding is that
  a plausible-looking allowlist was wrong.
- **n=1 caveat, stated plainly**: all four findings come from a single upgrade of a single
  project. F1 is safe regardless (it's removing a defect, and that defect independently
  cost the same project work twice). F2 and F3 add mechanism on one data point each —
  both are small, advisory, and remove no capability, which is why they clear the bar
  where F4 doesn't.
- **Ordering**: F1 first (only one with a version bump, and only one a project is actively
  paying for). F2 before F3 — F3's detection wants F2's classification restructure.
