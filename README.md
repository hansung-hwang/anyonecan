# 나만의 하네스 엔지니어링 프레임워크

## 개념

**하네스 엔지니어링**이란 AI 에이전트가 실수하기 어려운 환경을 미리 설계하는 것입니다.
타입 시스템, 린터 규칙, 아키텍처 테스트, 슬래시 커맨드를 조합해 에이전트의 행동을 제약하고,
실수가 발생하면 규칙을 강화(`/fix`)하는 **스티어링 루프**로 점진적으로 고도화됩니다.

이 프레임워크는 어떤 프로젝트든 `git clone` 후 `setup.ps1` / `setup.sh` 한 번으로
하네스가 적용된 새 프로젝트를 생성합니다.

---

## 포함된 것들

### 템플릿

| 템플릿 | 경로 | 설명 |
|--------|------|------|
| `typescript-web` | `templates/typescript-web/` | TypeScript 웹 앱 (기본) |

### 각 파일의 역할

| 파일 | 역할 |
|------|------|
| `CLAUDE.md` | Claude Code 세션마다 읽는 핵심 규칙 (50줄 이내) |
| `AGENTS.md` | 에이전트 행동 규칙 (삭제 전 확인, 범위 외 수정 금지 등) |
| `eslint.config.js` | 코드 품질 자동 강제 (`any` 금지, 반환 타입 명시 등) |
| `vitest.config.ts` | 테스트 실행 + 커버리지 80% 임계값 설정 |
| `.claude/settings.json` | PostToolUse Hook — 파일 저장 시 lint/format 자동 실행 |
| `.claude/commands/start.md` | `/start` — 세션 시작 루틴 |
| `.claude/commands/fix.md` | `/fix` — 실수 발생 시 스티어링 루프 |
| `.claude/commands/review.md` | `/review` — 코드 리뷰 자동화 |
| `.claude/commands/commit.md` | `/commit` — 검증 후 커밋 자동화 |
| `src/tests/arch/` | 레이어 의존성 아키텍처 테스트 (CI에서 자동 실행) |
| `docs/adr/` | 아키텍처 결정 기록 |
| `docs/how-to/` | 상세 가이드 (컴포넌트, 테스트, git 워크플로우) |

---

## 사용법

### 빠른 시작 (3단계)

```
1. git clone https://github.com/<your-id>/harness-framework
2. ./setup.ps1   (Windows) 또는   ./setup.sh   (Mac/Linux)
3. cd <프로젝트명> && claude → /start
```

### 상세 사용법

**Windows (PowerShell)**

```powershell
git clone https://github.com/<your-id>/harness-framework
cd harness-framework
.\setup.ps1
```

프롬프트에 따라 입력:
- 프로젝트명 (예: `my-todo-app`)
- 프로젝트 설명
- 저자명
- 기술스택 (기본값: TypeScript, React, Vite)
- 템플릿 선택 (현재: 1. typescript-web)
- 생성 위치 (기본값: `./프로젝트명`)

**Mac / Linux (bash)**

```bash
git clone https://github.com/<your-id>/harness-framework
cd harness-framework
chmod +x setup.sh
./setup.sh
```

setup 완료 후 자동으로:
1. 플레이스홀더 치환 (`{{PROJECT_NAME}}` 등)
2. `pnpm install` 실행
3. `git init` + 첫 커밋 생성

---

## 새 템플릿 추가하는 법

### 1. 템플릿 폴더 생성

```
templates/
  typescript-web/    ← 기존
  react-native/      ← 새로 추가
    CLAUDE.md
    AGENTS.md
    package.json
    ...
```

### 2. setup.ps1 / setup.sh에 옵션 추가

`setup.ps1` 내 템플릿 선택 부분:

```powershell
Write-Host "  1. typescript-web (TypeScript 웹 애플리케이션)"
Write-Host "  2. react-native (React Native 앱)"   # 추가

$TemplateName = switch ($TemplateChoice) {
    "1" { "typescript-web" }
    "2" { "react-native" }   # 추가
    default { "typescript-web" }
}
```

`setup.sh` 내 동일한 위치에 추가:

```bash
echo "  2. react-native (React Native 앱)"

case "$TEMPLATE_CHOICE" in
    2) TEMPLATE_NAME="react-native" ;;
esac
```

### 3. 템플릿 유효성 검사

```bash
bash scripts/validate-template.sh
```

---

## 스티어링 루프

에이전트가 실수했을 때 동일한 실수가 반복되지 않도록 하네스를 강화합니다.

```
실수 발생
    ↓
/fix 실행
    ↓
실수 유형 분류
    ├── 린터로 자동 감지 가능  →  eslint.config.js 규칙 추가
    ├── 코드 습관/패턴 문제    →  CLAUDE.md 금지사항 추가
    └── 아키텍처 결정         →  docs/adr/ 신규 ADR 작성
    ↓
pnpm validate 통과 확인
    ↓
하네스 강화 완료
```

시간이 지날수록 `CLAUDE.md`와 `eslint.config.js`가 두꺼워지면서
에이전트가 같은 실수를 반복하기 어려운 환경이 만들어집니다.
