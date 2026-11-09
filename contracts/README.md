# Contrato A2UI v1.0

Fonte única para backend, mobile e skills. O Pydantic em `backend/app/core/a2ui/components.py` gera `catalog.json`.

- `APP_CATALOG_ID = "https://hackathon-starter.dev/catalogs/app/v1/catalog.json"`
- Uma surface por widget, com id `s_<uuid8>_<i>`. Componente raiz com `id: "root"`.
- Props em camelCase.

```json
{"version":"1.0","createSurface":{"surfaceId":"s_ab12cd34_0","catalogId":"<APP_CATALOG_ID>","components":[{"id":"root","component":"SummaryKpiCard"}]}}
```

## Componentes e ações

| Componente | Props (obrigatórias **negrito**) | Ação (`event.name` → `context`) |
|---|---|---|
| `SummaryKpiCard` | **title** str, **value** str, deltaPercent number, **status** `positive\|negative\|neutral`, caption str | — |
| `ActionChecklistCard` | **title**, **items** [{**id**, **label**, **done** bool}], submitLabel="Confirmar" | `checklist_submitted` → `{checkedIds: [str], uncheckedIds: [str]}` |
| `ApprovalConfirmationCard` | **title**, **summary**, **referenceId**, fields [{**label**, **value**}], approveLabel="Aprovar", rejectLabel="Recusar" | `approval_decided` → `{referenceId, decision: approved\|rejected}` |
| `InfoListCard` | **title**, **items** [{**id**, **icon** `task\|info\|warning\|check\|person\|money`, **title**, subtitle, badge}] | — |
| `DynamicFormCard` | **title**, description, **fields** [{**name**, **label**, **type** `text\|number\|date\|select`, required bool=false, options [str], placeholder}], submitLabel="Enviar" | `form_submitted` → `{values: {name: value}}` |

Limites: `items` de 1 a 20; `fields` até 8.

Exemplos de props: `examples/<Component>.json`. Catálogo gerado: `catalog.json` (não edite à mão).

## Renderer para agente

Cada ação vai no corpo da requisição como `{"messages":[{"version":"1.0","action":{"name","surfaceId","sourceComponentId","timestamp","context"}}]}`.

## `POST /api/genui/stream`

Corpo (camelCase):

```json
{
  "sessionId": "...",
  "userId": "mobile-user",
  "text": "...",
  "attachments": [{"mimeType": "image/jpeg", "dataBase64": "..."}],
  "a2ui": {"messages": [ /* renderer→agente */ ]}
}
```

Resposta `text/event-stream`:

```text
event: status  data: {"label": "Processando..." | "Consultando dados..."}
event: text    data: {"markdown": "..."}
event: a2ui    data: <envelope A2UI v1.0>
event: error   data: {"message": "..."}
event: done    data: {}
```

`done` é sempre o último frame, inclusive após `error`.

Corpo inválido (sem texto, imagem ou ação; anexo que não é imagem, base64 inválido ou acima de 5 MB; ação A2UI malformada) responde 422 antes do stream, com mensagens em pt-BR e sem ecoar a entrada:

```json
{"detail": [{"loc": ["body", "attachments", 0, "dataBase64"], "msg": "O anexo excede 5 MB."}]}
```

O app mostra `detail[].msg` ao usuário. O servidor guarda os últimos 6 turnos da sessão (`history` no state do ADK) e os envia ao modelo, então uma ação como `approval_decided` chega com o contexto do widget que a gerou.

## Adicionar um componente

1. Crie o modelo de props (subclasse de `ComponentProps`, com `COMPONENT_NAME`) no módulo e liste em `AppModule.ui_components` (ou em `CORE_COMPONENTS`, se genérico).
2. Crie a fixture `contracts/examples/<Component>.json` com props em camelCase e texto em pt-BR.
3. Rode `cd backend && uv run python -m app.export_catalog` e commite `contracts/catalog.json`.
4. Implemente o `ComponentImplementation` correspondente no app Flutter e registre no catálogo do renderer.
