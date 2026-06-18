# /coverage — 커버리지 리포트

테스트 커버리지를 실행하고 미달 영역을 보고합니다.

## 실행 (언어별)

**TypeScript**: `pnpm test:coverage`
**Python**: `python -m pytest --cov=src --cov-report=term-missing`
**Java**: `mvn verify -P coverage` (JaCoCo)

## 결과 분석

- `domain` 레이어 목표: **80% 이상**
- 0% 함수: 미테스트 비즈니스 로직 위험

## 보고 형식

```
## 커버리지 현황

| 레이어 | 구문 | 브랜치 | 함수 | 상태 |
|--------|------|--------|------|------|
| domain | XX%  | XX%    | XX%  | ✅/⚠ |

### 미테스트 항목 (함수 커버리지 0%)
- `파일명`: 함수명
```

커버리지 80% 미달인 domain 파일에 대해 테스트 케이스를 제안합니다.
