# FRAMEWORK-CHANGELOG

Changelog for **this framework's own evolution** (`harness-core/HARNESS-VERSION`).

Not to be confused with the per-project `HARNESS-CHANGELOG.md` (copied into
every generated project), which tracks agent mistakes and the rules added
to prevent them via `/fix`. This file tracks changes to the framework
itself, so a project owner running `upgrade.ps1`/`upgrade.sh` knows what
they're pulling in.

See `AGENTS.md` → "Framework Versioning" for the bump rule.

## [1.7.0] - 2026-07-28

**`upgrade`: detect when a template `AGENTS.md` section's body changed, not just whether it's missing:**

- 1.6.1 could only tell a project that a framework-authored `AGENTS.md` section was entirely
  *absent*. It said nothing when a section the project already has had its *body* quietly
  move on in a later release — the heading matches on both sides, so nothing looked wrong.
- Measured before building anything: across `harness-core/AGENTS.md`'s full history, "heading
  stayed, body changed" happened **11 times** in 8 of the file's 10 revising commits. After
  discounting what other mechanisms already cover (`Coding Rules` is project-owned; 3 of the
  `Workflow Prompts` changes are already covered by the new-slash-command reminder), **8 events
  were genuinely undetected** — more than double the 4 *missing-section* events 1.6.1 built
  tooling for. Confirmed with a live instance: `Homographormer`'s `Work Journal` was missing a
  sentence the template gained in the 1.4.0 era; fixed by hand this session, but nothing had
  told the project it was stale.
- **Core design property, carried over from 1.6.1's own lesson**: hash the *template's*
  section body, never the project's own prose. A translated or deliberately rewritten section
  (like a Korean project's own `Handoff and Reporting`) never false-positives here — the same
  principle that stops 1.6.1's missing-section check from flagging a renamed heading. The
  advisory only ever claims "the framework's version of this changed, go look", never "yours
  is wrong".
- New `.harness-meta.json` key `agentsTemplateSections` (section name → hash of the
  template's body as of the project's last upgrade). A section with no recorded hash yet
  (first run under this feature, or a section the project doesn't have) is recorded silently,
  not reported — there's no "since your last upgrade" baseline to compare against, and
  dumping every historical change on first run would train people to ignore the channel.
  `setup.ps1`/`setup.sh` record this map at generation time so a freshly generated project
  never hits that first-run gap at all.
- **Real bug found and fixed during verification, not by inspection**: a freshly generated
  test project reported 5 sections "changed" seconds after being generated from the exact
  template it was just stamped from. Root cause: `Get-Content` in PowerShell defaults to the
  system's active codepage, not UTF-8 — on this non-English-codepage Windows box it silently
  mangled em-dashes and other non-ASCII template prose into `?`, producing a hash mismatch
  against the correctly-UTF-8-read Python side. Fixed every `Get-Content` call in
  `upgrade.ps1`/`setup.ps1` that reads UTF-8 template/project content to specify
  `-Encoding UTF8` explicitly. This also silently fixes a **pre-existing, independent bug**
  from 1.6.1: `Get-Headings` (the missing-section check's own heading reader) had the same gap
  — any non-English `AGENTS.md` heading read via `upgrade.ps1` was at risk of the identical
  corruption, and `.harness-meta.json` itself (author names, `commentLanguage` values like
  "한국어 (Korean)") was being silently mangled on every `upgrade.ps1` run against a non-English
  project and re-written corrupted. Neither had been exercised by 1.6.1's own verification,
  which only used ASCII English content.
- **Why this required a version bump when 1.6.0's `--dry-run` and 1.6.1's `--verify` didn't**:
  none of `upgrade.py`/`upgrade.ps1`/`upgrade.sh`/`setup.ps1`/`setup.sh`/`.harness-meta.json`
  are manifest-owned, so the letter of the versioning rule doesn't require a bump. But
  `upgrade.py`'s own early return (`if old_version == new_version and has_meta and
  has_baselines and not read_only: return 0`) means a plain write-mode run on an
  already-current project exits before this feature's hash-recording code ever runs — the
  feature would ship permanently dormant for every project already caught up, including the
  one it was built for. `--dry-run`/`--verify` bypass that early return but are read-only by
  contract and can't establish the baseline either. Bumping to 1.7.0 is what makes the feature
  reachable, not a visibility preference.
- Verified against real generation and real projects, not simulation: a project generated
  fresh via the fixed `setup.ps1` reports zero changed/missing sections immediately; a
  deliberate mutation of a template section's body (`Steering Loop`) was correctly detected by
  name in both `upgrade.py --verify` and `upgrade.ps1 -Verify`, with the mutation reverted via
  `git checkout` afterward and confirmed clean; `--dry-run`/real-mode-with-matching-versions
  both confirmed to write nothing to `.harness-meta.json`, by diffing the file before and
  after.
- Full design record, including the ratified S0 decisions (per-section vs. whole-file
  hashing, the exclusion set, first-run-silent behavior) and the version-bump reasoning above
  stated in full: `.workspace/plans/2026-07-28-agents-section-drift-detection.md`.

## Tooling - 2026-07-28 (no `HARNESS-VERSION` bump)

**`AGENTS.md` missing-section advisory: honest about its own limitation:**

`upgrade.py`/`upgrade.ps1` (`upgrade.sh` delegates to `upgrade.py`, so only two files needed
the edit) are framework-repo tooling, never copied into a generated project, so per `AGENTS.md`
→ Framework Versioning this doesn't require a version bump — same precedent as `--dry-run`
(1.6.0) and `--verify` (1.6.1).

- Found applying 1.6.1 to `Homographormer` (Korean-language project): its `AGENTS.md` has
  translated the "Handoff and Reporting" heading to `## 핸드오프·보고 규약` — the section
  genuinely exists, translated, but 1.6.1's missing-section advisory (exact heading-text match)
  reported it as missing anyway, indistinguishable in the printed output from a section that
  was never added at all.
- Not fixed by detecting translations — no reliable, low-cost way to do that from heading text
  alone, and the false positive is harmless (advisory-only, doesn't affect `--verify`'s exit
  code). Fixed by making the message honest about what the check actually does: added a line
  to both entry points' advisory text stating the match is by exact heading text, so a
  translated or renamed heading will show up here even though the section already exists —
  check before adding a duplicate.
- **Deliberately deferred, not built now**: an alias map in `.harness-meta.json`
  (`agentsSectionAliases: {"Handoff and Reporting": "핸드오프·보고 규약"}`) would resolve this
  for real, at the cost of upgrade needing to read and trust project-declared state for a
  check that's currently pure template-vs-project comparison. One confirmed occurrence so far
  (`Homographormer`) — deferring on the same n=2 bar this changelog already uses for
  `check-agent-scope` (1.5.0) and F4 (below, in 1.6.1's entry). **Un-defer trigger**: a second
  non-English project hitting the same false positive.
- **Separately noted, not addressed here**: this advisory only detects a *missing* heading, not
  a template section whose *body* changed since a project's last upgrade while the heading
  stayed put (confirmed happening in practice — `Homographormer`'s "Work Journal" section
  predates a 1.4.0-era sentence in the template about where newly-learned rules get appended,
  and the advisory says nothing about it since both projects have the heading). Real gap,
  bigger than the translation case since it's language-independent, but a genuinely new
  feature (would need per-section content hashes recorded in `.harness-meta.json`, analogous
  to the existing per-file baseline hashes) — not a wording fix, so out of scope for this
  same-day change. Candidate for its own future plan.

## [1.6.1] - 2026-07-27

**Python domain-purity check: stdlib allowlist replaced with `sys.stdlib_module_names`:**

- Root cause: `language-packs/python/tests/arch/test_dependencies.py`'s `test_domain_purity`
  gated "the domain layer must not import external libraries" behind a hand-written 30-name
  `STDLIB_ROOTS` set. It was missing real stdlib modules (`calendar`, `zoneinfo` confirmed
  missing) — a false positive on ordinary standard-library usage, not third-party code, the
  thing the check was actually meant to catch.
- Found via a real project upgrade (`agentic-eacc-mcp-server`, 1.3.0 → 1.6.0): its
  `domain/clock.py` (`zoneinfo`) and `domain/relative_date.py` (`calendar`) tripped this
  false positive, and the only available fix at the time was editing the framework-owned
  file directly — which permanently reclassifies it as "customized," so it now regenerates a
  `.new` on every future upgrade indefinitely. The same project had already re-added the same
  two names once before, during its 1.2.0 → 1.3.0 upgrade — this cost it manual work twice.
- Fix: `STDLIB_ROOTS` now reads `sys.stdlib_module_names` (297 names, Python 3.10+; the pack
  requires `>=3.12`) instead of a hardcoded subset, so it can't go stale the same way again.
  The check's intent is unchanged (still blocks third-party packages in `domain/`); the
  allowlist already contained `os`/`urllib`/`http`/`threading`, so this doesn't newly permit
  a class of import the check was ever trying to exclude.
- Does **not** retroactively fix already-upgraded projects with a customized copy of this
  file (like `agentic-eacc-mcp-server`) — their next upgrade will still offer 1.6.1's version
  as a `.new`. Once merged, their file becomes byte-identical to the template again and the
  recurring `.new` ends for good.
- Verified against a real generated project (not simulation): swapped the new template into
  `agentic-eacc-mcp-server`'s `tests/arch/test_dependencies.py` in place — `test_domain_purity`
  passed with `calendar`/`zoneinfo` present and no manual allowlist edit; a negative control
  (injecting a genuine third-party import, `numpy`, into a domain-layer file) still failed the
  same test. Trial files discarded, project's committed file left untouched (`git status`
  clean afterward).
- Full design record, including F2/F3 (below, same session) and F4 (deliberately deferred, same
  n=2 bar 1.5.0 used for `check-agent-scope`): `.workspace/plans/2026-07-27-upgrade-feedback-from-eacc-1.6.0.md`.

## Tooling - 2026-07-27 (no `HARNESS-VERSION` bump)

**`upgrade --verify` + `AGENTS.md` missing-section reporting:**

`upgrade.py`/`upgrade.ps1`/`upgrade.sh` are framework-repo tooling, never copied into a
generated project, so per `AGENTS.md` → Framework Versioning this doesn't require a version
bump — same precedent as the 1.6.0-era `--dry-run` work. Both fixes came from the same
`agentic-eacc-mcp-server` 1.6.0 upgrade session that produced 1.6.1 above.

- **`--verify` (`-Verify` on Windows), all three entry points**: a read-only mode for
  scripting, distinct from `--dry-run`'s preview-for-a-human framing. Exits non-zero only if a
  file the framework previously delivered (has a baseline entry) is now absent from the
  project — a customized or newly-managed file is a legitimate state, not a failure, so
  neither triggers a non-zero exit.
- **Closed a real blind spot shared by `--verify` and `--dry-run`**: both previously inherited
  the same early-return as a normal run — if the project's `HARNESS-VERSION` already matched
  the framework's, the script printed "already up to date" and returned before classifying a
  single file. A version string agreeing says nothing about whether an individual managed file
  still matches its template; this session's own `--dry-run` run against an already-upgraded
  project produced exactly that uninformative result, and verifying the upgrade actually took a
  throwaway hash-diff script instead. Fixed by skipping the early-return for `--dry-run`/
  `--verify` only (a plain no-flag run keeps the old fast-path, unchanged, since that's a
  write-mode command where speed is the point and nothing was reported as broken about it).
- **`AGENTS.md` missing-section advisory**: `upgrade` now compares a project's `AGENTS.md`
  headings against `harness-core/AGENTS.md`'s and prints any framework-authored section the
  project doesn't have (excluding the seeded-at-generation, project-owned headings: Key
  Invariants, Architecture, Coding Rules, Prohibited). `AGENTS.md` stays user-owned and
  unwritten either way — this only reports. Closes a real gap: 1.4.0's "Handoff and Reporting"
  and 1.6.0's "File Ownership" both shipped as new template sections with no mechanism telling
  an existing project they existed, beyond the pre-existing new-slash-command reminder (which
  only covers `.claude/commands/*.md`, not `AGENTS.md` prose). Found by hand this session,
  diffing `agentic-eacc-mcp-server`'s `AGENTS.md` headings against the template manually — the
  gap this change closes.
- **Derived, not hand-maintained**: the missing-section list comes from parsing
  `harness-core/AGENTS.md`'s own `## ` headings at run time, not a separately tracked list in
  the manifest. A hand-copied list is exactly the drift failure mode `AGENTS.md`'s own Framework
  Versioning section already warns about (it happened to that section's own prose twice); this
  avoids adding a fourth copy to keep in sync.
- Verified against the real `agentic-eacc-mcp-server` project (not simulation), all three
  entry points: `--dry-run`/`--verify` no longer short-circuit on a version match and correctly
  report its 2 genuinely customized files; a deliberately deleted previously-delivered file
  (`.claude/commands/adr.md`) was correctly flagged as missing with a non-zero `--verify` exit,
  while a file with no baseline entry (simulating "never delivered yet") was correctly treated
  as ordinary pending delivery, not a failure; confirmed neither read-only mode wrote anything
  to disk in either case. Missing-section detection verified against the real project in both
  directions: zero false positives at its current state (both sections already added), and a
  temporarily-stripped copy of one section correctly reported as missing, in both `upgrade.py`
  and `upgrade.ps1` (PowerShell syntax-parsed clean via
  `[System.Management.Automation.Language.Parser]::ParseFile`). All trial edits were made
  in-place and restored via `git checkout` immediately after, confirmed by a clean `git status`
  each time — no lasting changes to the project used for verification.
- Full design record: `.workspace/plans/2026-07-27-upgrade-feedback-from-eacc-1.6.0.md`.

**F4 (retiring a removed/renamed framework-owned manifest path) — deliberately deferred, not
forgotten:** no framework release has yet needed to retire a managed path, so this is a
zero-incident, real-but-hypothetical gap. Declining to build `retired`-path handling now on the
same n=2 bar 1.5.0 used to defer `check-agent-scope` in its own changelog entry — one project's
upgrade surfacing the *shape* of a future problem isn't the same as a second real occurrence
needing the fix. **Un-defer trigger**: the first release that actually needs to retire a
manifest path, at which point there's a concrete case to design against instead of a guess.

## [1.6.0] - 2026-07-26

**File ownership rules — tell projects what they may edit:**

- Root cause: the Homographormer incident (see the Tooling entry below) traced back further than a code bug —
  the shipped `AGENTS.md`/`CLAUDE.md` said nothing about which files a project may edit versus which the framework
  manages, and the only machine-readable map (`harness-manifest.json`) was copied once at generation and never
  refreshed, so it silently went stale. The project did nothing wrong; it had no way to know better.
- New `docs/how-to/file-ownership.md` (framework-owned, added to every project): the three-tier model (**Yours**
  — edit freely; **Framework's** — `upgrade` overwrites when unmodified; **Customizable, at a cost** — your
  version kept, template arrives as `<file>.new`), the single highest-value rule (never create new files inside a
  Framework's-tier directory — put project-specific docs in `docs/guides/` instead, which the manifest will never
  claim), and exactly how the `.new` merge cycle resolves.
- New short `## File Ownership` section in `AGENTS.md` (tier summary + the "don't create files in framework
  directories" rule), placed next to `Validation`/`Steering Loop` where edit-time decisions happen. Reaches new
  projects immediately; existing projects get it via the guide on upgrade (the section itself is user-owned, so it
  doesn't retroactively appear in `AGENTS.md` — same asymmetry as every other `AGENTS.md`-only addition).
- `harness-manifest.json` is now itself `frameworkOwned` — the map that used to go stale is now refreshed by every
  upgrade. **One-time caveat for existing projects**: since this is the first time the manifest is
  baseline-tracked, the first post-1.6.0 upgrade offers it as a "newly managed" `.new` rather than refreshing it
  silently (the safe default when there's no baseline to compare against — see the Tooling entry's D1 fix). Once
  that one `.new` is resolved (it's almost certainly identical to what the project already had), every later
  upgrade refreshes it automatically, verified end-to-end with a real disposable project.
- `scripts/check-sync.mjs` gained a fourth guard: `file-ownership.md`'s Framework-tier list (between
  `<!-- framework-tier:start/end -->` markers) must exactly match `harness-manifest.json`'s `frameworkOwned` +
  every language's `languageSpecific` paths, in both directions. Verified by deliberately breaking it three ways
  (a real omission caught during this release's own Gate O0, plus two synthetic breaks) — all three correctly
  failed the build, all three fixes confirmed.
- `AGENTS.md`'s Steering Loop and `.workspace/plans/README.md` (both copies) now point at the ownership rule, so a
  mistake-driven edit or a new plan can't casually propose changing framework territory without noticing.
- Verified with real disposable projects, not simulation: fresh-generation matrix across all three languages
  (guide + `AGENTS.md` section present, byte-identical delivery, no leftover `{{...}}` tokens); a real upgrade
  matrix (pre-1.6.0 project → current tooling, confirmed `AGENTS.md` untouched per the design asymmetry, the
  one-time manifest `.new` behavior, and full self-healing on the next upgrade after resolving it); and a live
  test with fresh, zero-context agents given an undirected guide-writing task, to confirm the rule actually
  changes behavior rather than merely existing in a file no one reads.
- Full design record: `.workspace/plans/2026-07-25-file-ownership-rules.md`.

## Tooling - 2026-07-26 (no `HARNESS-VERSION` bump)

**`upgrade` safety fix + `--dry-run`:**

`upgrade.py`/`upgrade.ps1`/`upgrade.sh` are framework-repo tooling, never copied into a generated project (not in
`harness-manifest.json`), so per `AGENTS.md` → Framework Versioning this doesn't require a version bump — same
precedent as 1.4.0's `.harness-meta.json`/`harnessVersion` fix below.

- **`--dry-run` (all three entry points)**: previews exactly what an upgrade would do — same classification logic
  as a real run, sharing one code path via `write_text()`/`remove_if_exists()` helpers that no-op when dry-run is
  set — and writes zero bytes. `upgrade.py`/`upgrade.sh` take `--dry-run` (anywhere in argv); `upgrade.ps1` takes
  `-DryRun`, matching each shell's idiom. Always exits 0 (a preview, not a CI gate).
- **Closed a real baseline-tracking gap**: a manifest path that's *new* since a project's last upgrade, where the
  project has already written its own file at that path, was being **silently overwritten** — the code couldn't
  distinguish "the project customized a known file" from "this path didn't exist in the manifest yet, so there's
  no baseline to compare against." Found while planning the Homographormer 1.3.0→1.5.0 upgrade: its hand-written
  22 KB Korean multi-agent guide sat exactly at a path (`docs/how-to/multi-agent-collaboration.md`) the framework
  claimed after that project's last upgrade. Fixed by treating "baselines map exists, but this path has no entry,
  and the file exists on disk anyway" as project authorship — same `<file>.new` treatment as an ordinary
  customized file, reported in its own "newly managed by the framework" bucket so the reason is clear. Genuine
  pre-1.3.0 projects (no `baselines` map at all) are unaffected — they still take the old unconditional-overwrite
  path for one run, with the existing warning.
- New post-upgrade guidance: when new `.claude/commands/*.md` files are added, upgrade now prints a reminder that
  `AGENTS.md`'s Workflow Prompts table and `CLAUDE.md`'s command list are user-owned and must be hand-registered,
  naming the commands added.
- `harness-manifest.json`'s `_baselinesComment` rewritten to document all three per-file cases (unmodified /
  customized / newly-managed-with-no-entry) instead of the old two-case description.
- Verified with real disposable projects (`git worktree` checkouts at the 1.3.0 and pre-versioning commits,
  generated via their own `setup.ps1`, deleted after), not simulation: reproduced the Homographormer hazard
  synthetically (original file confirmed byte-identical after upgrade, `.new` written); regression-checked both a
  genuine pre-versioning project and an ordinary customized-file case still behave exactly as before;
  full-tree-hash-verified `--dry-run` writes zero bytes and its output matches the following real run; cross-checked
  `upgrade.py`/`upgrade.ps1`/`upgrade.sh` agree; re-ran `--dry-run` against the real on-disk Homographormer copy
  and confirmed the guide now reports as `.new`, not overwritten.
- Full design record: `.workspace/plans/2026-07-25-upgrade-tooling-safety-and-dry-run.md`.

## [1.5.0] - 2026-07-25

**Team roles & project mode (Solo/Team):**

- New "Project mode" prompt in `setup.ps1`/`setup.sh` (Solo default, Team opt-in), matching the existing
  language/comment-language prompt style. `.harness-meta.json` gains `projectMode`; Solo omits `roles`/`roster`
  entirely, Team writes empty `[]`/`{}` for `/team` to populate.
- New `## Team & Roles` `AGENTS.md` section, scaffolded only in Team mode (a `{{TEAM_ROLES_SECTION}}` template
  token, placed between "Handoff and Reporting" and "Key Invariants", that Solo strips to nothing — zero-overhead
  litmus verified: the Solo/Team `AGENTS.md` diff is exactly this one section, nothing else moves).
- New `.claude/commands/team.md` (`/team`): one command for both "set up at the start" and "change anytime" — picks
  roles from a default 7-role catalog (Planner, Architect, Backend, Frontend, Data/DBA, Infra/DevOps, QA/Test; user
  editable) or custom ones, assigns a roster, and writes the role→ownership map into `AGENTS.md` (mirrored to
  `.harness-meta.json`). Role ownership maps onto the existing clean-architecture layers rather than a new ACL
  system. Reviewer/Integrator is a rotating hat (whoever reviews a PR holds that PR's merge gate), not a fixed role.
- `docs/how-to/multi-agent-collaboration.md` §13 ("Working as a team") gains the actual in-role convention — active
  role by explicit declaration or branch-prefix hint, edits restricted to the active role's owned scope, cross-role
  changes escalated as a request note to `.workspace/plans/<date>-<short-topic>-request.md` (addressed to the
  owning role) instead of edited directly, reusing the same escalation pattern a sub-agent already uses toward a
  Coordinator. This replaces the deferral note the section carried since 1.4.0.
- Enforcement is **prose-only** in 1.5.0 (the agent reads the role map from always-loaded `AGENTS.md` and
  self-constrains); a mechanical `check-agent-scope` checker is deferred to 1.6.0, reusing the same ownership data.
- Verified with real dry runs, not simulation: a fresh, zero-context agent declared under a role and given a
  cross-role task self-constrained and escalated correctly in two separate runs. The first run surfaced a real gap
  — the escalation note's location was unspecified, so the agent had to infer one — fixed in the same session by
  making the location concrete in both `/team`'s generation instructions and the guide; a second run with a fresh
  agent confirmed the fix (location "given verbatim," not inferred).
- Post-close-out audit (real, not a re-read): a live agent actually running `/team`'s instructions — not a manual
  dry run — found `/team`'s `.harness-meta.json` step had no worked example, so multi-word role ids and multi-role
  people were being inferred rather than specified (a real schema-drift risk). Fixed with an explicit shape +
  worked JSON example in `/team`'s Step 6 (both copies); confirmed with two further live runs. Full record:
  `.workspace/plans/2026-07-23-team-roles-and-project-mode.md`'s "Post-close-out audit" section.
- **Deliberately still deferred to 1.6.0** (not un-deferred by this release): the conditional coordination
  branches in `/start`, `/commit`, `/review`, and `/done` that 1.4.0 pushed out, and the mechanical
  `scripts/check-agent-scope.*` checker. 1.4.0's stated un-defer trigger was **n=2** — a *second* real project's
  multi-agent session where the prose-only contract demonstrably fails. That hasn't happened; this release's own
  T3 dry run (see above) is evidence *for* the prose approach, not against it — the gap it found was an
  under-specified location, not a role-scope violation, and it was closed by tightening the prose, not by adding
  a mechanical check. Decision, not omission — recorded here per 1.4.0's own instruction to do so.
- Full design record and phase-by-phase verification: `.workspace/plans/2026-07-23-team-roles-and-project-mode.md`.

## [1.4.0] - 2026-07-23

**Opt-in multi-agent coordination layer (slim scope):**

- Root cause / evidence: a real generated-project multi-agent session (documented in that project's own
  `docs/how-to/multi-agent-collaboration.md`) survived code review cleanly, but shared state and reporting broke in
  five repeatable ways — a reviewed file grew before commit, uncommitted work from two sessions accumulated with no
  clear boundary, `worklog.md`/`STATUS.md` drifted (duplicate rows, stale sections), a completion report claimed
  nine items reflected when only review notes had changed, and a test-pass claim didn't reproduce in a different
  environment (a writable-temp-path difference, not a code defect). None of these were code-quality failures — the
  harness had nothing standardizing shared-state handoff or reporting.
- New `AGENTS.md` section **"Handoff and Reporting"** (after Work Journal, before Key Invariants): clean handoff
  (a WIP commit if commit authority exists, otherwise an explicitly declared owned diff — never a silent dirty
  handoff), fixed-SHA review (re-review if Head moves), `requirement → file/symbol/test location` reporting instead
  of counts, and command+working-directory+environment evidence on validation claims. **Applies at any actor
  count** — three of the five source incidents happened in a single session, so this isn't multi-agent-gated.
- New `docs/how-to/multi-agent-collaboration.md` guide (framework-owned, added to every project): Coordinator/
  Implementation/Test/Research-Review/Execution roles, worktree/branch isolation, Base SHA + per-wave single-writer
  ownership, task-assignment and completion-report templates, a file-ownership table, a Coordinator merge
  procedure, a Claude Code tool appendix (`isolation: "worktree"`, `subagent_type: "fork"`, `SendMessage`), and a
  "Working as a team (multiple people)" section (same model, PR review replaces the Coordinator's cherry-pick).
  Activates only when multiple sessions/sub-agents touch the repo at once; a solo user never needs to open it.
- New `.claude/commands/coordinate.md` (`/coordinate`): produces a coordination plan (Coordinator, Base SHA,
  per-agent file allow/deny lists, integration order) or an explicit single-agent recommendation when the task
  doesn't clear the parallelization-benefit bar. Plans only — never creates branches/worktrees or spawns agents
  itself.
- `.workspace/plans/README.md` template gains an optional `Owner` field and an optional `Parallelization` block
  (Coordinator, Base SHA, Wave assignments, integration order, completion authority) that `/plan` points to and
  `/coordinate` writes into; both are skipped entirely on an ordinary single-agent plan. `worklog.md`'s row format
  gained an optional author column, documented as a convention rather than a `/done.md` edit.
- `AGENTS.md`'s "Multiple team members" note gained one bullet: new Key Invariants entries are added **append-only
  to the bottom** (no reformatting/reordering) so concurrent edits from different people merge without conflict.
- **Deliberately deferred to 1.5.0** after a complexity-budget review: conditional coordination logic in `/start`,
  `/commit`, `/review`, and `/done` (would tax every user's most-used commands for a workflow only a minority uses)
  and a mechanical `scripts/check-agent-scope.*` scope checker (no second real use case yet to justify it). The one
  genuinely general rule inside the deferred `/review` edit — fixed-SHA review — is already covered by the
  always-on `AGENTS.md` Handoff and Reporting section, so single-agent review loses nothing by this deferral.
  Litmus applied throughout: *can a solo user ignore this feature and never notice it?* Everything shipped in 1.4.0
  passes that test.
- `scripts/check-sync.mjs` gained a third guard: every `harness-core` command and `docs/how-to` guide must be
  registered in `harness-manifest.json`'s `frameworkOwned`, or `upgrade` silently never delivers it to an existing
  project. Nothing previously caught a forgotten manifest entry.
- Full design record, including the complexity-budget scope cut and a companion team-roles/project-mode design
  (provisional 1.5.0, not part of this release): `.workspace/plans/2026-07-22-multi-agent-coordination.md` and
  `.workspace/plans/2026-07-23-team-roles-and-project-mode.md`.

**Incidental fix, found while verifying this release's upgrade path (not itself frameworkOwned, no version bump
required, noted here since it affects every upgrade run):**

- `upgrade.ps1`/`upgrade.py` never updated `.harness-meta.json`'s own `harnessVersion` field — only the standalone
  `HARNESS-VERSION` file was written, so a project's metadata silently kept reporting its pre-upgrade version
  indefinitely (baselines advanced correctly; only this one field was stale). Pre-existing since the 1.3.0
  baseline-tracking system. Fixed in both scripts and verified end-to-end against a real 1.3.0→1.4.0 upgrade.

## [1.3.0] - 2026-07-14

**Customization-safety for upgrade (dpkg-conffile-style protection):**

- Root cause: upgrading a project generated before 1.3.0 (`agentic-eacc-mcp-server`)
  showed that `upgrade` overwrites every framework-owned/language-specific file
  unconditionally, with no way to tell a file the project customized apart
  from one it never touched. Three real files were silently clobbered on
  that project's first upgrade (a project-added `SessionStart` hook in
  `.claude/settings.json`, a project-specific arch test appended to
  `tests/arch/test_dependencies.py`, and Python-specific wording in
  `docs/adr/001-*`) and had to be manually restored with `git checkout`
  after the fact.
- `setup.ps1`/`setup.sh` now record a baseline (LF-normalized SHA-256) of
  every frameworkOwned/languageSpecific file into `.harness-meta.json`'s new
  `baselines` map at generation time (`HARNESS-VERSION` itself excluded --
  it's an unconditional marker, not a mergeable template).
- `upgrade.ps1`/`upgrade.py` (shared by `upgrade.sh`) now branch per file:
  unmodified-since-baseline → overwrite + advance baseline; modified →
  leave the project's file alone and write the new template as `<file>.new`
  for manual merge (baseline stays at the old hash so the next upgrade
  offers the merge again); a project's file matching its `.new` exactly on
  a later run is treated as caught up and the stray `.new` is cleaned up
  automatically -- no separate "mark as merged" step needed. Projects
  upgrading from a pre-1.3.0 `.harness-meta.json` (no `baselines` map) fall
  back to the old always-overwrite behavior for one run with a warning, then
  gain baseline tracking from that point on.
- `docs/adr/001-clean-architecture-layers.md` reclassified from
  `frameworkOwned` to `bootstrapIfMissing` -- an ADR is a project decision
  record from the moment it's created (this project's own copy already had
  Python-specific wording), so upgrade should never have been overwriting it.
- New `bootstrapLanguageSpecific` manifest section seeds a project-owned
  architecture-test extension point per language (`tests/arch/test_project_rules.py`
  / `src/tests/arch/project-rules.test.ts` / `src/test/java/arch/ProjectRulesTest.java`)
  -- created once if missing, never overwritten, so a project-specific arch
  check has a home that isn't the framework-owned dependency-test file.

**Methodology backport (from real framework usage on `agentic-eacc-mcp-server`):**

- `SessionStart` hook added to all three language packs' `.claude/settings.json`,
  wired to a new frameworkOwned `harness-core/scripts/status-context.sh` that
  prints `.workspace/STATUS.md` at the start of every session -- so the
  current work snapshot is surfaced automatically instead of relying on the
  agent remembering to run `/start` or read `STATUS.md` on its own.
- `AGENTS.md` template gains a "Key Invariants (do not break)" section
  (seeded empty, with an instruction to accumulate one bullet per incident
  or non-obvious design decision) -- the project's real accumulated value
  observed was in this kind of distilled, hard-won rule, not in restating
  generic coding style.
- Work Journal section now says to update `STATUS.md` and affected docs
  **the moment** a meaningful change lands, not just at `/done` session
  close-out -- more resilient to an unplanned session end.
- Python pack's `scripts/validate.sh` now prefers `.venv/bin/python` or
  `.venv/Scripts/python.exe` over whatever `python`/`python3` resolves to on
  PATH (a bare system Python produces confusing import-not-found errors that
  look like real mypy failures); new `scripts/validate.ps1` added for native
  Windows PowerShell use, registered in the manifest.
- `start.md`'s Read Work State step now also greps `.workspace/plans/*.md`
  for any `- **Status**: In Progress` beyond the one `STATUS.md` points at,
  so a second in-flight plan isn't silently missed.

## [1.2.0] - 2026-07-14

**P4 — Team collaboration layer:**

- Added `harness-core/.github/PULL_REQUEST_TEMPLATE.md` (tests included?
  validate passes? plan doc linked? ADR written? AGENTS.md updated?).
- Moved `docs/how-to/git-workflow.md` and `testing-guide.md` into
  `harness-core/docs/how-to/`, generalized to be language-agnostic (they
  previously only existed in this framework repo's own docs and were never
  copied into generated projects). `component-guide.md` stays root-only —
  it documents this repo's own TypeScript conventions, not a
  generated-project template.
- Documented multi-member `.workspace/` conflict handling
  (`.workspace/plans/README.md` + `AGENTS.md` Work Journal section, both
  copies): `STATUS.md` is a per-branch snapshot, `worklog.md` is
  append-only and should keep both sides' rows on merge conflict.
- Split the single "Validate" CI step into named `Typecheck` / `Lint` /
  `Test` steps for the TypeScript and Python language packs (and this
  repo's own root `ci.yml`), so PR failures point at the specific check
  that failed instead of a generic bash script. Java's `mvn verify` still
  runs as one step — Maven's build lifecycle doesn't split cheaply into
  separate typecheck/lint/test invocations.

**P5 — Data-driven language packs:**

- Added `language-packs/<lang>/pack.json` for typescript/python/java —
  display name, menu order, aliases, AGENTS.md rules + banned items,
  optional `postGenerate` flag, and an `install.candidates` list (tool
  check → run → optional retry-fix → success message).
- `setup.ps1`/`setup.sh` now discover language packs by globbing
  `language-packs/*/pack.json` instead of hardcoding a 3-way switch —
  adding a language no longer requires editing the setup scripts. `pack.json`
  is deleted from the generated project after the overlay copy (it's
  setup-time metadata only). Java's base-package prompt and package-dir
  generation are now keyed off `pack.json`'s `postGenerate: "java-packages"`
  flag rather than a hardcoded language check.
- Added `docs/how-to/adding-a-language-pack.md` — the full pack contract
  (required files, `pack.json` schema, the 5-check arch-test parity matrix,
  manifest registration, end-to-end verify steps). README's "Adding a New
  Language Pack" section rewritten to match.
- Verified: generated one project per language via `setup.ps1` with piped
  stdin (TypeScript, Python, Java — including Java's base-package prompt
  and `{{BASE_PACKAGE}}` substitution), plus alias-based input (`python`)
  and blank-input default-to-TypeScript. `setup.sh`'s equivalent rewrite
  was only syntax-checked (`bash -n`), not run end-to-end, on this Windows
  machine.

## [1.0.0] - 2026-07-13

- Baseline version. Established `HARNESS-VERSION` + `harness-manifest.json`
  + `upgrade.ps1`/`upgrade.sh`/`upgrade.py` so existing generated projects
  can pull in framework updates instead of staying frozen at generation time.
- Added `.workspace/` work journal (`STATUS.md`, `worklog.md`, `plans/`) and
  the `/plan`, `/done` commands so work survives an unplanned session end.
  `/start` now reads `.workspace/STATUS.md`; `/commit` hints at `/done`.
- Made `AGENTS.md` the single source of truth for project rules. `CLAUDE.md`
  shrinks to a header + `@AGENTS.md` import; `.cursorrules`/`.windsurfrules`/
  `.cursor/rules/harness.mdc` shrink to thin pointers. `setup.ps1`/`setup.sh`
  placeholder substitution narrowed to `AGENTS.md` only.
- Added `scripts/check-sync.mjs` (this repo's own drift guard between root
  and `harness-core` command files).
- `setup.ps1`/`setup.sh` now write `.harness-meta.json` in every generated
  project, capturing the answers given at generation time so `upgrade` can
  re-render templated files (e.g. Java's `{{BASE_PACKAGE}}`) later.
