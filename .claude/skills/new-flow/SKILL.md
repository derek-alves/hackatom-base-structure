---
name: new-flow
description: Use quando precisar de um fluxo de negócio novo de ponta a ponta (domínio, tool do agente, widget, prompt e testes), por exemplo aprovação de reembolso.
argument-hint: "<nome do domínio em snake_case> <descrição do fluxo>"
---

# /new-flow

Cria um fluxo completo no padrão modular: módulo (backend e mobile), contrato, tool, widget, prompt e testes.

## Entrada esperada

- Nome do domínio em snake_case (ex.: `reimbursements`) e se ele já existe em `backend/app/modules/` / `mobile/lib/modules/`.
- Descrição do fluxo: o que o usuário pede, que dados o agente busca ou grava, que widget mostra e que ação volta.

## Passos

0. Módulo:
   - Domínio novo: `scripts/new_module.sh <nome>` (cria `backend/app/modules/<nome>/`, `mobile/lib/modules/<nome>/`, testes, e registra em `backend/app/registry.py` e `mobile/lib/app/registry.dart`).
   - Domínio existente: trabalhe dentro de `modules/<nome>/`.
1. Contrato: reutilize um componente existente (veja `contracts/README.md`) ou execute `/add-genui-widget` (de domínio, com o `<nome>`).
2. Tool(s) em `backend/app/modules/<nome>/tools.py`:
   - `async`, tipadas, docstring em pt-BR, retornam `dict` via `model_dump(mode="json")`. Lógica em `service.py`; modelos em `models.py`/`schemas.py`. Use `backend/app/modules/records/tools.py` como referência.
   - Liste a tool em `TOOLS` (a lista que o `__init__.py` passa para `AppModule.tools`).
   - Teste em `backend/tests/modules/<nome>/test_tools.py`.
   - Se o fluxo precisa de roteamento próprio, adicione um nó de código com `Event(route=...)` em `backend/app/modules/assistant/workflow.py`.
3. API: CRUD REST em `backend/app/modules/<nome>/router.py` se necessário (o chat já passa pelo stream). Teste em `backend/tests/modules/<nome>/test_router.py`.
4. Mobile: crie e registre o `ComponentImplementation` (feito no passo 1 via `/add-genui-widget`). Se há ação, o fluxo de volta já funciona: `dispatchAction` envia a ação no próximo POST e o agente a recebe em `a2ui.messages`.
5. Prompt: a fixture entra sozinha no few-shot. Adicione a regra de "quando usar" em `build_instruction()` (`backend/app/modules/assistant/agent.py`), em pt-BR, mencionando a tool e o componente. Ajuste `backend/tests/modules/assistant/test_workflow.py` se ele compara o texto da instrução.
6. Testes e lint dos dois lados (comando abaixo). Opcional: `QuickAction` na Home em `mobile/lib/modules/home/quick_actions.dart`.

## Exemplo: aprovação de reembolso

1. `scripts/new_module.sh reimbursements`.
2. Reutilize `ApprovalConfirmationCard` (ação `approval_decided` com `{referenceId, decision}`); nenhum componente novo.
3. Em `backend/app/modules/reimbursements/tools.py`, crie `create_reimbursement(...)` que grava o reembolso e retorna `{"referenceId": ..., ...}`; adicione a `TOOLS`. Teste em `backend/tests/modules/reimbursements/test_tools.py`.
4. Em `build_instruction()`, regra: "quando o usuário pedir um reembolso, chame `create_reimbursement` e mostre `ApprovalConfirmationCard` com o `referenceId` retornado".
5. Quando a ação `approval_decided` voltar, o agente confirma o resultado em texto.
6. `QuickAction` opcional "Pedir reembolso" na Home.

## Verificação

```bash
(cd backend && uv run pytest -m "not e2e" && uv run ruff check . && uv run ruff format --check .) \
  && (cd mobile && fvm flutter analyze && fvm dart format --set-exit-if-changed lib test && fvm flutter test)
```

## Pronto quando

- O módulo existe nos dois lados e está registrado nas composition roots.
- Tool, widget, regra de prompt e testes existem, e o contrato (`catalog.json`) está atualizado.
- A verificação acima passa.
