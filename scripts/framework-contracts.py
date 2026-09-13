"""Exercise delivered framework behavior in disposable projects, using stdlib only."""
from __future__ import annotations

import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.dont_write_bytecode = True
POWERSHELL = shutil.which("pwsh") or shutil.which("powershell")
BASH = os.environ.get("HARNESS_BASH") or (
    "C:/Program Files/Git/bin/bash.exe" if os.name == "nt" else shutil.which("bash")
)
ENGINES = ["python"] + (["powershell"] if POWERSHELL else [])


def digest(content: str) -> str:
    return hashlib.sha256(content.replace("\r\n", "\n").encode()).hexdigest()


def execute(args: list[str], cwd: Path = ROOT) -> subprocess.CompletedProcess[str]:
    env = dict(os.environ, PYTHONUTF8="1", PYTHONIOENCODING="utf-8",
               HARNESS_PYTHON=sys.executable.replace("\\", "/"))
    return subprocess.run(args, cwd=cwd, env=env, capture_output=True,
                          text=True, encoding="utf-8", errors="replace", timeout=90)


def upgrade(project: Path, engine: str, mode: str = "") -> subprocess.CompletedProcess[str]:
    if engine == "python":
        args = [sys.executable, str(ROOT / "upgrade.py"), str(project), str(ROOT)]
        if mode:
            args.append("--" + mode)
    else:
        assert POWERSHELL
        args = [POWERSHELL, "-NoProfile", "-File", str(ROOT / "upgrade.ps1"),
                "-ProjectDir", str(project)]
        if mode:
            args.append({"verify": "-Verify", "dry-run": "-DryRun"}[mode])
    return execute(args)


def snapshot(project: Path) -> dict[str, bytes]:
    return {str(file.relative_to(project)): file.read_bytes()
            for file in project.rglob("*") if file.is_file()}


class UpgradeContracts(unittest.TestCase):
    def test_baseline_classification_and_metadata_errors(self) -> None:
        cases = ["absent", {}, {"other": digest("baseline")}, None, [], {"x": "bad"}]
        for engine in ENGINES:
            for baselines in cases:
                with self.subTest(engine=engine, baselines=baselines), tempfile.TemporaryDirectory() as temporary:
                    project = Path(temporary)
                    meta: dict[str, object] = {"language": "typescript"}
                    if baselines != "absent":
                        meta["baselines"] = baselines
                    (project / ".harness-meta.json").write_text(json.dumps(meta), encoding="utf-8")
                    custom = project / ".claude/commands/review.md"
                    custom.parent.mkdir(parents=True)
                    custom.write_text("USER RULES", encoding="utf-8")
                    before = snapshot(project)
                    result = upgrade(project, engine)
                    malformed = baselines is None or isinstance(baselines, list) or baselines == {"x": "bad"}
                    if malformed:
                        self.assertNotEqual(result.returncode, 0)
                        self.assertEqual(snapshot(project), before)
                    else:
                        self.assertEqual(result.returncode, 0, result.stderr)
                        if baselines == "absent":
                            self.assertNotEqual(custom.read_text(encoding="utf-8"), "USER RULES")
                        else:
                            self.assertEqual(custom.read_text(encoding="utf-8"), "USER RULES")
                            self.assertTrue(Path(str(custom) + ".new").exists())

    def test_repair_merge_readonly_and_skill_delivery(self) -> None:
        for engine in ENGINES:
            with self.subTest(engine=engine), tempfile.TemporaryDirectory() as temporary:
                project = Path(temporary)
                meta_path = project / ".harness-meta.json"
                meta_path.write_text(json.dumps({"language": "typescript", "baselines": {},
                                                "projectMode": "team", "roster": {"dev": "backend"}}), encoding="utf-8")
                first = upgrade(project, engine)
                self.assertEqual(first.returncode, 0, first.stderr)
                skill = project / ".agents/skills/source-command-review/SKILL.md"
                self.assertTrue(skill.is_file())
                self.assertIn("../../../AGENTS.md", skill.read_text(encoding="utf-8"))
                review = project / ".claude/commands/review.md"
                review.unlink()
                before = snapshot(project)
                self.assertNotEqual(upgrade(project, engine, "verify").returncode, 0)
                self.assertEqual(upgrade(project, engine, "dry-run").returncode, 0)
                self.assertEqual(snapshot(project), before)
                self.assertEqual(upgrade(project, engine).returncode, 0)
                self.assertTrue(review.is_file())
                template = review.read_text(encoding="utf-8")
                review.write_text("USER RULES", encoding="utf-8")
                self.assertEqual(upgrade(project, engine).returncode, 0)
                incoming = Path(str(review) + ".new")
                self.assertEqual(incoming.read_text(encoding="utf-8"), template)
                review.write_bytes(template.replace("\n", "\r\n").encode())
                self.assertEqual(upgrade(project, engine).returncode, 0)
                self.assertFalse(incoming.exists())
                meta = json.loads(meta_path.read_text(encoding="utf-8"))
                self.assertEqual(meta["baselines"][".claude/commands/review.md"], digest(template))
                self.assertEqual(meta["roster"], {"dev": "backend"})
                skill.write_text("CUSTOM SKILL", encoding="utf-8")
                self.assertEqual(upgrade(project, engine).returncode, 0)
                self.assertEqual(skill.read_text(encoding="utf-8"), "CUSTOM SKILL")
                self.assertTrue(Path(str(skill) + ".new").exists())


class SetupContracts(unittest.TestCase):
    def test_generation_and_existing_target_protection(self) -> None:
        engines = (["bash"] if BASH else []) + (["powershell"] if POWERSHELL else [])
        for engine in engines:
            for language in ("typescript", "python", "java"):
                with self.subTest(engine=engine, language=language), tempfile.TemporaryDirectory(prefix="harness-setup-") as temporary:
                    base = Path(temporary)
                    target = base / "space project"
                    config = base / "setup.json"
                    config.write_text(json.dumps({"projectName": "contract-project", "language": language,
                                                  "outputDir": str(target), "basePackage": "com.example.contract"}), encoding="utf-8")
                    if engine == "powershell":
                        assert POWERSHELL
                        args = [POWERSHELL, "-NoProfile", "-File", str(ROOT / "setup.ps1"),
                                "-ConfigFile", str(config), "-SkipInstall", "-SkipGit"]
                    else:
                        assert BASH
                        args = [BASH, "-c", 'python3() { "$HARNESS_PYTHON" "$@"; }; export -f python3; bash "$@"',
                                "--", str(ROOT / "setup.sh"), "--config", str(config), "--skip-install", "--skip-git"]
                    result = execute(args)
                    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                    self.assertFalse((target / ".git").exists())
                    self.assertFalse((target / "node_modules").exists())
                    self.assertTrue((target / ".agents/skills/source-command-review/SKILL.md").is_file())
                    meta = json.loads((target / ".harness-meta.json").read_text(encoding="utf-8"))
                    self.assertEqual(meta["language"], language)
                    self.assertIn(".agents/skills/source-command-review/SKILL.md", meta["baselines"])
                    self.assertNotIn("{{", (target / "AGENTS.md").read_text(encoding="utf-8"))
                    before = snapshot(target)
                    result = execute(args)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertEqual(snapshot(target), before)


class PythonArchitectureContracts(unittest.TestCase):
    def test_relative_imports_nested_tests_and_ignore(self) -> None:
        spec = importlib.util.spec_from_file_location("arch_contract", ROOT / "language-packs/python/tests/arch/test_dependencies.py")
        assert spec and spec.loader
        arch = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(arch)
        with tempfile.TemporaryDirectory() as temporary:
            project = Path(temporary)
            arch.ROOT_DIR = project
            arch.SRC_DIR = project / "src"
            domain = project / "src/domain/nested"
            domain.mkdir(parents=True)
            source = domain / "user.py"
            sibling = domain / "sibling.py"
            sibling.write_text("value = 1", encoding="utf-8")
            for statement in ("from .sibling import value", "from . import sibling"):
                source.write_text(statement, encoding="utf-8")
                self.assertIn("domain.nested.sibling", arch.extract_imports(source))
                arch.test_domain_purity()
            with self.assertRaises(AssertionError):
                arch.test_domain_modules_have_tests()
            arch.HARNESSIGNORE_PATTERNS = ["nested"]
            arch.test_domain_modules_have_tests()
            arch.HARNESSIGNORE_PATTERNS = []
            source.write_text("from infrastructure import store", encoding="utf-8")
            with self.assertRaises(AssertionError):
                arch.test_layer_dependencies()
            source.write_text("from .sibling import value", encoding="utf-8")
            tests = project / "tests/domain/nested"
            tests.mkdir(parents=True)
            for name in ("user", "sibling"):
                (tests / f"test_{name}.py").touch()
            arch.test_domain_modules_have_tests()


class JavaPathContracts(unittest.TestCase):
    def test_actual_matcher_maps_compiled_classes_to_source_paths(self) -> None:
        javac = os.environ.get("HARNESS_JAVAC") or shutil.which("javac")
        if not javac:
            self.skipTest("javac not available; language-smoke CI exercises the Java pack")
        java = str(Path(javac).with_name("java.exe" if os.name == "nt" else "java"))
        source = (ROOT / "language-packs/java/src/test/java/arch/DependencyTest.java").read_text(encoding="utf-8")
        start = source.index("    private static List<String> loadHarnessignorePatterns()")
        end = source.index("    private final JavaClasses classes")
        methods = source[start:end]
        with tempfile.TemporaryDirectory(prefix="harness-java-") as temporary:
            project = Path(temporary)
            (project / ".harnessignore").write_text("src/main/java/com/example/domain/vendor\nancestor\n", encoding="utf-8")
            code = """import java.io.*;
import java.net.URI;
import java.nio.file.*;
import java.util.*;
class MatcherContract {
""" + methods + """
    public static void main(String[] args) {
        Path root = Paths.get("").toAbsolutePath();
        URI excluded = root.resolve("target/classes/com/example/domain/vendor/Outer$Inner.class").toUri();
        URI included = root.resolve("target/classes/com/example/domain/Keep.class").toUri();
        URI external = root.resolve("ancestor/other/Keep.class").toUri();
        if (!isIgnoredClassLocation(excluded) || isIgnoredClassLocation(included)
                || isIgnoredClassLocation(external)) { throw new AssertionError("path mapping"); }
    }
}
"""
            (project / "MatcherContract.java").write_text(code, encoding="utf-8")
            compiled = execute([javac, "-encoding", "UTF-8", "MatcherContract.java"], project)
            self.assertEqual(compiled.returncode, 0, compiled.stderr)
            result = execute([java, "-cp", ".", "MatcherContract"], project)
            self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main(verbosity=2)
