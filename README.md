# 하네스 엔지니어링 프레임워크

## 개념

**하네스 엔지니어링**이란 AI 에이전트가 실수하기 어려운 환경을 미리 설계하는 것입니다.
타입 시스템, 린터 규칙, 아키텍처 테스트, 워크플로우 프롬프트를 조합해 에이전트의 행동을 제약하고,
실수가 발생하면 규칙을 강화(`/fix`)하는 **스티어링 루프**로 점진적으로 고도화됩니다.

이 프레임워크는 어떤 프로젝트든 `setup.ps1` / `setup.sh` 한 번으로
하네스가 적용된 새 프로젝트를 생성합니다.

---

## 지원 AI 도구

어느 AI 코딩 도구를 사용하든 동일한 하네스 규칙이 적용됩니다.

| 도구 | 읽는 파일 |
|------|-----------|
| Claude Code | `CLAUDE.md` + `.claude/commands/` (슬래시 커맨드) |
| Cursor | `.cursor/rules/harness.mdc` 또는 `.cursorrules` |
| Windsurf | `.windsurfrules` |
| Codex / Antigravity / 기타 | `AGENTS.md` |

> `.claude/commands/*.md` 의 워크플로우 프롬프트는 Claude Code 외 도구에서도
> 파일 내용을 복사해 프롬프트로 사용할 수 있습니다.

---

## 지원 언어

| 언어 | 검증 도구 | 아키텍처 테스트 |
|------|-----------|----------------|
| TypeScript | tsc + ESLint + Vitest | `src/tests/arch/dependencies.test.ts` |
| Python | mypy + ruff + pytest | `tests/arch/test_dependencies.py` |
| Java | Maven + Checkstyle + JUnit5 | `src/test/java/arch/DependencyTest.java` (ArchUnit) |

---

## 구조

```
.
├── harness-core/              # 언어 무관 공통 (모든 프로젝트에 복사)
│   ├── CLAUDE.md              # Claude Code 전용 규칙 템플릿
│   ├── AGENTS.md              # 범용 에이전트 규칙 템플릿
│   ├── .cursorrules           # Cursor 레거시
│   ├── .cursor/rules/harness.mdc  # Cursor MDC
│   ├── .windsurfrules         # Windsurf
│   ├── .claude/
│   │   ├── settings.json      # Stop 훅 (validate.sh 자동 실행)
│   │   └── commands/          # 워크플로우 프롬프트 (모든 도구 공통)
│   │       ├── start.md       # 세션 시작
│   │       ├── fix.md         # 오류 수정 루프
│   │       ├── commit.md      # 커밋 전 검사
│   │       ├── review.md      # 코드 리뷰
│   │       ├── test.md        # 테스트 작성
│   │       ├── adr.md         # 아키텍처 결정 기록
│   │       └── coverage.md    # 커버리지 확인
│   ├── .husky/pre-commit      # 커밋 전 validate.sh 자동 실행
│   ├── .github/workflows/ci.yml
│   ├── .editorconfig
│   ├── HARNESS-CHANGELOG.md
│   └── docs/adr/001-clean-architecture-layers.md
│
├── language-packs/
│   ├── typescript/            # tsconfig · ESLint · Vitest · 아키텍처 테스트
│   ├── python/                # pyproject.toml · ruff · mypy · pytest
│   └── java/                  # pom.xml · Checkstyle · ArchUnit
│
├── setup.ps1                  # 프로젝트 생성 (Windows)
└── setup.sh                   # 프로젝트 생성 (Mac / Linux)
```

---

## 빠른 시작

```bash
git clone https://github.com/hansung-hwang/anyonecan.git
cd anyonecan
```

**Windows**
```powershell
.\setup.ps1
```

**Mac / Linux**
```bash
chmod +x setup.sh
./setup.sh
```

프롬프트에 따라 입력:

```
프로젝트명 (영문, 하이픈 허용): my-service
프로젝트 설명: 주문 관리 서비스
저자명: hansung-hwang
언어 선택: 1=TypeScript / 2=Python / 3=Java
프로젝트 생성 위치 (기본값: ./my-service):
```

완료 후 자동 실행:
1. `harness-core/` 복사
2. 언어팩 오버레이 (harness-core 위에 덮어쓰기)
3. `{{PROJECT_NAME}}` 등 플레이스홀더 치환
4. Java의 경우 패키지 디렉터리 구조 자동 생성
5. 의존성 설치 (`pnpm install` / `uv sync` / Maven 확인)
6. `git init` + 첫 커밋

생성된 프로젝트에서:
```bash
cd my-service
claude        # Claude Code 사용 시
# /start      # 세션 시작
```

---

## 아키텍처 원칙

레이어 의존성 (단방향):

```
domain  ←  application  ←  infrastructure  ←  presentation
```

- `domain`: 순수 비즈니스 로직, 외부 라이브러리 의존 금지
- `application`: 유스케이스, domain 조율
- `infrastructure`: DB, 외부 API, 파일 시스템
- `presentation`: UI, REST/GraphQL 라우터

이 규칙은 언어별 아키텍처 테스트로 자동 강제됩니다.

---

## 스티어링 루프

에이전트가 실수했을 때 동일한 실수가 반복되지 않도록 하네스를 강화합니다.

```
실수 발생
    ↓
/fix 실행  (Claude Code) 또는  fix.md 프롬프트 사용  (다른 도구)
    ↓
실수 유형 분류
    ├── 린터로 자동 감지 가능  →  린터 설정 파일에 규칙 추가
    ├── 코드 습관/패턴 문제    →  AGENTS.md + CLAUDE.md에 추가
    └── 아키텍처 결정         →  docs/adr/ 신규 ADR 작성
    ↓
./scripts/validate.sh 통과 확인
    ↓
HARNESS-CHANGELOG.md에 기록
    ↓
하네스 강화 완료
```

---

## 새 언어팩 추가하는 법

1. `language-packs/<언어명>/` 폴더 생성
2. 필수 파일 작성:
   - `scripts/validate.sh` — 해당 언어 검증 명령
   - `scripts/lint-format-hook.sh` — PostToolUse 훅용 (선택)
   - `.claude/settings.json` — 훅 설정
   - `.github/workflows/ci.yml` — CI 설정
   - `src/tests/arch/` 또는 동등한 경로에 아키텍처 테스트
3. `setup.ps1` / `setup.sh`에 언어 선택지 및 언어별 규칙 추가
4. `pnpm validate`로 프레임워크 자체 검증 통과 확인
