import ast
import re
from pathlib import Path

APP = Path(__file__).resolve().parent.parent / "app"


def imported_names(source: str, package: str) -> list[tuple[int, str]]:
    """(line, dotted name) for every import; relative imports resolve against `package`."""
    names: list[tuple[int, str]] = []
    for node in ast.walk(ast.parse(source)):
        if isinstance(node, ast.Import):
            names += [(node.lineno, a.name) for a in node.names]
        elif isinstance(node, ast.ImportFrom):
            if node.level:
                parts = package.split(".")
                base = parts[: len(parts) - node.level + 1]
                module = ".".join([*base, node.module] if node.module else base)
            else:
                module = node.module or ""
            names.append((node.lineno, module))
            # `from app import registry` / `from .. import records` style
            names += [(node.lineno, f"{module}.{a.name}") for a in node.names]
    return names


def offenders(root: Path, banned: str) -> list[str]:
    pattern = re.compile(banned)
    found: list[str] = []
    for file in root.rglob("*.py"):
        package = ".".join(file.relative_to(APP.parent).parent.parts)
        found += [
            f"{file}:{line}: {name}"
            for line, name in imported_names(file.read_text(), package)
            if pattern.match(name)
        ]
    return found


def module_ban(name: str) -> str:
    return rf"^app\.(registry|modules\.(?!{name}\b))"


def test_core_does_not_import_modules_or_registry():
    assert offenders(APP / "core", banned=r"^app\.(modules|registry)") == []


def test_modules_do_not_import_each_other_or_registry():
    for mod in (APP / "modules").iterdir():
        if mod.is_dir() and mod.name != "__pycache__":
            assert offenders(mod, banned=module_ban(mod.name)) == []


def test_relative_imports_are_resolved_before_matching():
    ban = re.compile(module_ban("assistant"))
    package = "app.modules.assistant"

    def flagged(source: str) -> list[str]:
        return [n for _, n in imported_names(source, package) if ban.match(n)]

    assert flagged("from ..records import service\n") == [
        "app.modules.records",
        "app.modules.records.service",
    ]
    assert flagged("from .. import records\n") == ["app.modules.records"]
    assert flagged("from ... import registry\n") == ["app.registry"]
    assert flagged("from .schemas import GenUiStreamRequest\nfrom . import agent\n") == []
