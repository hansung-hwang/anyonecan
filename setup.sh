#!/usr/bin/env bash
# setup.sh — 하네스 엔지니어링 프레임워크 프로젝트 생성 스크립트 (Mac/Linux)
#
# 사용법: ./setup.sh
#         OUTPUT_DIR=/path/to/dir ./setup.sh
set -euo pipefail

# ── 색상 정의 ──────────────────────────────────────────────────────────────────
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

read -rp "기술스택 (기본값: TypeScript, React, Vite): " TECH_STACK_INPUT
TECH_STACK="${TECH_STACK_INPUT:-TypeScript, React, Vite}"

echo ""
echo "템플릿 선택:"
echo "  1. typescript-web — TypeScript 웹 애플리케이션 (기본값)"
read -rp "번호 선택: " TEMPLATE_CHOICE
TEMPLATE_CHOICE="${TEMPLATE_CHOICE:-1}"

case "$TEMPLATE_CHOICE" in
    1|"") TEMPLATE_NAME="typescript-web" ;;
    *)
        echo -e "${YELLOW}  알 수 없는 선택. typescript-web 으로 진행합니다.${NC}"
        TEMPLATE_NAME="typescript-web"
        ;;
esac

read -rp "프로젝트 생성 위치 (기본값: ./$PROJECT_NAME): " OUTPUT_DIR_INPUT
OUTPUT_DIR="${OUTPUT_DIR_INPUT:-./$PROJECT_NAME}"

TODAY=$(date +%Y-%m-%d)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/templates/$TEMPLATE_NAME"

if [[ ! -d "$TEMPLATE_DIR" ]]; then
    echo -e "${RED}오류: 템플릿을 찾을 수 없습니다: $TEMPLATE_DIR${NC}" >&2; exit 1
fi

# 설정 요약 출력
echo ""
echo "────────────────────────────────────────────────"
info "프로젝트명    : $PROJECT_NAME"
info "설명          : $PROJECT_DESCRIPTION"
info "저자          : $AUTHOR"
info "기술스택      : $TECH_STACK"
info "템플릿        : $TEMPLATE_NAME"
info "생성 위치     : $OUTPUT_DIR"
echo "────────────────────────────────────────────────"
echo ""

read -rp "계속 진행하시겠습니까? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[yY] ]]; then
    echo "취소되었습니다."; exit 0
fi

# ── 1. 파일 복사 ───────────────────────────────────────────────────────────────
step "파일 복사 중..."
mkdir -p "$OUTPUT_DIR"
# 숨김 파일(.claude 등) 포함 복사
cp -r "$TEMPLATE_DIR/." "$OUTPUT_DIR/"
ok "파일 복사 완료"

# ── 2. 플레이스홀더 치환 ────────────────────────────────────────────────────────
step "플레이스홀더 치환 중..."

# macOS(BSD sed)와 Linux(GNU sed) 모두 호환되도록 perl 사용
find "$OUTPUT_DIR" -type f \( \
    -name "*.md" -o -name "*.json" -o -name "*.ts" -o -name "*.tsx" \
    -o -name "*.js" -o -name "*.mjs" -o -name "*.sh" \
    -o -name "*.yaml" -o -name "*.yml" \
\) ! -path "*/node_modules/*" | while IFS= read -r file; do
    perl -pi \
        -e "s|\{\{PROJECT_NAME\}\}|$PROJECT_NAME|g" \
        -e "s|\{\{PROJECT_DESCRIPTION\}\}|$PROJECT_DESCRIPTION|g" \
        -e "s|\{\{AUTHOR\}\}|$AUTHOR|g" \
        -e "s|\{\{TECH_STACK\}\}|$TECH_STACK|g" \
        -e "s|\{\{DATE\}\}|$TODAY|g" \
        "$file"
done

ok "플레이스홀더 치환 완료"

# ── 3. pnpm install ─────────────────────────────────────────────────────────────
step "pnpm install 실행 중..."
cd "$OUTPUT_DIR"
if command -v pnpm &>/dev/null; then
    if ! pnpm install --silent 2>/dev/null; then
        # esbuild 등 빌드 스크립트가 차단된 경우 승인 후 재시도
        echo -e "${GRAY}  빌드 스크립트 승인 중 (esbuild)...${NC}"
        pnpm approve-builds esbuild --silent 2>/dev/null || true
        pnpm install --silent
    fi
    ok "의존성 설치 완료"
else
    echo -e "${YELLOW}  ⚠ pnpm이 없습니다. 수동으로 실행하세요: cd $OUTPUT_DIR && pnpm install${NC}"
fi

# ── 4. git init + 첫 커밋 ───────────────────────────────────────────────────────
step "git 초기화 중..."
git init --quiet
git add .
git commit --quiet -m "chore: initialize project with harness engineering framework"
ok "git 초기화 완료 (첫 커밋 생성)"

# ── 5. 최종 검증 ────────────────────────────────────────────────────────────────
step "최종 검증 중..."
if pnpm validate 2>/dev/null; then
    ok "검증 통과 — 프로젝트 준비 완료"
else
    echo -e "${YELLOW}  ⚠ 검증 실패. 수동으로 확인하세요: pnpm validate${NC}"
fi

# ── 6. 완료 메시지 ──────────────────────────────────────────────────────────────
header "✅ 설정 완료!"

echo -e "생성된 프로젝트: ${CYAN}$OUTPUT_DIR${NC}"
echo ""
echo "생성된 주요 파일:"
find "$OUTPUT_DIR" -type f ! -path "*/node_modules/*" ! -path "*/.git/*" | sort | while IFS= read -r f; do
    info "${f#"$OUTPUT_DIR/"}"
done

echo ""
echo -e "${YELLOW}다음 단계:${NC}"
echo -e "  1. ${CYAN}cd $OUTPUT_DIR${NC}"
echo -e "  2. ${CYAN}claude${NC} 실행"
echo -e "  3. ${CYAN}/start${NC} 입력해서 세션 시작"
echo "  4. 작업 시작!"
echo ""
