# CLAUDE.md

> 상세 가이드: `docs/how-to/` | 아키텍처 결정: `docs/adr/`

## 세션 시작

새 세션마다 `/start` 실행 — git 상태·최근 커밋·현재 목표를 요약합니다.

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

실수 발생 시 `/fix` 실행 →
- 린터로 막을 수 있으면 `eslint.config.js`에 규칙 추가
- 습관/패턴 문제면 이 파일(CLAUDE.md)에 추가
- 아키텍처 결정이면 `docs/adr/`에 신규 ADR 작성
