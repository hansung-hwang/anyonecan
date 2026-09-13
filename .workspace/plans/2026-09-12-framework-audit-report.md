# 하네스 프레임워크 점검 결과

- 점검일: 2026-09-12
- 대상: 프레임워크 1.8.1, Base = Head = `7888b529d192cacc142052b724d47417a8ffa44f`
- 추가 대상: 점검 시작 전부터 존재한 미추적 `.agents/skills/`, `.codex/hooks.json`
- 제외: `eacc-agentic-mcp-server/`, `Homographormer/`. 내부 파일·코드·검증을 열거나 실행하지 않았다.
- 변경 범위: 이 보고서, 재현 스크립트, 계획·저널만 변경. 구현 수정·버전 변경·커밋 없음.

## 판단

**후속 수정 상태 (1.9.0 작업 트리, 2026-09-13):** F7과 F8 지침 충돌은
1.8.2에서 수정했고, 이번에 F1-F6, skills 배포, 프레임워크 회귀 테스트와 CI도
구현했다. 로컬 전체 검증 및 생성된 TypeScript/Python 검증은 통과했다.
Java matcher는 JDK 20에서 검증했으며 Java 21/Maven 및 hosted CI 실행은 미확인이다.
아래 발견 내용은 최초 1.8.1 점검 시점의 기록이다. 현재 구현·검증·제약은
`2026-09-13-framework-upgrade.md`를 참조한다.

업그레이드할 부분이 있다. 새 에이전트나 프롬프트를 늘리기보다 **파일 보호, 아키텍처 검사 정확도, skills 배포·동기화, 프레임워크 자체 회귀 테스트**를 먼저 보강하는 것이 효과적이다. 현재 검증이 통과해도 아래 결함은 검출되지 않는다.

기존 구성의 장점은 유지할 만하다. 언어 팩의 `pack.json` 기반 생성, manifest 기반 소유권 구분, 기준 해시와 `.new`를 통한 사용자 수정 보호, AGENTS 섹션 변경 안내, 작업 저널, 선택적인 Solo/Team 및 협업 규약은 이미 갖춰져 있다. 문제는 이 계약을 모든 실행 경로가 일관되게 지키는지 자동 검증하는 부분이다.

## 우선 수정할 항목

### F1 · P1 · Python 업그레이드가 빈 baselines를 구버전으로 오인해 사용자 파일을 덮어쓴다

- 근거: `upgrade.py:179`의 `bool(has_meta and meta.get("baselines"))`.
- 재현: `baselines: {}`와 직접 작성한 `.claude/commands/review.md`를 임시 프로젝트에 배치하고 실행하면 사용자 내용이 교체되고 `.new`도 생성되지 않는다. 동일 입력을 `upgrade.ps1`에 주면 원본을 유지하고 `.new`를 만든다.
- 영향: manifest가 명시한 “baselines 맵이 존재하지만 개별 경로가 없으면 보존” 계약 위반과 플랫폼 간 데이터 보호 차이.
- 개선: 키의 존재, JSON 객체 타입, 개별 해시 유효성을 별도로 판단한다. 맵 누락과 빈 맵을 구별하고, 잘못된 메타데이터는 쓰기 전에 오류로 처리한다.
- 완료 조건: absent / empty / partial / malformed baseline fixtures를 두 업그레이더에 공통 적용하여 보존 결과가 일치해야 한다.

### F2 · P1 · TypeScript 포맷 훅이 파일 경로를 셸 명령에 직접 삽입한다

- 근거: `scripts/lint-format-hook.mjs:15`, `language-packs/typescript/scripts/lint-format-hook.mjs:30`의 `execSync` 문자열 보간.
- 재현: `child_process`를 실행하지 않는 stub으로 `/tmp/$(printf audit).ts` 입력을 전달하면 셸 치환 구문이 그대로 포함된 명령 문자열을 생성한다. 실제 명령 주입은 실행하지 않았다.
- 영향: POSIX 셸에서는 큰따옴표 안의 `$()`도 실행된다. 유효한 파일 이름이 코드로 해석될 수 있고, 큰따옴표가 포함된 경로 역시 안전하지 않다.
- 개선: 셸 없이 실행하는 인자 배열과 프로젝트 로컬 CLI 진입점을 사용한다. Windows의 `.cmd` 실행 차이도 fixture로 검증한다. 포맷 실패를 삼키는 현재 동작에는 최소한 원인을 확인할 수 있는 진단 경로를 둔다.
- 완료 조건: 공백·한글·따옴표·달러 기호 경로가 정확히 하나의 파일 인자로 전달되고 셸에서 해석되지 않아야 한다.

### F3 · P1 · setup이 기존 출력 디렉터리를 보호하지 않는다

- 근거: `setup.ps1:123` 이후 `New-Item -Force` / `Copy-Item -Recurse -Force`, `setup.sh:149` 이후 `mkdir -p` / `cp -r`.
- 확인 수준: 코드 검토. 기존 사용자 디렉터리를 대상으로 실행하지 않았다.
- 영향: 기존 프로젝트 경로를 출력 위치로 선택하면 `AGENTS.md`, 빌드 설정, 샘플 소스 등을 그대로 덮어쓸 수 있다. 일반적인 `Proceed?` 확인 외에 비어 있지 않은 대상에 대한 별도 방어가 없다. 자신 또는 템플릿 디렉터리를 출력 대상으로 삼는 경우도 차단되지 않는다.
- 개선: 절대 경로를 확정하고 기존 비어 있지 않은 디렉터리와 프레임워크 소스 경로를 거부한다. 복구가 필요 없는 임시 디렉터리에서 생성 후 최종 위치로 전달하는 절차를 검토한다.
- 완료 조건: 기존 사용자 파일을 넣은 대상에 대한 생성이 쓰기 전에 실패하고 파일 해시가 유지되어야 한다.

### F4 · P2 · 같은 버전의 upgrade 재실행이 복구와 병합 마무리를 건너뛴다

- 근거: `upgrade.py:209`, `upgrade.ps1:199`의 버전 일치 조기 종료.
- 재현: 정상 배포 후 관리 파일을 하나 지우면 verify는 두 구현 모두 exit 1이다. 안내대로 실제 upgrade를 다시 실행하면 exit 0이지만 파일은 여전히 없다.
- 추가 코드 근거: `.new` 병합 후 재실행해도 뒤쪽의 해시 갱신·`.new` 정리 경로에 도달하지 않는다.
- 개선: 파일별 분류를 항상 수행하거나 명시적인 repair/reconcile 경로를 제공하고 안내와 일치시킨다.
- 완료 조건: 같은 버전에서 누락 파일 복원, 수동 병합 후 baseline 갱신, 재실행 멱등성을 양쪽 구현에서 검증한다.

### F5 · P2 · TypeScript 아키텍처 검사가 정상적인 import 문법을 놓친다

- 근거: `language-packs/typescript/src/tests/arch/dependencies.test.ts:63,79,90,100`.
- 재현: `import 'external'`, `import('external')`는 추출 결과가 빈 배열이다. `@/infrastructure/x`의 레이어 해석과 `./b.js`에서 실제 `b.ts`로의 파일 해석은 `null`이다.
- 영향: 템플릿 자체가 제공하는 `@/*` 별칭으로 application → infrastructure 의존성을 작성해도 레이어 검사가 놓친다. `.js` 확장자를 사용하는 TypeScript 모듈의 순환 참조도 놓칠 수 있다. `.tsx`는 수집 대상에서 제외된다. domain 내부 별칭은 반대로 외부 라이브러리로 오인할 수 있다.
- 개선: TypeScript AST 및 tsconfig 기반 모듈 해석을 사용하고 import/export/dynamic import와 확장자별 지원 범위를 정의한다.
- 완료 조건: 각 문법에 대해 금지된 의존성은 실패하고 허용된 의존성은 통과하는 fixture 테스트를 추가한다.

### F6 · P2 · Python 상대 import 해석과 테스트 파일 존재 검사가 부정확하다

- 근거: `language-packs/python/tests/arch/test_dependencies.py:77`이 `ImportFrom.level`과 `module=None`을 처리하지 않는다. `:197`은 최상위 `glob`만 수행하며 `is_ignored`를 호출하지 않는다.
- 재현: `from .sibling import value`를 domain의 외부 라이브러리 의존성으로 잘못 거부한다. `from . import sibling`은 import를 아예 추출하지 않는다. `.harnessignore`의 `user.py`는 일반 파일 수집에서는 제외되지만 테스트 파일 존재 검사에서는 실패한다.
- 추가 코드 근거: 하위 domain 패키지 파일의 테스트 존재는 검사하지 않는다. Java도 `DependencyTest.java:135`의 `Files.list`로 최상위만 검사한다.
- 개선: 현재 파일의 패키지와 상대 import 깊이를 이용해 모듈을 해석하고, 파일 수집·제외·테스트 대응 경로를 검사 전체에서 통일한다.
- 완료 조건: 상대 import, 중첩 패키지, 제외된 domain 파일에 대한 양성·음성 사례를 검증한다.

### F7 · P2 · AGENTS 단일 규칙 원천과 ADR 프롬프트가 충돌한다

- 근거: `.claude/commands/adr.md:44`는 `CLAUDE.md`에 규칙 참조를 추가하도록 지시한다. 배포 템플릿 `harness-core/.claude/commands/adr.md:40`은 `CLAUDE.md`와 `AGENTS.md` 모두에 추가하도록 지시한다.
- 영향: AGENTS를 유일한 편집 대상으로 정한 규칙을 공식 워크플로가 위반한다. 로컬 ADR skill은 AGENTS로 바뀌어 있어 도구별 행동도 달라진다.
- 확인: 이 상태에서 `check-sync`는 통과했다. 현재 정규식은 이 표현을 잡지 못한다.
- 개선: ADR 프롬프트를 AGENTS 기준으로 수정하고 실제 발견 문장을 회귀 fixture로 등록한다. 검사는 명령 파일 이름 일치 외에 규칙의 의미와 대상 경로를 다뤄야 한다.

### F8 · P2 · skills가 배포되지 않고 변환 오류도 검증되지 않는다

- 근거: `git ls-files .agents .codex` 결과가 비어 있다. setup은 `harness-core`와 언어 팩만 복사하며 이들 안에는 `.agents/skills`와 `.codex`가 없다. manifest에도 해당 경로가 없다.
- 영향: 현재 머신의 skills는 새 clone·생성 프로젝트·upgrade로 전달되지 않는다. README는 다른 도구에 프롬프트를 수동 복사하도록 설명하므로, 이는 기존 수동 사용 계약의 결함이라기보다 **skills를 프레임워크 기능으로 승격하기 위한 미완성 부분**이다.
- 실제 변환 오류: `source-command-start/SKILL.md:36`은 AGENTS를 두 번 읽으라고 한다. `source-command-coordinate/SKILL.md:48,59`에는 AGENTS가 중복되고 CLAUDE가 빠졌다. `source-command-team/SKILL.md:70`은 존재하지 않는 `.Codex/settings.json`을 가리킨다. done/fix에는 “AGENTS.md imports it”이라는 자기 참조가 생겼다.
- 개선: 공통 워크플로 원문에서 얇은 도구별 wrapper를 생성하거나 원문을 참조하게 한다. 전역 문자열 치환을 없애고 skill 설명에는 자연어 사용 조건·입력·산출물을 명시한다. manifest 소유권, 신규 생성, upgrade 전달, 변경 충돌 처리, 동기화 검사를 함께 설계한다.
- 범위 한계: `.codex/hooks.json`은 Claude 설정과 같은 내용을 담고 있다는 사실만 확인했다. 현재 Codex 런타임의 훅 지원 여부나 실행 성공은 이 점검에서 검증하지 않았다.

### F9 · P2 · 프레임워크를 수정해도 프레임워크 실행 계약을 테스트하지 않는다

- 근거: `vitest.config.ts:5`는 `src/**/*.test.ts`만 실행한다. 루트 CI는 check-sync, TypeScript 샘플 typecheck/lint/test/coverage를 실행한다. setup/upgrade, 언어 팩 동작, hook 입력, skills 생성에 대한 자동 테스트 단계가 없다.
- 실제 검증: 루트 샘플과 아키텍처 테스트는 통과했지만 F1/F4/F5/F6/F7/F8은 그대로 존재했다.
- 개선: 별도의 framework contract test suite와 Linux/Windows × 지원 언어 smoke matrix를 둔다. setup에 비대화형 입력·설치/초기커밋 생략 옵션을 제공하면 자동 검증이 쉬워진다. 각 언어 팩의 CI 템플릿이 존재하는 것과 프레임워크 저장소가 그 템플릿을 검증하는 것은 별개다.
- 우선 fixture: 사용자 파일 보존, baseline 상태, 동일 버전 복구, LF/CRLF·한글·공백 경로, 언어별 금지/허용 의존성, skills 경로와 내용.

## 추가 개선과 보류

- **Java 제외 규칙:** `DependencyTest.java:72`는 절대 compiled-class 위치를, `:138`은 상대 source 경로를 같은 matcher에 전달한다. 기존 저널의 의심 사항이 코드에 남아 있다. source 디렉터리 패턴과 compiled 경로 간 대응을 정의한 후 Java 21/Maven 환경에서 ArchUnit 통합 재현이 필요하다. 이번에는 도구가 PATH에 없어 빌드 결과를 단정하지 않는다.
- **Windows 검증 진입점:** 이 환경의 기본 `pnpm validate`는 System32의 WSL bash를 선택해 실패했다. Git Bash를 PATH 앞에 두면 통과한다. TypeScript에도 PowerShell 또는 Node 기반 공통 진입점과 환경 사전 점검을 제공할 가치가 있다.
- **재현 가능한 도구 버전:** 루트 CI의 pnpm `version: latest`와 package.json의 packageManager 부재를 정리한다. 이번 점검은 최신 패키지 버전·취약점 조사가 아니며 특정 버전 업그레이드를 권고하지 않는다.
- **워크플로 품질:** `/review` 자체에 Base/Head, 증거 수준, 실제 실행한 검증과 미검증 범위를 산출물로 요구하면 AGENTS의 보고 규칙이 더 잘 실행된다. skills 추가가 필요하다면 일반 역할 agent를 더 만드는 것보다 이 보고서의 반복 점검을 수행하는 framework-audit 및 language-pack 검증 절차가 직접적이다.
- **역할 agent:** 현재 프레임워크는 별도 실행형 agent 정의보다 `/team`, `/coordinate`, 협업 가이드로 역할을 관리한다. 요청 없이 병렬 실행을 시작하지 않는 선택적 설계는 유지하는 편이 좋다.

## 검증 기록

모든 명령의 작업 디렉터리는 `C:\anyonecan_harness\anyonecan`. Windows PowerShell 환경, Node `18.17.0`, 재현 스크립트 Python `3.13.5` 사용. 네트워크 설치와 하위 프로젝트 검증은 수행하지 않았다.

| 명령 | 결과와 해석 |
|---|---|
| `pnpm validate` | 샌드박스에서는 사용자 경로 EPERM으로 실행 시작 실패. 샌드박스 밖에서는 WSL bash 실행 실패. 코드 검사 실패로 해석하지 않음. |
| `$env:PATH = 'C:\Program Files\Git\bin;' + $env:PATH; pnpm validate` | 샌드박스 밖에서 성공. check-sync, typecheck, lint, 아키텍처 및 domain 샘플 테스트 통과. |
| `& 'C:\Users\rty10\miniconda3\python.exe' .workspace/plans/2026-09-12-framework-audit-repro.py` | 성공. 임시 프로젝트에서 두 upgrade의 동일 버전 복구 실패, 빈 baseline 보호 차이, Python 검사 오류와 skills 차이를 확인. 임시 폴더는 실행 종료 시 정리. |
| `node .workspace/plans/2026-09-12-framework-audit-repro.cjs` | 성공. 실제 배포 검사 코드를 transpile하여 import 해석을 확인. 포맷 훅의 프로세스 실행은 stub으로 대체해 명령 문자열만 확인. |
| `git ls-files .agents .codex` | 빈 결과. 로컬 미추적 설정임을 확인. |

당시 재현 스크립트는 **1.8.1 결함을 입증한 역사 기록**이다. 현재 버전은
`scripts/framework.test.mjs`와 `scripts/framework-contracts.py`의 수정된 기대 동작으로
검증한다. 위 표의 미실행 범위는 최초 점검 기준이며 후속 결과는 새 계획에 기록했다.

## 제안 순서

1. **파일 보호 수정:** F1/F2/F3와 F4를 각각 회귀 테스트와 함께 수정.
2. **규칙 정확도:** F5/F6/F7 및 Java 제외 규칙을 언어별 fixture로 검증.
3. **skills 정식 제공:** F8의 원문·wrapper·manifest·배포 계약을 일괄 정리.
4. **지속 검증:** F9의 framework suite와 Windows/Linux smoke CI를 정착.

framework-owned 경로를 수정할 때는 기존 규칙대로 HARNESS-VERSION 및 FRAMEWORK-CHANGELOG를 갱신한다. 이번 점검에서는 구현을 수정하지 않아 버전은 1.8.1 그대로다.
