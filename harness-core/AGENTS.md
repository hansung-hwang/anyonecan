# AGENTS.md — {{PROJECT_NAME}}

> **프로젝트**: {{PROJECT_DESCRIPTION}}
> **언어**: {{LANGUAGE_DISPLAY}}
> **작성자**: {{AUTHOR}} | **생성일**: {{DATE}}
>
> 이 파일은 **모든 AI 코딩 도구**에서 읽힙니다 (Claude Code, Cursor, Windsurf, Codex 등).
> 상세 가이드: `docs/how-to/` | 아키텍처 결정: `docs/adr/`

## 아키텍처

레이어 의존성 (단방향): `domain` ← `application` ← `infrastructure` ← `presentation`
`domain` 레이어는 외부 라이브러리 의존 금지. (→ `docs/adr/001`)

## 코딩 규칙

{{LANGUAGE_RULES}}

- 주석: 한국어, WHY만 작성 (WHAT은 코드가 설명)

## 금지사항

{{BANNED_ITEMS}} · `.env` 직접 수정 · 테스트 없는 PR

## 검증

코드 수정 후 항상 실행:

```bash
./scripts/validate.sh
```

## 스티어링 루프

실수 발생 시:
1. `./scripts/validate.sh`로 오류 확인
2. 린터로 막을 수 있으면 린터 설정 파일에 규칙 추가
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
