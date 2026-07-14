# Apply Harness 1.2.0 to agentic-eacc-mcp-server

- **Date**: 2026-07-14
- **Status**: Done

## Goal

`agentic-eacc-mcp-server/` (this repo root에 있는 별도 git 저장소, Python)는
버전 관리 도입 이전 하네스로 생성된 프로젝트다. P1–P5 업그레이드
(1.2.0)를 이 프로젝트에 적용하되, **구현 코드(`src/`)에는 영향이 없어야
한다**. 사용자 결정 사항 2건 확정:

1. 세션 기록은 프로젝트 자체 컨벤션(`docs/worklog.md` +
   `docs/investigations/` + SessionStart 훅) → **`.workspace/`로 전환**.
2. CI 커버리지 게이트(domain ≥ 80%)는 **커버리지를 먼저 측정한 뒤 결정**.

## Approach

`upgrade.ps1`을 쓰되 그대로는 못 돌린다 — 프로젝트에 `.harness-meta.json`이
없어(pre-versioning) 언어별 파일이 전부 스킵되기 때문. 절차:

1. 메타 파일 수동 생성 → 2. upgrade.ps1 실행 → 3. 커스터마이즈 파일 선별
복원 → 4. `.workspace/` 이관 → 5. 커버리지 측정 후 게이트 결정 → 6. P1
포인터화(수동) → 7. 프로젝트 저장소에 브랜치로 커밋.

**사전 조사에서 확인된 커스터마이즈 파일 (블라인드 덮어쓰기 금지):**

| 파일 | 커스터마이즈 내용 | 처리 |
|---|---|---|
| `tests/arch/test_dependencies.py` | `test_rag_heavy_modules_not_imported_at_boot` + `calendar`/`zoneinfo` stdlib 허용 | 프로젝트 버전 유지 (`git checkout`) |
| `.claude/settings.json` | `SessionStart` 훅 (`scripts/worklog-context.sh`) — 팩 버전 + 훅 구조 | 프로젝트 버전 유지, 훅 스크립트 경로만 `.workspace`로 갱신 |
| `.claude/commands/start.md` | `docs/worklog.md`/`docs/investigations/` 읽는 자체 컨벤션 | `.workspace` 전환이므로 **새 버전 채택** |
| `docs/adr/001` | Python 특화 문구 | 프로젝트 버전 유지 (`git checkout`) |

**안전 확인 완료:** `validate.sh`/`lint-format-hook.sh`/`.husky/pre-commit`은
이미 최신과 동일. `commit/fix/coverage` 커맨드 차이는 옛 프레임워크
버전일 뿐(커스터마이즈 아님). `docs/how-to/`엔 README.md만 있어 신규
문서와 이름 충돌 없음. 프로젝트 git 클린 (`1c4a327`).

## Checklist

- [x] 0. 프로젝트에 브랜치 생성 `chore/harness-upgrade-1.2.0`
- [x] 1. `.harness-meta.json` 작성 (language=python, createdDate=2026-06-29,
      author=hansung-hwang, projectName/description은 AGENTS.md 헤더에서)
- [x] 2. `upgrade.ps1 -ProjectDir .\agentic-eacc-mcp-server` 실행 — 17개
      파일 갱신 (frameworkOwned + python languageSpecific + bootstrap)
- [x] 3. 복원: arch 테스트, ADR-001, settings.json 전부 `git checkout`
      (settings.json은 팩+훅 상위집합이라 병합 불필요였음)
- [x] 4. `.workspace/` 이관: `git mv docs/worklog.md → .workspace/worklog.md`
      (이력 보존, 프레임워크 헤더+표 prepend, 기존 내용은 legacy 섹션),
      STATUS.md 실스냅샷 작성, `worklog-context.sh`를 STATUS.md 출력으로
      변경(파일명·settings.json은 유지), investigations README legacy 전환,
      README/how-to README 참조 갱신 (이력 문서 내 참조는 의도적으로 보존)
- [x] 5. 커버리지 측정 → **domain 98%** (194 passed) ≥ 80% → 게이트 포함
- [x] 6. P1 포인터화: CLAUDE.md → `@AGENTS.md` 포인터 + Claude Extras,
      AGENTS.md가 단일 소스(Work Journal 섹션 신설, steering loop 3단계
      단일소스 문구, plan/done 행 추가), .cursorrules/.windsurfrules/
      harness.mdc 포인터화
- [x] 7. 검증: venv 기준 mypy 0 err(46 files), ruff 통과, pytest 194 passed
      1 skipped (arch 테스트 포함). ⚠ `bash scripts/validate.sh`는 venv가
      아닌 시스템 Python을 집어 mypy import 에러 — 기존 환경 문제(프로젝트
      worklog에도 기록된 알려진 사항), 이번 변경과 무관
- [x] 8. git diff 전체 리뷰 → 사용자 승인 후 커밋 `d40aa6c`
      (`chore/harness-upgrade-1.2.0`, 24 files, +475/−280). 커밋 후 전수
      점검 완료: 매니페스트 21개 파일 중 18 MATCH / 3 DIFFERS(전부 의도된
      보존 — settings.json 훅, arch RAG 테스트, ADR Python 문구), CI 게이트
      실측 통과(97.56% ≥ 80%, exit 0), stale 참조 0건, 훅 정상 동작.

## Notes

- pyproject.toml의 P3 항목(ruff T20 등)은 사용자 소유 — 이번 범위에서
  제외, 커버리지 측정 결과 보고 시 같이 제안만.
- 프레임워크 차원 교훈: frameworkOwned로 분류된 `.claude/commands/*.md`를
  사용자가 커스터마이즈한 실사례 발견(start.md). upgrade가 이를 조용히
  덮어씀 — 향후 3-way 비교 or 로컬 오버라이드 메커니즘 검토 가치 있음.
  (이번 범위 아님, 아이디어만 기록)
- 이 작업의 커밋은 **agentic-eacc-mcp-server 저장소**에 생긴다. 프레임워크
  저장소에는 이 플랜/워크로그 외 변경 없음.
