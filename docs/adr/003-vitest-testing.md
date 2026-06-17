# ADR 003 — Vitest 테스트 프레임워크 선택

- **날짜**: 2026-06-17
- **상태**: Accepted

## 결정

테스트 프레임워크로 Jest 대신 Vitest를 사용한다.

## 이유

- **ESM-native 지원** — `"type": "module"` 프로젝트에서 별도 변환 설정 없이 동작
- **빠른 실행 속도** — Vite 기반 변환으로 TypeScript 파일을 직접 실행, 빌드 단계 없음
- **Jest 호환 API** — `describe`, `it`, `expect` 등 동일한 인터페이스 제공, 마이그레이션 비용 없음
- **네이티브 커버리지** — `@vitest/coverage-v8`으로 V8 엔진 내장 커버리지 측정

## 결과

**허용**
- `vitest.config.ts`를 통한 커스텀 설정 (필요 시 생성)
- `pnpm test:coverage`로 커버리지 리포트 생성
- 테스트 파일을 소스 파일과 같은 디렉터리 또는 `src/tests/`에 위치

**금지**
- Jest 또는 다른 테스트 프레임워크 혼용 설치
- 테스트 없이 비즈니스 로직 PR 제출
- 도메인 로직 커버리지 80% 미만 유지
- `it.only` / `describe.only` 커밋 (로컬 디버깅용만 허용)
