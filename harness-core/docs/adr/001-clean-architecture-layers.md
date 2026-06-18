# ADR 001 — Clean Architecture 레이어 의존성

- **날짜**: {{DATE}}
- **상태**: Accepted

## 결정

`domain` ← `application` ← `infrastructure` ← `presentation` 단방향 의존성을 강제한다.
아키텍처 테스트(`src/tests/arch/` 또는 `tests/arch/`)로 이를 자동 감시한다.

## 이유

- `domain` 레이어를 외부 라이브러리와 분리해 변경에 강한 비즈니스 로직 구성
- 레이어 경계를 자동화 테스트로 감시해 회귀 방지
- 의존성 방향이 명확하면 코드 리뷰 시 구조적 논의 최소화

## 결과

**허용**
- `domain`에서 표준 라이브러리 사용 (예: `java.util`, `os`, Node.js `path`)

**금지**
- `domain`에서 외부 라이브러리 직접 import
- 하위 레이어(`domain`)에서 상위 레이어(`application` 이상) import
