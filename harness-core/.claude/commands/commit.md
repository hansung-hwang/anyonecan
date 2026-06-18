# /commit — 커밋 자동화

변경 사항을 분석해 커밋 메시지를 제안하고, 검증 통과 시 커밋합니다.

## 실행 순서

### 1단계: 사전 스캔

커밋 전 아래 항목을 grep으로 확인합니다:

```bash
# 테스트 고정(test.only / describe.only 등) 잔존 여부
grep -rn "\.only(" src/ tests/ 2>/dev/null || true

# 디버그 출력 잔존 여부 (언어에 맞게)
grep -rn "console\.log\|print(\|System\.out\.print" src/ 2>/dev/null || true
```

잔존 항목 발견 시 커밋을 **중단**하고 해당 위치를 보고합니다.

### 2단계: 검증

```bash
./scripts/validate.sh
```

검증 실패 시 커밋을 중단하고 오류 내용을 보고합니다.

### 3단계: 변경 분석

`git diff --staged`를 분석해 변경 내용을 파악합니다.

### 4단계: 커밋 메시지 제안

```
<type>(<scope>): <한국어 설명>

[변경 이유 및 맥락 — 선택]
[Closes #이슈번호 — 선택]
```

### 5단계: 사용자 확인 후 커밋

## 커밋 타입

| 타입 | 기준 |
|------|------|
| `feat` | 새 기능 |
| `fix` | 버그 수정 |
| `refactor` | 동작 변화 없는 구조 개선 |
| `test` | 테스트 추가/수정 |
| `docs` | 문서 변경 |
| `chore` | 설정·패키지 변경 |

## 주의사항

- 사전 스캔 + 검증 모두 통과해야만 커밋
- `--no-verify` 사용 금지
- staged 파일 없으면 커밋 안 함
