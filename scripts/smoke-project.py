"""Generate a disposable language-pack project for local or CI validation."""
from __future__ import annotations

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    language, output = sys.argv[1:]
    target = Path(output).resolve()
    if language not in ("typescript", "python", "java"):
        raise SystemExit("Expected typescript, python, or java")
    with tempfile.TemporaryDirectory(prefix="harness-smoke-config-") as temporary:
        config = Path(temporary) / "setup.json"
        config.write_text(json.dumps({"projectName": "harness-smoke", "language": language,
                                      "outputDir": str(target), "basePackage": "com.example.smoke"}), encoding="utf-8")
        if os.name == "nt":
            shell = shutil.which("pwsh") or shutil.which("powershell")
            if not shell:
                raise SystemExit("PowerShell is required")
            command = [shell, "-NoProfile", "-File", str(ROOT / "setup.ps1"),
                       "-ConfigFile", str(config), "-SkipInstall", "-SkipGit"]
        else:
            command = ["bash", str(ROOT / "setup.sh"), "--config", str(config), "--skip-install", "--skip-git"]
        subprocess.run(command, cwd=ROOT, check=True)
    if language == "java":
        # Real classes make the ArchUnit checks meaningful even in an otherwise empty starter.
        files = {
            "src/main/java/com/example/smoke/domain/Model.java":
                "package com.example.smoke.domain; public class Model { }",
            "src/main/java/com/example/smoke/domain/nested/Item.java":
                "package com.example.smoke.domain.nested; public class Item { }",
            "src/main/java/com/example/smoke/application/Service.java":
                "package com.example.smoke.application; public class Service { }",
            "src/main/java/com/example/smoke/infrastructure/Storage.java":
                "package com.example.smoke.infrastructure; public class Storage { }",
            "src/main/java/com/example/smoke/presentation/Controller.java":
                "package com.example.smoke.presentation; public class Controller { }",
            "src/main/java/com/example/smoke/domain/vendor/Excluded.java":
                "package com.example.smoke.domain.vendor; public class Excluded "
                "extends com.example.smoke.presentation.Controller { }",
            ".harnessignore": "src/main/java/com/example/smoke/domain/vendor\n",
        }
        for name, package in (("Model", "domain"), ("Item", "domain.nested")):
            path = f"src/test/java/com/example/smoke/{package.replace('.', '/')}/{name}Test.java"
            files[path] = f"""package com.example.smoke.{package};
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertNotNull;
class {name}Test {{
    @Test void createsValue() {{ assertNotNull(new {name}()); }}
}}
"""
        for relative, content in files.items():
            file = target / relative
            file.parent.mkdir(parents=True, exist_ok=True)
            file.write_text(content + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
