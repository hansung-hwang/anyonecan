"""Disposable reproductions for the framework audit; no nested project access."""
from pathlib import Path
import importlib.util
import json
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]
sys.dont_write_bytecode = True


def upgrade(project: Path, engine: str, verify: bool = False) -> subprocess.CompletedProcess[str]:
    if engine == "python":
        args = [sys.executable, str(ROOT / "upgrade.py"), str(project), str(ROOT)]
        if verify:
            args.append("--verify")
    else:
        args = ["powershell.exe", "-NoProfile", "-File", str(ROOT / "upgrade.ps1"), "-ProjectDir", str(project)]
        if verify:
            args.append("-Verify")
    return subprocess.run(args, cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace")


with tempfile.TemporaryDirectory(prefix="framework-audit-") as temporary:
    base = Path(temporary).resolve()
    assert base.name.startswith("framework-audit-") and base != ROOT
    for engine in ("python", "powershell"):
        project = base / engine
        project.mkdir()
        meta = project / ".harness-meta.json"
        meta.write_text(json.dumps({"language": "typescript", "baselines": {"sentinel": "x"}}), encoding="utf-8")
        initial = upgrade(project, engine)
        assert initial.returncode == 0, initial.stderr
        managed = project / ".claude/commands/review.md"
        managed.unlink()
        verification = upgrade(project, engine, True)
        retry = upgrade(project, engine)
        print(f"{engine}: missing verify exit={verification.returncode}; repair exit={retry.returncode}; still missing={not managed.exists()}")
        assert verification.returncode != 0 and retry.returncode == 0 and not managed.exists()

        empty = base / (engine + "-empty")
        (empty / ".claude/commands").mkdir(parents=True)
        (empty / ".harness-meta.json").write_text(json.dumps({"language": "typescript", "baselines": {}}), encoding="utf-8")
        customized = empty / ".claude/commands/review.md"
        customized.write_text("USER CUSTOM REVIEW", encoding="utf-8")
        result = upgrade(empty, engine)
        assert result.returncode == 0, result.stderr
        print(f"{engine}: empty baseline preserves custom={customized.read_text(encoding='utf-8') == 'USER CUSTOM REVIEW'}; offers .new={Path(str(customized) + '.new').exists()}")

    spec = importlib.util.spec_from_file_location("audit_arch", ROOT / "language-packs/python/tests/arch/test_dependencies.py")
    assert spec and spec.loader
    arch = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(arch)
    fixture = base / "python-arch"
    (fixture / "src/domain").mkdir(parents=True)
    (fixture / "src/domain/user.py").write_text("from . import sibling\n", encoding="utf-8")
    arch.ROOT_DIR = fixture
    arch.SRC_DIR = fixture / "src"
    arch.HARNESSIGNORE_PATTERNS = ["user.py"]
    print(f"python: ignored file collected={bool(arch.collect_py_files(arch.SRC_DIR))}")
    try:
        arch.test_domain_modules_have_tests()
    except AssertionError:
        print("python: ignored domain file still demands test=True")
    arch.HARNESSIGNORE_PATTERNS = []
    source = fixture / "src/domain/user.py"
    source.write_text("from .sibling import value\n", encoding="utf-8")
    try:
        arch.test_domain_purity()
    except AssertionError:
        print("python: same-package relative import falsely rejected=True")
    source.write_text("from . import sibling\n", encoding="utf-8")
    print(f"python: from-dot import extraction={arch.extract_imports(source)}")

for skill in sorted((ROOT / ".agents/skills").glob("*/SKILL.md")):
    content = skill.read_text(encoding="utf-8")
    if "## Command Template\n\n" not in content:
        print(f"skill {skill.parent.name}: reference wrapper; checked by check-sync")
        continue
    body = content.split("## Command Template\n\n", 1)[1]
    command = ROOT / ".claude/commands" / (skill.parent.name.removeprefix("source-command-") + ".md")
    print(f"skill {skill.parent.name}: matches source={body.strip() == command.read_text(encoding='utf-8').strip()}")
