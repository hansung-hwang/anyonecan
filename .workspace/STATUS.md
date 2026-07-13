# STATUS

> Snapshot of current work. This file is **overwritten** each session close-out —
> for history, see `worklog.md`. Read this first when starting a new session.

**Last updated**: 2026-07-13
**Active plan**: `.workspace/plans/2026-07-13-harness-upgrade-p1-p5.md`

## Current Goal

Upgrade the framework across 5 priorities so every member — any AI tool, any
language — gets consistent, enforced quality. P1, P2, P3 are done (P3 not
yet committed). P4~P5 remain.

## Progress

- **P1 done** (commit f34eb77): AGENTS.md single rule source, check-sync guard.
- **P2 done** (commit cf39a92): HARNESS-VERSION + manifest + upgrade path,
  verified end-to-end, 3 real bugs found and fixed.
- **P3 done, awaiting commit**: promoted documented rules to hard gates.
  - TS: `.only()` ban + `ban-ts-comment` override, coverage narrowed to
    `src/domain/**`, CI coverage step
  - Python: ruff `T20` + `--cov-fail-under=80` — **verified live** with real
    ruff/pytest in this session
  - Java: Checkstyle `System.out.print*` ban, JaCoCo `coverage` profile
    (project-wide, not domain-scoped — documented why), arch test brought
    to 5-check parity (was missing domain purity, cycles, test-exists)
  - `/commit` pre-scan removed (linter now covers everything)
  - **Caveat**: TS and Java changes could only be syntax/well-formedness
    checked in this session (no pnpm/node_modules, no Java/Maven available)
    — not actually compiled or run. Python WAS verified live. Recommend the
    user run `pnpm validate`/`pnpm test:coverage` and `mvn verify -P
    coverage` once in an environment with those tools before trusting this
    in production.

## Next Steps

1. Review + commit P3
2. Start P4: PR template, move how-to docs into harness-core, multi-member
   `.workspace` note, named CI steps for TS/Python
3. Then P5: pack.json-driven language packs

## Blockers / Open Questions

- pnpm is not on PATH in this shell — `pnpm validate` must be run by the
  user, or `bash scripts/validate.sh` after confirming pnpm is reachable.
- No Java/Maven in this environment — the Java arch-test additions and
  JaCoCo profile are unverified beyond XML well-formedness. Flag for the
  user to confirm with real Maven before relying on them.
