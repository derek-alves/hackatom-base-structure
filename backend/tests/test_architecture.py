import ast
import re
from pathlib import Path

APP = Path(__file__).resolve().parent.parent / "app"


def offenders(root: Path, banned: str) -> list[str]:
    pattern = re.compile(banned)
    found: list[str] = []
    for file in root.rglob("*.py"):
        tree = ast.parse(file.read_text(), filename=str(file))
        for node in ast.walk(tree):
            if isinstance(node, ast.Import):
                names = [a.name for a in node.names]
            elif isinstance(node, ast.ImportFrom) and node.module and node.level == 0:
                names = [node.module]
                # `from app import registry` style
                names += [f"{node.module}.{a.name}" for a in node.names]
            else:
                continue
            found += [f"{file}:{node.lineno}: {n}" for n in names if pattern.match(n)]
    return found


def test_core_does_not_import_modules_or_registry():
    assert offenders(APP / "core", banned=r"^app\.(modules|registry)") == []


def test_modules_do_not_import_each_other_or_registry():
    for mod in (APP / "modules").iterdir():
        if mod.is_dir() and mod.name != "__pycache__":
            assert offenders(mod, banned=rf"^app\.(registry|modules\.(?!{mod.name}\b))") == []
