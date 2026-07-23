# STATUS

> Snapshot of current work. This file is **overwritten** each session close-out —
> for history, see `worklog.md`. Read this first when starting a new session.

**Last updated**: 2026-07-23
**Active plan**: `.workspace/plans/2026-07-22-multi-agent-coordination.md`
**Related plan**: `.workspace/plans/2026-07-23-team-roles-and-project-mode.md` (In Progress — design; provisional 1.5.0)

## Current Goal

Implement an opt-in multi-agent coordination layer for generated projects (Harness 1.4.0), preserving the 1.3.0
customization-safety contract. **Gate M0 closed + scope cut to a slim core (2026-07-23).** 1.4.0 ships only the
low-complexity, broadly-useful half (guide + AGENTS Handoff section + `/coordinate` + `/plan` optional block); the
`/start`·`/commit`·`/review`·`/done` prompt edits and the scope checker are **deferred to 1.5.0** (n=2 trigger).
**M1, M2, and M3 all passed their gates (2026-07-23). `HARNESS-VERSION` is now 1.4.0.** `harness-core/` has the
guide, `/coordinate`, AGENTS/CLAUDE pointers, the `/plan` block, manifest registration, and a new check-sync guard;
`FRAMEWORK-CHANGELOG.md` and `README.md` document all of it. **Open caveat carried into M4/M5**: the full `pnpm
validate` typecheck/lint/test suite has not run in this session's environment (no `node_modules`) — only
`node scripts/check-sync.mjs` could be verified directly. Run full `pnpm validate` before this ships.

## Progress

- Multi-agent coordination 설계안 작성 완료: 실제 generated-project 사고를 범용 규칙으로
  정리하고, opt-in `/coordinate`, immutable SHA review, wave별 single writer,
  Coordinator-only close-out, 3-language 생성·upgrade 검증을 1.4.0 후보 계획으로 제안했다.
  아직 framework-owned 템플릿 구현은 시작하지 않았다.
- **2026-07-23 설계 감사 완료**: 계획안을 이 repo의 실제 강제 장치(`check-sync.mjs`,
  `harness-manifest.json`, 3개 upgrade 스크립트)와 대조해 6개 보완점을 도출·반영했다.
  (A) 루트 `coordinate.md`는 check-sync 명령집합 parity 때문에 필수(선택 아님) —
  누락 시 `pnpm validate` 실패. (B) 새 명령은 check-sync가 못 잡는 4곳(양쪽 AGENTS
  Workflow 표 + 양쪽 CLAUDE.md 명령 목록) 수정 필요. (C) upgrade advisory 옵션은
  스크립트 3개를 건드려야 해 1.4.0에선 기각 — 신규 프로젝트만 섹션 수령, 기존은
  guide+changelog로 인지. (D) clean-handoff는 열린 질문이 아니라 확정 규칙으로 전환:
  커밋 권한 있으면 WIP 커밋, 없으면 명시 선언된 owned diff, silent dirty 인계 금지.
  (E) manifest 등록 누락을 잡을 check-sync 가드 추가. (F) guide/섹션은 한국어 소스
  번역이 아니라 영어로 신작. 모두 계획서 `Design Audit`·Gate M0·M2·M3에 반영됨.
- **2026-07-23 스코프 축소(complexity budget)**: 1.4.0을 저비용·광범위 가치의 코어로
  좁혔다. 유지: guide + AGENTS 핸드오프 규약 + `/coordinate` + `/plan` optional 블록.
  보류(→1.5.0): `/start`·`/commit`·`/review`·`/done` 프롬프트 개조 + `check-agent-scope`
  스코프 체커. 근거는 "solo 사용자가 무시하고 존재조차 모를 수 있나?" 리트머스 —
  핵심 4개 프롬프트 개조는 탈락(100% 사용자가 매번 쓰는 명령에 5% 워크플로 세금).
  deferred 프롬프트의 유일한 범용 규칙(SHA 고정 검토)은 이미 AGENTS 핸드오프 규약에
  포함돼 단일 세션 안전성 손실 없음. 계획서 `Scope Decision`·Scope·§4·§6·M2·M5·수용기준
  전면 반영. un-defer 트리거: 두 번째 실제 멀티 에이전트 프로젝트(n=2).
- **2026-07-23 멀티 휴먼(경량) 반영**: 여러 사람이 한 repo를 작업하는 경우를 계획서 §7로
  정식 반영. 핵심 통찰 — 멀티에이전트와 같은 모델이고 통합 게이트만 PR 리뷰로 바뀜.
  이미 있는 것(per-branch STATUS, append-only worklog, "PRs without tests")에 얹어 opt-in
  문서 1섹션 + optional 템플릿 필드 2개(plan `Owner`, worklog author) + AGENTS 머지 위생
  불릿 1개만 추가. solo 무영향(litmus 통과), 1.4.0 포함.
- **2026-07-23 팀 롤/프로젝트 모드 신규 plan 작성**: setup 시 Solo/Team 선택 + 중간 변경 +
  Team일 때 롤(기획/설계/백/프론트/Data/Infra/QA)별 소유 스코프로 agent가 자동 제약되는
  기능을 별도 plan(`2026-07-23-team-roles-and-project-mode.md`, 잠정 1.5.0)으로 설계.
  핵심 설계: 롤 소유권 = clean-architecture 레이어에 매핑(새 ACL 아님), 롤은 data-driven
  카탈로그, mode/roles는 AGENTS(동작 소스)+`.harness-meta.json`(도구용) 이중화, Solo는
  zero-overhead, prose-first(기계 강제는 1.6.0 `check-agent-scope`로 이연). 1.4.0 이후 착수.
- **2026-07-23 M1 (root prototype) 완료, Gate M1 통과**: 루트 `docs/how-to/multi-agent-
  collaboration.md` 신규 작성(14개 섹션 — applicability notice, §0 병렬화 가치 판단,
  §1 원칙(AGENTS Handoff 참조), §2 이 repo 실제 트리에 맞춘 롤(Docs/Guide, Command/Prompt,
  Language-Pack agent — HomoGraphormer 롤 없음), §3 worktree, §4~11 템플릿, §12 Claude Code
  도구 부록, §13 멀티휴먼/PR게이트, §14 일반화된 사고 근거). 루트 `AGENTS.md`에 `## Handoff
  and Reporting` 섹션 삽입(Work Journal 직후). 통제된 dry run으로 §5 작업 지시서 템플릿을
  실제 M2 하위 작업("harness-core/AGENTS.md에 Handoff 섹션 추가")에 채워 HomoGraphormer
  맥락 없이도 전 필드가 채워짐을 확인. 단순화 1건: §6(상시 소유권 표)과 §5(작업별 override)
  중복처럼 보여 §6 서두에 관계 명시. `node scripts/check-sync.mjs` 통과 확인(이 셸 PATH엔
  pnpm 없어 typecheck/lint/test는 미실행 — 마크다운/AGENTS 텍스트만 변경이라 영향 없음).
- **2026-07-23 root 산출물 리뷰 + 교정**: worktree 경로 `..\..\`→`..\`(깊이 계산 오류,
  다이어그램과 모순됐던 걸 발견), §0·§3의 `see §14`→`see §12`(stale 참조, fork/Agent
  메커니즘은 §12) 2건의 사실 오류 수정. AGENTS Handoff 섹션은 불릿별 근거절을 덜어내
  규칙만 남기고 §14로 포인터(complexity budget 원칙 재적용, clean-handoff 2분기 규칙은
  보존). `node scripts/check-sync.mjs` 재확인 통과.
- **2026-07-23 M2 (generated-project templates) 완료, Gate M2 통과**: `harness-core/docs/
  how-to/multi-agent-collaboration.md` 신규(§2 롤을 Coordinator/Implementation/Test/
  Research-Review/Execution으로 일반화, §3 경로 프로젝트명 중립화, §6 표 일반화, 검증
  명령 `./scripts/validate.sh`, §13 제목을 계획 스펙("Working as a team")과 정확히 맞춤 —
  M1에서 발견한 title-drift를 소스에서 교정). `harness-core/AGENTS.md`에 Handoff 섹션 +
  `/coordinate` 표 행 + "Multiple team members"에 append-only 규칙 불릿 추가.
  `harness-core/CLAUDE.md` + 루트 `AGENTS.md`/`CLAUDE.md`에 `/coordinate` 포인터 4곳 추가.
  `.claude/commands/coordinate.md` 양쪽 사본(harness-core는 언어중립, 루트는 pnpm
  구체적 — 기존 commit.md 분화 패턴 따름). `harness-core/.claude/commands/plan.md`에
  1줄 포인터. `harness-core/.workspace/plans/README.md`에 Parallelization 블록 +
  `Owner` 필드 + worklog author 컬럼 안내(둘 다 `/done.md` 미편집 — 1.4.0 스코프 결정
  준수). `harness-manifest.json`에 `coordinate.md`·guide 등록. `check-sync.mjs`에
  manifest 등록 누락 가드 신규 추가 — 항목 임시 제거 후 실패 확인, 복구 후 통과 확인으로
  가드 자체를 검증(복구 스크립트가 `/tmp` 문제로 실패해 한 번 깨졌던 걸 재확인·수정함).
  검증: 이 실행 환경에 `node_modules` 미설치라 `pnpm validate` 전체는 못 돌렸지만
  `node scripts/check-sync.mjs`(그 스크립트가 첫 단계로 호출하는 것과 동일)는 통과 —
  이번 변경이 `.md`/`.json`/`.mjs`만 건드려 typecheck/lint/test 리스크는 없음. M3에서
  의존성 설치된 환경에서 전체 `pnpm validate` 재확인 필요(계획서에 caveat로 기록).
- **2026-07-23 M3 (version, docs, self-validation) 완료, Gate M3 통과**: `HARNESS-VERSION`
  1.3.0→1.4.0. `FRAMEWORK-CHANGELOG.md`에 1.4.0 항목(근거·Handoff 섹션·guide·`/coordinate`·
  plan 블록·append-only 불릿·1.5.0 이연 근거·check-sync 가드·양쪽 plan 링크 포함). README
  3곳 갱신 — Structure(명령 트리에 `coordinate.md`), Quick Start(`/coordinate` 예시 추가),
  Work Journal(opt-in 조율 레이어 단락 + guide 링크). "Supported AI Tools" 섹션은 개별
  명령이 아니라 tool→config 매핑이라 변경 불필요 판단(이미 있는 범용 문구가 `/coordinate`도
  커버). `node scripts/check-sync.mjs` M3 편집 후 재확인 통과. **M2와 동일한 caveat 유지**:
  이 세션 환경엔 `node_modules` 없어 전체 `pnpm validate`는 미실행 — README/CHANGELOG/
  VERSION은 산문·버전 문자열뿐이라 src/test 영향 없음. 반복해서 "미실행"을 "통과"로
  뭉개지 않고 계속 caveat로 명시 이월.
- `/fix` applied for finding #1: `language-packs/python/tests/arch/test_dependencies.py`
  (E501) and `tests/domain/test_user.py` (F401) fixed directly; root
  cause was that this repo's own `pnpm validate` can never exercise a
  Python pack's sample code (no Python toolchain at the root), so a
  process step was added to `docs/how-to/adding-a-language-pack.md` §7:
  re-run the pack's own `validate.sh`/`.ps1` after *any* edit to shipped
  pack code, not only when adding a new pack. Recorded in
  `HARNESS-CHANGELOG.md`. Root `pnpm validate` reconfirmed clean after.
- `agentic-eacc-mcp-server` upgraded 1.2.0 → 1.3.0 on its still-unmerged
  `chore/harness-upgrade-1.2.0` branch (commit `e0d9c70`, on top of
  `d40aa6c`). Pre-1.3 fallback applied (project had no baselines yet) —
  reviewed the overwrite diff file-by-file rather than blanket-reverting:
  kept the RAG arch-test customization + calendar/zoneinfo stdlib entries
  (re-merged onto the *new* template, which also had this session's E501
  fix), kept the project's own `.pytest-tmp`/no-cache pytest flags in
  `validate.ps1`, kept `.claude/settings.json` pointing at the project's
  Korean-commented `worklog-context.sh` (deleted the redundant
  framework-added `status-context.sh` duplicate), and accepted
  `validate.sh`'s venv-detection rewrite and the new
  `test_project_rules.py` seed as pure improvements. Verified: mypy 46
  files clean, ruff clean, pytest 195 passed / 1 skipped.
- Branch `chore/harness-upgrade-1.2.0` (now carrying both the 1.2.0 and
  1.3.0 upgrades) is still **not merged to `master`** in the eacc repo —
  that decision is the user's, not made this session.

## Next Steps

- **M0 완전히 닫힘** — `Parallelization` 블록 추가 확정(2026-07-23). 블록 전체 스펙은
  계획서 §4 `/plan`에 박아둠. 실제 파일 편집은 framework-owned이라 M2에서 guide/command/
  prompt와 한 묶음으로 처리(버전 범프·changelog 1회).
- **다음: M4 (fresh-generation matrix)** — TS/Python/Java 각각 임시 프로젝트 생성 후 guide·
  명령·Handoff 섹션 존재 확인, `/coordinate`가 단일/다중 케이스 모두 처리하는지 검증.
- 이후 M5~M6: upgrade 호환 매트릭스 → close-out.
- **carry-over**: 의존성 설치된 환경에서 전체 `pnpm validate` 1회 재확인 필요(M2/M3 공통
  caveat) — 이 세션들엔 `node_modules` 없음.
- **팀 롤/모드(1.5.0)**: **Gate T0 완전히 닫힘(2026-07-23)** — 명령 `/team`, 7-롤 카탈로그
  +QA+Reviewer 순환모자, active-role는 명시 선언+브랜치 접두사 보조, mode/roles/roster는
  user data(upgrade 미덮어씀), 1.5.0 prose-only·기계강제는 1.6.0. **1.4.0 착지 후 T1 착수 가능.**
- User's call, whenever: merge/push `chore/harness-upgrade-1.2.0` in the
  `agentic-eacc-mcp-server` repo.

## Blockers / Open Questions

- **없음.** Gate M0의 모든 결정이 해소됨(`/coordinate` 명칭, 1.4.0 minor, clean-handoff
  규칙, 기존 프로젝트 통지 방식, plan 템플릿 `Parallelization` 블록 추가). M1 진입 가능.
