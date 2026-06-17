# AGENTS.md — AI 에이전트 작업 규칙 ({{PROJECT_NAME}})

## 세션 시작

새 세션에서 반드시 `/start` 를 실행합니다.
git 상태, 최근 커밋, CLAUDE.md·AGENTS.md를 읽고 현재 목표를 요약합니다.

## 작업 전 규칙

### 1. 변경 파일 먼저 나열
작업을 시작하기 전에 수정할 파일 목록을 반드시 먼저 제시합니다.

```
변경 예정 파일:
- src/domain/user/user-service.ts  (수정)
- src/domain/user/user-service.test.ts  (신규)
```

### 2. 삭제 전 확인
파일 또는 코드 블록을 삭제하기 전에 반드시 사용자에게 확인을 요청합니다.
삭제 이유와 영향 범위를 명확히 설명합니다.

### 3. 범위 외 수정 금지
요청된 작업 범위를 벗어나는 파일은 수정하지 않습니다.
관련 개선 사항이 있다면 작업 완료 후 별도로 제안합니다.

## 환경 설정 규칙

- `.env`, `.env.local`, `.env.*` 파일은 **절대 수정하지 않습니다**
- 새로운 환경 변수가 필요한 경우 `.env.example`에만 추가하고 사용자에게 안내합니다
- 민감한 정보(API 키, 비밀번호, 토큰)를 코드에 하드코딩하지 않습니다

## 완료 후 자동 검증

작업 완료 후 반드시 아래 순서로 실행합니다:

```bash
pnpm typecheck   # 1단계: 타입 검사
pnpm lint        # 2단계: lint 검사
pnpm test        # 3단계: 테스트 실행
```

검증 실패 시 해당 오류를 수정한 뒤 다시 검증합니다.
모든 단계가 통과될 때까지 작업을 완료로 보고하지 않습니다.

## 실수 발생 시 스티어링 루프

실수가 발생하면 `/fix` 를 실행해 하네스를 강화합니다.

| 실수 유형 | 처리 방법 |
|-----------|-----------|
| 린터로 자동 감지 가능 | `eslint.config.js` 규칙 추가 |
| 코드 습관·패턴 문제 | `CLAUDE.md` 금지사항 추가 |
| 아키텍처 설계 결정 | `docs/adr/` 신규 ADR 작성 |

## 상세 가이드

| 주제 | 파일 |
|------|------|
| 모듈/컴포넌트 작성 규칙 | `docs/how-to/component-guide.md` |
| 테스트 작성 가이드 | `docs/how-to/testing-guide.md` |
| 커밋/브랜치 워크플로우 | `docs/how-to/git-workflow.md` |
| 아키텍처 결정 기록 | `docs/adr/` |

## 커밋 컨벤션

```
<type>(<scope>): <한국어 설명>
```

타입: `feat` · `fix` · `refactor` · `test` · `docs` · `chore` · `perf`
상세 내용: `docs/how-to/git-workflow.md` 참고

## 코드 품질 기준

- `any` 사용 금지 — 타입 추론이 안 되면 `unknown` 사용 후 타입 가드 적용
- 새 함수 작성 시 반드시 테스트 파일도 함께 작성
- 아키텍처 의존성 규칙 준수 (domain ← application ← infrastructure ← presentation)
