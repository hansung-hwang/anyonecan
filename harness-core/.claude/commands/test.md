# /test — 테스트 생성

지정한 파일에 대한 단위 테스트를 생성합니다.

## 사용법

```
/test <파일 경로>
```

## 테스트 생성 규칙

### 파일 저장 위치

- **TypeScript**: 소스 파일과 같은 디렉터리에 `[파일명].test.ts`
- **Python**: `tests/` 하위 동일 구조에 `test_[파일명].py`
- **Java**: `src/test/java/` 하위 동일 패키지에 `[ClassName]Test.java`

### 커버리지 기준

- 모든 public 함수/메서드에 최소 1개 이상의 테스트
- 정상 케이스(happy path) + 예외 케이스(edge case) 모두 포함
- 외부 의존성(DB, API, 파일시스템)만 모킹 — 도메인 로직 자체는 모킹하지 않음

### 생성 후 실행

```bash
./scripts/validate.sh
```

실패 시 오류 원인을 분석하고 테스트 코드를 수정합니다.
