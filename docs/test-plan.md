# Plano de testes pendentes

O que falta testar no projeto inteiro: bootstrap, design system e Docker. Atualizado em 2026-11-13.

Duas partes:

- **Verificações manuais:** precisam de algo que a máquina de desenvolvimento não tinha (chave do Gemini, Docker, Figma). Cada item tem passos e resultado esperado.
- **Testes automatizados que faltam:** lacunas conhecidas nas suítes. Ajustes de código que não são teste ficam em [`backlog.md`](backlog.md).

Ao concluir um item, apague-o daqui e registre o resultado (data, ambiente, evidência) no documento indicado em "Registrar em". Se não houver documento indicado, registre no [Histórico](#histórico) no fim deste arquivo.

## Verificações manuais

### 1. Fluxo completo com o Gemini real

Origem: critério de aceite 3 do bootstrap (`docs/superpowers/plans/2026-11-09-hackathon-starter-bootstrap.md`, Task 17) e item 2 de "Depois deste projeto" da spec do design system. Hoje o caminho do agente só foi provado com `FakeLlm`. O teste e2e foi pulado por falta de chave.

Pré-requisitos: `GEMINI_API_KEY` em `backend/.env`, simulador iOS e emulador Android.

Os passos chamam o Gemini de verdade e consomem cota.

1. `cd backend && uv run pytest -m e2e -v`. Esperado: PASS.
2. Smoke do stream, com o backend no ar:

   ```bash
   curl -N -X POST localhost:8000/api/genui/stream \
     -H 'content-type: application/json' \
     -d '{"sessionId":"t","text":"Resumo das tarefas"}'
   ```

   Esperado: frames `a2ui`, sem `error`.
3. No app (simulador iOS e emulador Android), tocar "Resumo de indicadores". Esperado: `SummaryKpiCard` nativo.
4. Tocar "Minhas pendências", marcar itens e tocar "Confirmar". Esperado: o agente responde, e `GET /api/records?status=done` reflete a mudança.
5. Pedir algo que gere resposta em texto. Esperado: o markdown aparece com cor e tamanho do tema. Ainda não houve verificação em device do markdown (ADR 0002).
6. Tirar screenshots da Home e do assistente nas duas plataformas. A screenshot da Home no Android nunca foi capturada.

Risco conhecido: na primeira execução real, a saída do Gemini pode não bater com o schema (camelCase × snake_case).

### 2. Backend em Docker

Origem: `docs/decisions/0003-backend-docker.md` e checklist do PR #2. A máquina onde o Docker foi configurado não tinha Docker, então a imagem nunca foi construída.

Pré-requisito: Docker com Compose v2.

1. Na raiz, `docker compose up --build`. Depois, `curl http://localhost:8000/api/health`. Esperado: `200` com `{"status":"ok",...}`.
2. `docker compose ps`. Esperado: serviço `backend` como `healthy`.
3. `docker compose watch` e editar um arquivo em `backend/app`. Esperado: o serviço reinicia com a mudança.
4. Criar um registro (`POST /api/records`), rodar `docker compose down` e `docker compose up` de novo. Esperado: o registro continua lá. Depois de `docker compose down -v`, o banco volta ao seed.
5. App no emulador Android com o backend no container (`http://10.0.2.2:8000`, o padrão do app). Esperado: o app conversa com o backend.

Registrar em: seção "Verificação" da ADR 0003 (tirar a linha "Pendente").

### 3. Importar o contrato de tokens no Figma

Origem: `docs/design-system/token-contract.md`, seção "Importar no Figma" (status "a validar no primeiro projeto").

1. Num arquivo do Figma, importar `mobile/packages/design_system/tokens/contract/light.tokens.json` e `dark.tokens.json`. Tentar primeiro a opção nativa do modal de variáveis. Se não houver ou não aceitar os arquivos, usar o plugin TokensBrücke.
2. Esperado: as variáveis aparecem com os nomes do contrato, com os modos light e dark.

Registrar em: `token-contract.md`. Anotar o caminho que funcionou (menu ou plugin, versão do Figma, plano) e tirar a marca "a validar".

### 4. Primeiro `/boot-theme` com um Figma real

Origem: próximos passos do design system. O rebrand só foi provado com o exemplo `tokens/examples/alt-brand` (ADR 0002, "Demo de rebrand").

1. Rodar `/boot-theme <url-do-figma>` com o Figma de um projeto real.
2. Esperado: só mudam dados. São eles `tokens/`, `mapping.yaml`, os arquivos gerados, os goldens, as fontes e o `AppBrand`. Nenhum widget é editado.
3. Em `mobile/packages/design_system`, rodar `fvm dart run design_system:build_tokens --check` e `fvm flutter test`. Esperado: verde.
4. Em `mobile`, rodar `fvm flutter analyze` e `fvm flutter test`. Esperado: verde.
5. Abrir o app no device. Esperado: a marca nova aparece na Home e nos cards do assistente.

Registrar em: ADR 0002, ao lado da "Demo de rebrand".

## Testes automatizados que faltam

Antes de escrever um teste, confirme que a lacuna ainda vale no código atual.

### Execução

- O repo não tem CI (não há `.github/`). A regressão roda só local:

  ```bash
  (cd backend && uv run pytest -m "not e2e" && uv run ruff check . && uv run ruff format --check .)
  (cd mobile && fvm flutter analyze && fvm dart format --set-exit-if-changed lib test && fvm flutter test)
  (cd mobile/packages/design_system && fvm dart run design_system:build_tokens --check && fvm flutter test)
  bash scripts/test_new_module.sh
  ```

### Backend

- O teste do limite superior (`limit=999` → 50) não verifica o corte de fato, porque o seed só tem 6 linhas.
- Falta teste para base64 inválido (`"!!!"`) → 422.

### Mobile

- O padrão Android `10.0.2.2` em `AppConfig` não tem teste.
- Os testes de página esperam 300 ms fixos em `runAsync`. Esperar um estado do cubit, porque o tempo fixo pode falhar de vez em quando num CI.
- `sent` é mutável no topo de `assistant_cubit_test.dart`.
- Os helpers de SSE enlatado estão duplicados entre `genui_manager_test` e `test/helpers/sse.dart`.

### Design system (`mobile/packages/design_system`)

Caminhos relativos ao pacote, salvo indicação.

- `build_tokens`: faltam testes dos códigos de saída da CLI e da mensagem do `--check`, do raio `{value, unit}` e do peso com espaço ("Semi Bold").
- Asserções fracas:
  - dispose do controller da data;
  - visibilidade do hint;
  - alturas de `.number`, `.date` e `.select`;
  - borda e fundo do chip de status;
  - variantes do card;
  - `find.byType(SizedBox)` vazio no teste de loading;
  - tema no `catalog_test`.
- Sem teste:
  - loading com label longo a 2.0x;
  - cor e tamanho do spinner;
  - destrutivo desabilitado;
  - `showAppDatePicker` direto;
  - precedência `controller` × `initialValue`;
  - overflow de `.checkbox` e `.navigation`;
  - skeleton do list tile em sm;
  - sumiço do skeleton do assistente com `SurfaceEntry` e `UiProblemEntry`;
  - obrigatório em texto e número no formulário.
- Os testes de "enviar duas vezes" não detectam a remoção da trava `_submitting`, porque o botão desabilitado já absorve o toque.
- Guards:
  - checagem de pasta duplicada entre os dois arquivos;
  - varredura por linha (não pega `Card\n(` e acusa comentários);
  - `listSync` segue symlinks;
  - import só pelo barrel não tem guard (o app cumpre hoje).
- Pequenos: `result` sombreado em `token_set_test`, `kitContractTokens` sem memo e teste vazio em `design_system_test.dart`.

## Histórico

Nenhuma verificação registrada ainda.
