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
Next is M1 (root prototype), then M2 template implementation.

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
- **다음: M1 (root prototype)** — framework 기여자용 guide 초안 작성, 루트 AGENTS에
  핸드오프 규약 프로토타입, 실제/모의 작업으로 프로토콜 검증 후 harness-core로 백포트.
- 이후 M2~M6: 템플릿 구현 → manifest/version/docs → 3-language 생성 매트릭스 →
  upgrade 호환 매트릭스 → close-out.
- **팀 롤/모드(1.5.0)**: **Gate T0 완전히 닫힘(2026-07-23)** — 명령 `/team`, 7-롤 카탈로그
  +QA+Reviewer 순환모자, active-role는 명시 선언+브랜치 접두사 보조, mode/roles/roster는
  user data(upgrade 미덮어씀), 1.5.0 prose-only·기계강제는 1.6.0. **1.4.0 착지 후 T1 착수 가능.**
- User's call, whenever: merge/push `chore/harness-upgrade-1.2.0` in the
  `agentic-eacc-mcp-server` repo.

## Blockers / Open Questions

- **없음.** Gate M0의 모든 결정이 해소됨(`/coordinate` 명칭, 1.4.0 minor, clean-handoff
  규칙, 기존 프로젝트 통지 방식, plan 템플릿 `Parallelization` 블록 추가). M1 진입 가능.
