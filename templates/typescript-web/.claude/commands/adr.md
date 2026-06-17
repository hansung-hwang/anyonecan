# /adr — ADR 생성

새로운 아키텍처 결정 기록(ADR)을 `docs/adr/` 에 작성합니다.

## 실행 순서

### 1. 기존 ADR 번호 확인

```bash
ls docs/adr/
```

다음 번호(NNN)를 결정합니다.

### 2. ADR 파일 생성

`docs/adr/NNN-<kebab-case-제목>.md` 파일을 아래 형식으로 작성합니다:

```markdown
# ADR NNN — <결정 제목>

- **날짜**: YYYY-MM-DD
- **상태**: Accepted | Deprecated | Superseded by ADR NNN

## 배경

왜 이 결정이 필요했는가.

## 결정

무엇을 하기로 했는가.

## 이유

왜 이 선택이 대안보다 나은가.

## 결과

- 긍정: ...
- 부정(트레이드오프): ...
- 금지사항: ...
```

### 3. CLAUDE.md 참조 추가

관련 제약사항이 있으면 `CLAUDE.md` 아키텍처 섹션에 `(→ docs/adr/NNN)` 링크를 추가합니다.

### 4. 완료 확인

생성한 ADR 경로와 핵심 결정 내용을 한 줄로 요약합니다.
