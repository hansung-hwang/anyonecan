# ADR 002 — ESLint + Prettier 툴체인 선택

- **날짜**: 2026-06-17
- **상태**: Accepted

## 결정

코드 품질 검사는 ESLint(`@typescript-eslint/recommended-requiring-type-checking`),
포맷팅은 Prettier로 역할을 분리한다.

PostToolUse Hook(`scripts/lint-format-hook.mjs`)으로 파일 저장 시 자동 실행한다.

## 이유

- ESLint와 Prettier의 역할 분리로 각각의 강점만 활용
- `@typescript-eslint/recommended-requiring-type-checking`으로 타입 기반 린팅 활성화
  — 타입 정보를 활용한 `no-floating-promises`, `await-thenable` 등 오류 자동 탐지
- PostToolUse Hook으로 파일 저장 시 자동 포맷 → 수동 포맷 작업 제거
- ESLint flat config(`eslint.config.js`) 사용으로 v9 호환성 확보

## 결과

**허용**
- 특정 줄에 한해 `// eslint-disable-next-line <rule>` (이유 주석 필수)
- `eslint.config.js`의 `ignores` 배열에 빌드 산출물 추가

**금지**
- `// eslint-disable` 블록 단위 비활성화
- 소스 파일을 `ignores`에 추가
- 직접 수동 포맷팅(Hook이 자동 처리)
- Prettier 설정(`.prettierrc`) 임의 변경
