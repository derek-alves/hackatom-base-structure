---
name: add-genui-widget
description: Use quando precisar de um componente A2UI novo (widget que o agente renderiza no app), do modelo Pydantic ao ComponentImplementation Flutter.
argument-hint: "<NomePascalCase> <props> [ação] [genérico|módulo <nome>]"
---

# /add-genui-widget

Adiciona um componente ao contrato nas 3 fontes: Pydantic + fixture, `contracts/catalog.json` gerado e `ComponentImplementation`. Contrato completo em `contracts/README.md`.

## Entrada esperada

- Nome PascalCase terminado em `Card` por convenção (ex.: `ProgressStepsCard`). Abaixo, `<snake>` é o mesmo nome em snake_case (`progress_steps_card`).
- Props: nome, tipo e se é obrigatória. Limites de lista (`min_length`/`max_length`) quando houver.
- Ação opcional: `event.name` em snake_case e o `context` enviado.
- Escopo: genérico (serve a qualquer domínio) ou de domínio (`<nome>`). Se o domínio é novo, rode antes `scripts/new_module.sh <nome>`.

## Passos

1. Modelo Pydantic: subclasse de `ComponentProps` com `COMPONENT_NAME: ClassVar[str] = "<Name>"` e docstring curta (o LLM lê). Sub-modelos de itens usam `model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)`. Siga `SummaryKpiCard` e `InfoListCard`.
   - Genérico: em `backend/app/core/a2ui/components.py`, e adicione a classe à lista `CORE_COMPONENTS`.
   - De domínio: em `backend/app/modules/<nome>/ui.py` (crie o arquivo) com `UI_COMPONENTS: list[type[ComponentProps]] = [<Name>]`, e em `backend/app/modules/<nome>/__init__.py` passe `ui_components=UI_COMPONENTS` ao `AppModule`.
   - O campo `<snake>` em `UiResponse` é gerado sozinho.
2. Fixture `contracts/examples/<Name>.json`: props em camelCase, texto em pt-BR, valores literais.
3. Teste do backend:
   - Genérico: em `backend/tests/core/test_a2ui_contract.py`, inclua `"<snake>"` no conjunto esperado de `test_ui_response_model_has_one_optional_field_per_component`. A validação da fixture já é parametrizada sobre `CORE_COMPONENTS`.
   - De domínio: crie `backend/tests/modules/<nome>/test_ui.py` que valida a fixture com `<Name>.model_validate(...)`.
4. Regenerar o catálogo: `cd backend && uv run python -m app.export_catalog`. Commite `contracts/catalog.json`.
5. Componente Flutter:
   - Genérico: `mobile/lib/core/a2ui/components/<snake>.dart`.
   - De domínio: `mobile/lib/modules/<nome>/a2ui/<snake>.dart`.
   - Use `mobile/lib/core/a2ui/components/summary_kpi_card.dart` como base: `final ComponentImplementation <camel>Component = ComponentImplementation(name: '<Name>', schema: Schema.object(properties: {...}, required: [...]), builder: ...)`. O `required` tem de ser igual ao de `contracts/catalog.json` e os nomes de props em camelCase.
   - Leitura das props: escalares com `props.string('x')`, `props.number('x')`; listas e objetos com `props.value('x')` (retorna `Object?`; faça cast para `List`/`Map`, como em `info_list_card.dart`). Listas no schema: `Schema.list(items: Schema.object(...))`.
   - Estilo só via `context.tokens` e `Theme.of(context)` (sem cor, tamanho, `EdgeInsets` ou raio literal).
   - Ação: `node.context?.dispatchAction({'event': {'name': '<acao>', 'context': {...}}})`. Veja `approval_confirmation_card.dart`. Evite duplo envio, como ele faz.
6. Registrar:
   - Genérico: importe o arquivo e inclua `<camel>Component` em `coreComponents` (`mobile/lib/core/a2ui/core_components.dart`).
   - De domínio: em `mobile/lib/modules/<nome>/<nome>.dart`, troque `const []` por `[<camel>Component]` em `a2uiComponents` (o getter deixa de ser `const`).
7. Se há ação, documente `event.name` e `context` na tabela de `contracts/README.md` (e na tabela do componente).
8. Teste de widget:
   - Genérico: em `mobile/test/core/a2ui/widgets_test.dart`, com `pumpComponent(t, '<Name>', fixture('<Name>'))` (`mobile/test/helpers/a2ui_harness.dart`).
   - De domínio: em `mobile/test/modules/<nome>/`, com o mesmo helper.
   - Se há ação, assert em `h.actions` (nome e `context`) e em `h.errors` vazio.
   - O teste de contrato `mobile/test/core/a2ui/contract_test.dart` já cobre todo componente do catálogo (fixture + `required` vs `catalog.json`); não precisa de edição.
9. Few-shot e prompt: a fixture entra sozinha em `build_instruction()` (`backend/app/modules/assistant/agent.py`). Para dizer quando usar o componente, siga `/new-flow` passo 5.

## Verificação

```bash
(cd backend && uv run pytest -m "not e2e" && uv run ruff check . && uv run ruff format --check .) \
  && (cd mobile && fvm flutter analyze && fvm dart format --set-exit-if-changed lib test && fvm flutter test)
```

## Pronto quando

- Pydantic, fixture, `contracts/catalog.json` e `ComponentImplementation` existem e concordam (`test_catalog_json_is_up_to_date` e `contract_test.dart` passam).
- O componente está registrado (`CORE_COMPONENTS`/`coreComponents` ou `AppModule.ui_components`/`a2uiComponents`).
- Ação documentada em `contracts/README.md`, se houver.
- Os dois lados têm teste de widget/contrato e a verificação acima passa.
