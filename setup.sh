#!/usr/bin/env bash
# setup.sh — 하네스 엔지니어링 프레임워크 프로젝트 생성 (Mac/Linux)
#
# 사용법: ./setup.sh
#         OUTPUT_DIR=/path/to/dir ./setup.sh
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[0;37m'; NC='\033[0m'

header() { echo -e "\n${CYAN}================================================${NC}\n  ${CYAN}$1${NC}\n${CYAN}================================================${NC}\n"; }
step()   { echo -e "${YELLOW}▶ $1${NC}"; }
ok()     { echo -e "${GREEN}✓ $1${NC}"; }
info()   { echo -e "${GRAY}  $1${NC}"; }

# ── 입력 받기 ──────────────────────────────────────────────────────────────────
header "하네스 엔지니어링 프레임워크 설정"

read -rp "프로젝트명 (영문, 하이픈 허용): " PROJECT_NAME
if [[ -z "$PROJECT_NAME" ]]; then
    echo -e "${RED}오류: 프로젝트명은 필수입니다.${NC}" >&2; exit 1
fi
if [[ ! "$PROJECT_NAME" =~ ^[a-z0-9][a-z0-9\-]*$ ]]; then
    echo -e "${RED}오류: 소문자 영문, 숫자, 하이픈만 사용할 수 있습니다.${NC}" >&2; exit 1
fi

read -rp "프로젝트 설명: " PROJECT_DESCRIPTION
read -rp "저자명: " AUTHOR

echo ""
echo "언어 선택:"
echo "  1. TypeScript (기본값)"
echo "  2. Python"
echo "  3. Java"
read -rp "번호 선택: " LANG_CHOICE

case "${LANG_CHOICE:-1}" in
    2) LANGUAGE="python";     LANGUAGE_DISPLAY="Python" ;;
    3) LANGUAGE="java";       LANGUAGE_DISPLAY="Java" ;;
    *) LANGUAGE="typescript"; LANGUAGE_DISPLAY="TypeScript" ;;
esac

BASE_PACKAGE=""
if [[ "$LANGUAGE" == "java" ]]; then
    SAFE_NAME=$(echo "$PROJECT_NAME" | tr -d '-')
    read -rp "Java 기본 패키지 (기본값: com.example.$SAFE_NAME): " BASE_PACKAGE_INPUT
    BASE_PACKAGE="${BASE_PACKAGE_INPUT:-com.example.$SAFE_NAME}"
fi

read -rp "프로젝트 생성 위치 (기본값: ./$PROJECT_NAME): " OUTPUT_DIR_INPUT
OUTPUT_DIR="${OUTPUT_DIR_INPUT:-./$PROJECT_NAME}"

TODAY=$(date +%Y-%m-%d)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_CORE_DIR="$SCRIPT_DIR/harness-core"
LANG_PACK_DIR="$SCRIPT_DIR/language-packs/$LANGUAGE"

if [[ ! -d "$HARNESS_CORE_DIR" ]]; then
    echo -e "${RED}오류: harness-core/ 를 찾을 수 없습니다: $HARNESS_CORE_DIR${NC}" >&2; exit 1
fi
if [[ ! -d "$LANG_PACK_DIR" ]]; then
    echo -e "${RED}오류: language-packs/$LANGUAGE 를 찾을 수 없습니다: $LANG_PACK_DIR${NC}" >&2; exit 1
fi

echo ""
echo "────────────────────────────────────────────────"
info "프로젝트명    : $PROJECT_NAME"
info "설명          : $PROJECT_DESCRIPTION"
info "저자          : $AUTHOR"
info "언어          : $LANGUAGE_DISPLAY"
[[ "$LANGUAGE" == "java" ]] && info "기본 패키지   : $BASE_PACKAGE"
info "생성 위치     : $OUTPUT_DIR"
echo "────────────────────────────────────────────────"
echo ""

read -rp "계속 진행하시겠습니까? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[yY] ]]; then echo "취소되었습니다."; exit 0; fi

# ── 1. harness-core 복사 ────────────────────────────────────────────────────────
step "harness-core 복사 중..."
mkdir -p "$OUTPUT_DIR"
cp -r "$HARNESS_CORE_DIR/." "$OUTPUT_DIR/"
ok "harness-core 복사 완료"

# ── 2. 언어팩 복사 (harness-core 위에 덮어쓰기) ────────────────────────────────
step "$LANGUAGE_DISPLAY 언어팩 복사 중..."
cp -r "$LANG_PACK_DIR/." "$OUTPUT_DIR/"
ok "언어팩 복사 완료"

# ── 3. 언어별 규칙 → CLAUDE.md 치환 (python3 사용) ────────────────────────────
step "언어별 규칙 적용 중..."

export LANGUAGE OUTPUT_DIR LANGUAGE_DISPLAY

python3 << 'PYEOF'
import os, pathlib

lang    = os.environ["LANGUAGE"]
output  = pathlib.Path(os.environ["OUTPUT_DIR"])
display = os.environ["LANGUAGE_DISPLAY"]

rules = {
    "typescript": (
        "- `any` 금지 → `unknown` + 타입 가드\n"
        "- 모든 함수에 반환 타입 명시 (`explicit-function-return-type`)\n"
        "- `as` 단언은 불가피한 경우에만, 한국어 주석으로 이유 설명\n"
        "- 파일명: `kebab-case.ts` / `.test.ts` / `.types.ts` / `.interface.ts`"
    ),
    "python": (
        "- 타입 힌트 필수 (Python 3.12+, `X | Y` union 스타일)\n"
        "- `Any` 타입 금지 → 구체 타입 사용\n"
        "- 모든 함수에 반환 타입 명시\n"
        "- dataclass 또는 Pydantic 모델 우선 (dict 남발 금지)\n"
        "- 파일명: `snake_case.py` / `test_*.py`"
    ),
    "java": (
        "- `null` 반환 금지 → `Optional<T>` 사용\n"
        "- checked exception 남발 금지 → 도메인 예외는 unchecked\n"
        "- record 클래스 우선 (불변 데이터, Java 16+)\n"
        "- `var` 허용 (타입 추론이 명확한 경우만)\n"
        "- 파일명: `PascalCase.java` / `*Test.java`"
    ),
}

banned = {
    "typescript": "`any` · `@ts-ignore` · `@ts-nocheck` · `@ts-expect-error` · `console.log` · `eslint-disable` 남발",
    "python":     "`Any` · `# type: ignore` · `print()` (로깅 대신) · `pass` 남발",
    "java":       "`null` 반환 · raw type 사용 · `System.out.println` · `@SuppressWarnings` 남발",
}

p = output / "CLAUDE.md"
content = p.read_text(encoding="utf-8")
content = content.replace("{{LANGUAGE_RULES}}", rules[lang])
content = content.replace("{{BANNED_ITEMS}}", banned[lang])
content = content.replace("{{LANGUAGE_DISPLAY}}", display)
p.write_text(content, encoding="utf-8")
PYEOF

ok "언어별 규칙 적용 완료"

# ── 4. 표준 플레이스홀더 치환 ───────────────────────────────────────────────────
step "플레이스홀더 치환 중..."

find "$OUTPUT_DIR" -type f \( \
    -name "*.md" -o -name "*.mdc" -o -name "*.json" \
    -o -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.mjs" \
    -o -name "*.sh" -o -name "*.yaml" -o -name "*.yml" \
    -o -name "*.toml" -o -name "*.xml" -o -name "*.java" \
    -o -name ".cursorrules" -o -name ".windsurfrules" \
\) ! -path "*/node_modules/*" ! -path "*/target/*" | while IFS= read -r file; do
    perl -pi \
        -e "s|\{\{PROJECT_NAME\}\}|$PROJECT_NAME|g" \
        -e "s|\{\{PROJECT_DESCRIPTION\}\}|$PROJECT_DESCRIPTION|g" \
        -e "s|\{\{AUTHOR\}\}|$AUTHOR|g" \
        -e "s|\{\{DATE\}\}|$TODAY|g" \
        "$file"
done

ok "플레이스홀더 치환 완료"

# ── 5. Java: 패키지 디렉터리 생성 + BASE_PACKAGE 치환 ──────────────────────────
if [[ "$LANGUAGE" == "java" ]]; then
    step "Java 패키지 구조 생성 중..."
    BASE_PKG_PATH=$(echo "$BASE_PACKAGE" | tr '.' '/')
    JAVA_SRC_ROOT="$OUTPUT_DIR/src/main/java/$BASE_PKG_PATH"

    for layer in domain application infrastructure presentation; do
        mkdir -p "$JAVA_SRC_ROOT/$layer"
        cat > "$JAVA_SRC_ROOT/$layer/package-info.java" << EOF
/** ${layer} 레이어 */
package $BASE_PACKAGE.$layer;
EOF
    done

    # DependencyTest.java BASE_PACKAGE 치환
    ARCH_TEST="$OUTPUT_DIR/src/test/java/arch/DependencyTest.java"
    if [[ -f "$ARCH_TEST" ]]; then
        perl -pi -e "s|\{\{BASE_PACKAGE\}\}|$BASE_PACKAGE|g" "$ARCH_TEST"
    fi

    ok "Java 패키지 구조 생성 완료 ($BASE_PACKAGE)"
fi

# ── 6. 의존성 설치 ───────────────────────────────────────────────────────────────
step "의존성 설치 중..."
cd "$OUTPUT_DIR"

case "$LANGUAGE" in
    typescript)
        if command -v pnpm &>/dev/null; then
            if ! pnpm install --silent 2>/dev/null; then
                echo -e "${GRAY}  빌드 스크립트 승인 중 (esbuild)...${NC}"
                pnpm approve-builds esbuild --silent 2>/dev/null || true
                pnpm install --silent
            fi
            ok "pnpm install 완료"
        else
            echo -e "${YELLOW}  ⚠ pnpm이 없습니다. 수동으로 실행하세요: pnpm install${NC}"
        fi
        ;;
    python)
        if command -v uv &>/dev/null; then
            uv sync --quiet 2>/dev/null; ok "uv sync 완료"
        elif command -v pip &>/dev/null; then
            pip install ruff mypy pytest pytest-cov -q; ok "pip install 완료"
        else
            echo -e "${YELLOW}  ⚠ uv 또는 pip를 설치하세요.${NC}"
        fi
        ;;
    java)
        if command -v mvn &>/dev/null; then
            ok "Maven 확인됨 (첫 빌드 시 의존성 자동 다운로드)"
        else
            echo -e "${YELLOW}  ⚠ Maven(mvn)이 없습니다. Java 21+ 및 Maven 3.9+를 설치하세요.${NC}"
        fi
        ;;
esac

# ── 7. git init + 첫 커밋 ───────────────────────────────────────────────────────
step "git 초기화 중..."
git init --quiet
git add .
git commit --quiet -m "chore: initialize project with harness engineering framework"
ok "git 초기화 완료 (첫 커밋 생성)"

# ── 8. 완료 메시지 ──────────────────────────────────────────────────────────────
header "✅ 설정 완료!"
echo -e "생성된 프로젝트: ${CYAN}$OUTPUT_DIR${NC}"
echo ""
echo -e "${YELLOW}다음 단계:${NC}"
echo -e "  1. ${CYAN}cd $OUTPUT_DIR${NC}"
echo -e "  2. ${CYAN}claude${NC} 실행"
echo -e "  3. ${CYAN}/start${NC} 입력해서 세션 시작"
echo ""
