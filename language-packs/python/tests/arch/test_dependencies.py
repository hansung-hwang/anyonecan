"""Architecture dependency rule tests"""
from __future__ import annotations

import ast
import re
import sys
from pathlib import Path

ROOT_DIR = Path(__file__).parent.parent.parent
SRC_DIR = ROOT_DIR / "src"

LAYER_ORDER: dict[str, int] = {
    "domain": 0,
    "application": 1,
    "infrastructure": 2,
    "presentation": 3,
}

# Every standard-library top-level module name (usable from the domain layer).
# Sourced from the interpreter itself (Python 3.10+) instead of a hand-maintained
# list -- a hardcoded subset drifts (missing real stdlib modules a project legitimately
# uses) without ever catching up, since nothing forces it to be revisited.
STDLIB_ROOTS: frozenset[str] = sys.stdlib_module_names


def load_harnessignore() -> list[str]:
    """Patterns from the project's .harnessignore (bare name -> path segment, '/' -> substring)"""
    ignore_file = ROOT_DIR / ".harnessignore"
    if not ignore_file.exists():
        return []
    patterns: list[str] = []
    for line in ignore_file.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        patterns.append(stripped)
    return patterns


HARNESSIGNORE_PATTERNS: list[str] = load_harnessignore()


def is_ignored(file_path: Path) -> bool:
    rel = file_path.relative_to(ROOT_DIR).as_posix()
    for pattern in HARNESSIGNORE_PATTERNS:
        if "/" in pattern:
            if pattern in rel:
                return True
        elif pattern in rel.split("/"):
            return True
    return False


def collect_py_files(directory: Path) -> list[Path]:
    return [
        p for p in directory.rglob("*.py")
        if "__pycache__" not in p.parts and not p.name.startswith("test_") and not is_ignored(p)
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
    """No layer imports a layer above itself"""
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
                    f"[violation] {file.relative_to(SRC_DIR)} ({from_layer}) → {imp} ({to_layer})"
                )

    assert not violations, (
        f"{len(violations)} layer dependency violation(s):\n\n" + "\n".join(violations)
    )


def test_domain_purity() -> None:
    """The domain layer does not import external libraries"""
    violations: list[str] = []

    for file in collect_py_files(SRC_DIR):
        if extract_layer(file) != "domain":
            continue

        for imp in extract_imports(file):
            root = imp.split(".")[0]
            if root in STDLIB_ROOTS or root in LAYER_ORDER:
                continue
            rel = file.relative_to(SRC_DIR)
            violations.append(f"[violation] {rel}: external library '{imp}' must not be imported")

    assert not violations, (
        f"{len(violations)} domain purity violation(s):\n\n" + "\n".join(violations)
    )


def test_source_files_exist() -> None:
    """Python source files exist under src"""
    py_files = collect_py_files(SRC_DIR)
    assert len(py_files) > 0, "There must be Python source files under src"


def test_no_import_cycles() -> None:
    """There must be no circular references between layers (DFS)"""
    graph: dict[str, set[str]] = {layer: set() for layer in LAYER_ORDER}

    for file in collect_py_files(SRC_DIR):
        from_layer = extract_layer(file)
        if from_layer is None:
            continue
        for imp in extract_imports(file):
            to_layer = resolve_layer(imp)
            if to_layer and to_layer != from_layer:
                graph[from_layer].add(to_layer)

    visited: set[str] = set()
    rec_stack: set[str] = set()

    def has_cycle(node: str) -> bool:
        visited.add(node)
        rec_stack.add(node)
        for neighbor in graph.get(node, set()):
            if neighbor not in visited:
                if has_cycle(neighbor):
                    return True
            elif neighbor in rec_stack:
                return True
        rec_stack.discard(node)
        return False

    cycle_roots = [n for n in graph if n not in visited and has_cycle(n)]
    assert not cycle_roots, f"Layers with detected circular references: {cycle_roots}"


def test_file_naming_convention() -> None:
    """Python source file names must be snake_case"""
    pattern = re.compile(r'^[a-z][a-z0-9_]*\.py$')
    violations: list[str] = []

    for file in SRC_DIR.rglob("*.py"):
        if "__pycache__" in file.parts or file.name.startswith("__") or is_ignored(file):
            continue
        if not pattern.match(file.name):
            violations.append(str(file.relative_to(ROOT_DIR)))

    assert not violations, (
        f"{len(violations)} file name(s) violating snake_case:\n" + "\n".join(violations)
    )


def test_domain_modules_have_tests() -> None:
    """Each module in src/domain must have a matching test file"""
    domain_dir = SRC_DIR / "domain"
    tests_domain_dir = ROOT_DIR / "tests" / "domain"

    if not domain_dir.exists():
        return

    violations: list[str] = []
    for src_file in domain_dir.glob("*.py"):
        if src_file.name.startswith("__"):
            continue
        expected = tests_domain_dir / f"test_{src_file.name}"
        if not expected.exists():
            violations.append(
                f"src/domain/{src_file.name} → tests/domain/test_{src_file.name} missing"
            )

    assert not violations, (
        f"{len(violations)} missing test file(s):\n" + "\n".join(violations)
    )
