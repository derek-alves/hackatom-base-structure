#!/usr/bin/env bash
set -euo pipefail
root=$(git rev-parse --show-toplevel); tmp=$(mktemp -d)
git -C "$root" worktree add -q --detach "$tmp" HEAD
trap 'git -C "$root" worktree remove --force "$tmp"' EXIT
cd "$tmp"
scripts/new_module.sh zz_demo
! scripts/new_module.sh zz_demo 2>/dev/null       # duplicado falha
! scripts/new_module.sh Bad-Name 2>/dev/null       # nome inválido falha
(cd backend && uv sync -q && uv run pytest -q -m "not e2e" && uv run ruff check .)
(cd mobile && fvm flutter pub get && fvm flutter analyze && fvm flutter test)
grep -q "zz_demo" backend/app/registry.py && grep -q "ZzDemoModule" mobile/lib/app/registry.dart
echo OK
