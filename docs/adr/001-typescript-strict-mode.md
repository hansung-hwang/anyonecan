# ADR 001 — TypeScript Strict 모드 사용

- **날짜**: 2026-06-17
- **상태**: Accepted

## 결정

`tsconfig.json`에서 `strict: true` 및 추가 엄격 옵션을 활성화한다.

활성화된 옵션:
- `strict` (noImplicitAny, strictNullChecks 등 포함)
- `noUncheckedIndexedAccess`
- `exactOptionalPropertyTypes`
- `noImplicitReturns`
- `noFallthroughCasesInSwitch`

## 이유

- 런타임 오류(null 참조, 암묵적 any 등)를 컴파일 타임에 조기 발견
- `noUncheckedIndexedAccess`로 배열·레코드 인덱스 접근 시 undefined 방어 강제
- `exactOptionalPropertyTypes`로 선택적 프로퍼티 할당 오류 방지
- 코드 리뷰 시 타입 관련 논의 최소화 — 컴파일러가 자동 검증

## 결과

**허용**
- `unknown` + 타입 가드 패턴으로 동적 데이터 처리
- 불가피한 `as` 단언 (한국어 주석으로 이유 명시 필수)

**금지**
- `any` 타입 직접 사용
- `@ts-ignore` / `@ts-nocheck` 사용
- 이유 없는 `as` 타입 단언 남발
- `tsconfig.json`의 strict 옵션 개별 비활성화
