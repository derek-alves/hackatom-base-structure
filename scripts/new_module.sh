#!/usr/bin/env bash
# Gera um módulo (fatia vertical) no backend e no mobile e o registra nas composition roots.
# Uso: scripts/new_module.sh <nome_snake> [--backend-only|--mobile-only]
set -euo pipefail

usage() { echo "Uso: $0 <nome_snake> [--backend-only|--mobile-only]" >&2; exit 1; }

name=""; do_backend=1; do_mobile=1
for arg in "$@"; do
  case "$arg" in
    --backend-only) do_mobile=0 ;;
    --mobile-only) do_backend=0 ;;
    -*) usage ;;
    *) [ -z "$name" ] && name="$arg" || usage ;;
  esac
done
[ -n "$name" ] || usage
if ! [[ "$name" =~ ^[a-z][a-z0-9_]*$ ]]; then
  echo "Nome inválido '$name': use snake_case (^[a-z][a-z0-9_]*$)." >&2; exit 1
fi

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tpl="$root/templates"

pascal=""; IFS='_' read -r -a parts <<< "$name"
for p in "${parts[@]}"; do
  [ -n "$p" ] || continue
  first=$(printf '%s' "${p:0:1}" | tr '[:lower:]' '[:upper:]')
  pascal+="$first${p:1}"
done
camel="$(printf '%s' "${pascal:0:1}" | tr '[:upper:]' '[:lower:]')${pascal:1}"

be_mod="$root/backend/app/modules/$name";  be_test="$root/backend/tests/modules/$name"
mo_mod="$root/mobile/lib/modules/$name";   mo_test="$root/mobile/test/modules/$name"

if [ "$do_backend" = 1 ] && { [ -e "$be_mod" ] || [ -e "$be_test" ]; }; then
  echo "Módulo '$name' já existe no backend." >&2; exit 1
fi
if [ "$do_mobile" = 1 ] && { [ -e "$mo_mod" ] || [ -e "$mo_test" ]; }; then
  echo "Módulo '$name' já existe no mobile." >&2; exit 1
fi

generated=()
# render <template> <destino>: copia substituindo placeholders.
render() {
  mkdir -p "$(dirname "$2")"
  sed -e "s/__name_camel__/$camel/g" -e "s/__Name__/$pascal/g" -e "s/__name__/$name/g" "$1" > "$2"
  generated+=("$2")
}
# render_tree <dir_template> <dir_destino>: renderiza *.tmpl, trocando __name__ nos nomes.
render_tree() {
  local src="$1" dst="$2" f rel
  while IFS= read -r f; do
    rel="${f#"$src"/}"; rel="${rel%.tmpl}"; rel="${rel//__name__/$name}"
    render "$f" "$dst/$rel"
  done < <(find "$src" -name '*.tmpl' -not -path "$src/tests/*" -not -path "$src/test/*" | sort)
}
# insert_before <marcador> <linha> <arquivo>: insere a linha com a indentação do marcador.
insert_before() {
  local marker="$1" line="$2" file="$3" tmp
  grep -q "$marker" "$file" || { echo "Marcador '$marker' ausente em $file." >&2; exit 1; }
  tmp=$(mktemp)
  awk -v m="$marker" -v l="$line" 'index($0, m) { match($0, /^[ \t]*/); print substr($0, 1, RLENGTH) l } { print }' "$file" > "$tmp"
  cat "$tmp" > "$file"; rm -f "$tmp"
}

if [ "$do_backend" = 1 ]; then
  render_tree "$tpl/backend_module" "$be_mod"
  render "$tpl/backend_module/tests/test_router.py.tmpl" "$be_test/test_router.py"
  insert_before "# new_module:import" "from app.modules import $name" "$root/backend/app/registry.py"
  insert_before "# new_module:register" "$name.module," "$root/backend/app/registry.py"
fi
if [ "$do_mobile" = 1 ]; then
  render_tree "$tpl/mobile_module" "$mo_mod"
  render "$tpl/mobile_module/test/__name___cubit_test.dart.tmpl" "$mo_test/${name}_cubit_test.dart"
  insert_before "// new_module:import" "import 'package:hackathon_starter/modules/$name/$name.dart';" "$root/mobile/lib/app/registry.dart"
  insert_before "// new_module:register" "const ${pascal}Module()," "$root/mobile/lib/app/registry.dart"
fi

# Formatação apenas dos arquivos gerados (e do registry tocado).
py=(); dt=()
for f in "${generated[@]}" ${do_backend:+"$root/backend/app/registry.py"}; do
  case "$f" in *.py) py+=("${f#"$root/backend/"}") ;; esac
done
for f in "${generated[@]}"; do
  case "$f" in *.dart) dt+=("${f#"$root/mobile/"}") ;; esac
done
if [ "${#py[@]}" -gt 0 ]; then (cd "$root/backend" && uv run ruff check --select I --fix -q "${py[@]}" || true; uv run ruff format "${py[@]}"); fi
if [ "${#dt[@]}" -gt 0 ]; then (cd "$root/mobile" && fvm dart format "${dt[@]}" lib/app/registry.dart); fi

cat <<EOF

Módulo '$name' criado.
Próximos passos:
  1. Tool do agente: backend/app/modules/$name/tools.py (adicione a função em TOOLS) + teste.
  2. Componente A2UI (opcional): ui_components no AppModule do backend e a2uiComponents em ${pascal}Module.
  3. Rota: backend/app/modules/$name/router.py (GET /api/$name/ping já existe) e a navegação para ${pascal}Page no mobile.
  4. Testes: (cd backend && uv run pytest -q -m "not e2e") e (cd mobile && fvm flutter test).
EOF
