"""아키텍처 의존성 규칙 테스트"""
from __future__ import annotations

import ast
from pathlib import Path

ROOT_DIR = Path(__file__).parent.parent.parent
SRC_DIR = ROOT_DIR / "src"

LAYER_ORDER: dict[str, int] = {
    "domain": 0,
    "application": 1,
    "infrastructure": 2,
    "presentation": 3,
}

# Python 표준 라이브러리 허용 목록 (domain에서 사용 가능)
STDLIB_ROOTS: set[str] = {
    "os", "sys", "re", "json", "typing", "pathlib", "datetime",
    "collections", "functools", "itertools", "abc", "dataclasses",
    "enum", "math", "io", "logging", "uuid", "contextlib",
    "copy", "hashlib", "time", "urllib", "http", "email",
    "ast", "inspect", "types", "weakref", "threading", "string",
    "__future__",
}


def collect_py_files(directory: Path) -> list[Path]:
    return [
        p for p in directory.rglob("*.py")
        if "__pycache__" not in p.parts and not p.name.startswith("test_")
    ]


def extract_layer(file_path: Path) -> str | None:
    try:
        rel = file_path.relative_to(SRC_DIR)
        part = rel.parts[0] if rel.parts else None
        return part if part in LAYER_ORDER else None
    except ValueError:
        return None


def extract_imports(file_path: Path) -> list[str]:
    try:
        tree = ast.parse(file_path.read_text(encoding="utf-8"))
    except SyntaxError:
        return []
    imports: list[str] = []
    for node in ast.walk(tree):
        if isinstance(node, ast.ImportFrom) and node.module:
            imports.append(node.module)
        elif isinstance(node, ast.Import):
            for alias in node.names:
                imports.append(alias.name)
    return imports


def resolve_layer(imp: str) -> str | None:
    root = imp.split(".")[0]
    return root if root in LAYER_ORDER else None


def test_layer_dependencies() -> None:
    """모든 레이어는 자신보다 상위 레이어를 import하지 않는다"""
    violations: list[str] = []

    for file in collect_py_files(SRC_DIR):
        from_layer = extract_layer(file)
        if from_layer is None:
            continue
        from_order = LAYER_ORDER[from_layer]

        for imp in extract_imports(file):
            to_layer = resolve_layer(imp)
            if to_layer is None:
                continue
            if LAYER_ORDER[to_layer] > from_order:
                violations.append(
                    f"[위반] {file.relative_to(SRC_DIR)} ({from_layer}) → {imp} ({to_layer})"
                )

    assert not violations, (
        f"레이어 의존성 위반 {len(violations)}건:\n\n" + "\n".join(violations)
    )


def test_domain_purity() -> None:
    """domain 레이어는 외부 라이브러리를 import하지 않는다"""
    violations: list[str] = []

    for file in collect_py_files(SRC_DIR):
        if extract_layer(file) != "domain":
            continue

        for imp in extract_imports(file):
            root = imp.split(".")[0]
            if root in STDLIB_ROOTS or root in LAYER_ORDER:
                continue
            violations.append(
                f"[위반] {file.relative_to(SRC_DIR)}: 외부 라이브러리 '{imp}' import 금지"
            )

    assert not violations, (
        f"domain 순수성 위반 {len(violations)}건:\n\n" + "\n".join(violations)
    )


def test_source_files_exist() -> None:
    """src 하위에 Python 소스 파일이 존재한다"""
    py_files = collect_py_files(SRC_DIR)
    assert len(py_files) > 0, "src 하위에 Python 소스 파일이 있어야 합니다"
