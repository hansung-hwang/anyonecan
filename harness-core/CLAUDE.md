# CLAUDE.md — {{PROJECT_NAME}}

> **프로젝트**: {{PROJECT_DESCRIPTION}}
> **언어**: {{LANGUAGE_DISPLAY}}
> **작성자**: {{AUTHOR}} | **생성일**: {{DATE}}
>
> 상세 가이드: `docs/how-to/` | 아키텍처 결정: `docs/adr/`

## 세션 시작

새 세션마다 `/start` 실행 — git 상태·최근 커밋·현재 목표를 요약합니다.

## 아키텍처

레이어 의존성 (단방향): `domain` ← `application` ← `infrastructure` ← `presentation`
`domain` 레이어는 외부 라이브러리 의존 금지. (→ `docs/adr/001`)

## 코딩 규칙

{{LANGUAGE_RULES}}

- 주석: 한국어, WHY만 작성 (WHAT은 코드가 설명)

## 금지사항

{{BANNED_ITEMS}} · `.env` 직접 수정 · 테스트 없는 PR

## 검증

```bash
./scripts/validate.sh
```

## 스티어링 루프

실수 발생 시 `/fix` 실행 →
- 린터로 막을 수 있으면 린터 설정 파일에 규칙 추가
- 습관/패턴 문제면 이 파일(CLAUDE.md)에 추가
- 아키텍처 결정이면 `docs/adr/`에 신규 ADR 작성
