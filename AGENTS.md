# AGENTS.md — anyonecan (하네스 엔지니어링 프레임워크)

> **⚠ 이 파일은 프레임워크 자체 개발용입니다.**
> 새 프로젝트를 만들려면 `setup.ps1` (Windows) 또는 `./setup.sh` (Mac/Linux) 실행 후,
> 생성된 프로젝트 디렉터리에서 AI 도구를 실행하세요.
>
> **언어**: TypeScript
> 이 파일은 **모든 AI 코딩 도구**에서 읽힙니다 (Claude Code, Cursor, Windsurf, Codex 등).
> Claude Code 사용 시 `CLAUDE.md`의 슬래시 커맨드도 함께 사용할 수 있습니다.

## 아키텍처

레이어 의존성 (단방향): `domain` ← `application` ← `infrastructure` ← `presentation`
`src/domain`은 외부 라이브러리 import 금지. (→ `docs/adr/001`)

## 코딩 규칙

- `any` 금지 → `unknown` + 타입 가드
- 모든 함수에 반환 타입 명시 (`explicit-function-return-type`)
- `as` 단언은 불가피한 경우에만, 한국어 주석으로 이유 설명
- 파일명: `kebab-case.ts` / `.test.ts` / `.types.ts` / `.interface.ts`
- 주석: 한국어, WHY만 작성 (WHAT은 코드가 설명)

## 금지사항

`any` · `@ts-ignore` · `@ts-nocheck` · `@ts-expect-error` · `console.log` · `eslint-disable` 남발 · `.env` 직접 수정 · 테스트 없는 PR

## 검증

```bash
pnpm validate   # typecheck + lint + test
```

## 스티어링 루프

실수 발생 시:
1. `pnpm validate`로 오류 확인
2. 린터로 막을 수 있으면 `eslint.config.js`에 규칙 추가
3. 습관/패턴 문제면 이 파일(AGENTS.md)과 `CLAUDE.md`에 추가 (두 파일 동기화)
4. 아키텍처 결정이면 `docs/adr/`에 신규 ADR 작성
5. `HARNESS-CHANGELOG.md`에 변경 내용 기록

## 워크플로우 프롬프트

`.claude/commands/` 폴더의 마크다운 파일은 **AI 도구 공통 프롬프트**입니다.

| 파일 | 용도 | Claude Code |
|---|---|---|
| `start.md` | 세션 시작 — git 상태·최근 커밋·목표 파악 | `/start` |
| `fix.md` | 오류 수정 루프 — 원인 분석·규칙 추가 | `/fix` |
| `commit.md` | 커밋 전 사전 검사 | `/commit` |
| `review.md` | 코드 리뷰 | `/review` |
| `test.md` | 테스트 작성 가이드 | `/test` |
| `adr.md` | 아키텍처 결정 기록 | `/adr` |
| `coverage.md` | 테스트 커버리지 확인 | `/coverage` |

**Claude Code 이외 도구**: 해당 파일 내용을 복사하여 프롬프트로 사용하세요.
