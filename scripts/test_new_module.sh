#!/usr/bin/env bash
set -euo pipefail
root=$(git rev-parse --show-toplevel); tmp=$(mktemp -d)
git -C "$root" worktree add -q --detach "$tmp" HEAD
trap 'git -C "$root" worktree remove --force "$tmp"' EXIT
cd "$tmp"
scripts/new_module.sh zz_demo
if scripts/new_module.sh zz_demo 2>/dev/null; then echo "duplicate should fail" >&2; exit 1; fi
if scripts/new_module.sh Bad-Name 2>/dev/null; then echo "invalid name should fail" >&2; exit 1; fi
(cd backend && uv sync -q && uv run pytest -q -m "not e2e" && uv run ruff check .)
(cd mobile && fvm flutter pub get && fvm flutter analyze && fvm flutter test)
grep -q "zz_demo" backend/app/registry.py || { echo "backend registry entry missing" >&2; exit 1; }
grep -q "ZzDemoModule" mobile/lib/app/registry.dart || { echo "mobile registry entry missing" >&2; exit 1; }
echo OK
