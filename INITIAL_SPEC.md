# Especificação Técnica: Hackathon AI-Native Starter (mobile/ + backend/)

## 1. Visão Geral e Objetivo

Construir um monorepo AI-Native pré-configurado para hackathons corporativos mobile-first. O repositório deve ser altamente legível e manipulável pelo Claude Code, contendo regras de contexto (`CLAUDE.md` e `.claude/rules/`) e comandos executáveis (`.claude/skills/`) que permitam adaptar o Design System e criar novos fluxos de ponta a ponta (ADK 2.0 + API + Flutter GenUI) em minutos.

## 2. Estrutura de Diretórios do Monorepo

```text
hackathon-starter/
├── CLAUDE.md                          # Roteador mestre (< 200 linhas) com comandos e arquitetura
├── INITIAL_SPEC.md                    # Este documento de especificação
├── .claude/
│   ├── rules/
│   │   ├── flutter-genui.md           # Guardrails para mobile/** (Tokens, Riverpod/State, GenUI)
│   │   └── backend-adk2.md            # Guardrails para backend/** (Google ADK 2.0, FastAPI, DB)
│   └── skills/
│       ├── boot-theme/
│       │   └── SKILL.md               # /boot-theme: Adapta paleta, tipografia e identidade visual
│       ├── new-flow/
│       │   └── SKILL.md               # /new-flow: Cria Workflow ADK 2.0 + Rota API + CatalogItem GenUI
│       └── add-genui-widget/
│           └── SKILL.md               # /add-genui-widget: Cria e registra componente visual no catálogo
├── backend/                           # Python 3.11+ | uv | Google ADK 2.0 | FastAPI | SQLite/SQLModel
│   ├── app/
│   │   ├── main.py                    # Entrypoint FastAPI + CORS + Lifespan (DB init)
│   │   ├── core/
│   │   │   └── config.py              # Settings via Pydantic (GEMINI_API_KEY, DATABASE_URL, etc.)
│   │   ├── db/
│   │   │   ├── database.py            # Engine assíncrona (aiosqlite) + Session dependency
│   │   │   └── models.py              # Modelos base (SessionLog, ActionItem, etc.)
│   │   ├── agents/
│   │   │   ├── workflow_base.py       # Abstração e exemplo de grafo híbrido (ADK 2.0)
│   │   │   └── root_agent.py          # Agente coordenador com instruções A2UI/GenUI
│   │   ├── tools/
│   │   │   └── db_tools.py            # Tools Python tipadas para leitura/escrita no banco
│   │   └── api/
│   │       ├── routes.py              # Endpoints REST (/health, /items, /sessions)
│   │       └── genui_stream.py        # Endpoint SSE (/api/chat/stream) compatível com GenUI/A2UI
│   ├── tests/
│   └── pyproject.toml
└── mobile/                            # Flutter (Stable >= 3.35) | Material 3 | GenUI SDK
    ├── lib/
    │   ├── main.dart
    │   ├── core/
    │   │   ├── config/
    │   │   │   └── app_config.dart    # Base URL configurável (localhost, emulador, Cloud Run)
    │   │   ├── theme/
    │   │   │   ├── app_tokens.dart    # Fonte única da verdade (Cores, Tipografia, Espaçamentos, Raios)
    │   │   │   └── app_theme.dart     # ThemeData Material 3 gerado a partir de AppTokens
    │   │   └── network/
    │   │       └── api_client.dart    # Cliente HTTP/SSE para comunicação com o backend
    │   ├── genui/
    │   │   ├── catalog/
    │   │   │   ├── app_catalog.dart   # Registro central de CatalogItems
    │   │   │   └── widgets/           # 5 widgets genéricos de negócio (KPI, Checklist, Approval, etc.)
    │   │   └── surface/
    │   │       └── genui_manager.dart # Configuração de SurfaceController e A2uiTransportAdapter
    │   └── features/
    │       ├── home/                  # Tela inicial mobile-first com ações rápidas e input multimodal
    │       └── assistant/             # Tela de interação dinâmica renderizando GenUiSurface + fallback Markdown
    └── pubspec.yaml
```

## 3. Requisitos Técnicos por Camada

### A. Camada de Inteligência do Repositório (`.claude/`)

1. **`CLAUDE.md` (Raiz):**
   - Documentar comandos exatos de build, run, lint e teste para `backend/` (`uv run ...`) e `mobile/` (`flutter ...`).
   - Explicar o fluxo de comunicação entre Flutter GenUI e Backend ADK 2.0.
   - Instruir o Claude Code a sempre consultar `.claude/rules/` e usar `.claude/skills/` para tarefas estruturais.
2. **`.claude/rules/backend-adk2.md`** (frontmatter `paths: ["backend/**"]`):
   - Exigir tipagem estrita (Pydantic v2) em todas as Tools e schemas de entrada/saída.
   - Definir o padrão de construção de agentes e grafos no Google ADK 2.0 (separando nós determinísticos de código e nós de Agent, usando callbacks de ciclo de vida sem sobrescrever métodos internos).
   - Exigir que toda resposta destinada à UI siga o contrato JSON/A2UI esperado pelo catálogo do Flutter.
3. **`.claude/rules/flutter-genui.md`** (frontmatter `paths: ["mobile/**"]`):
   - Proibir cores, fontes ou espaçamentos hardcoded nas telas; tudo deve vir de `AppTokens`.
   - Padronizar a criação de componentes GenUI usando `CatalogItem` e `json_schema_builder`, mantendo sincronia com os schemas do backend.
   - Exigir estados de loading, tratamento de erro de rede e fallback visual caso o payload do agente não corresponda a um widget registrado.
4. **`.claude/skills/`:**
   - `boot-theme/SKILL.md`: Recebe um briefing de marca/tema, atualiza `app_tokens.dart`, ajusta o nome/subtítulo do app na Home e valida com `flutter analyze`.
   - `new-flow/SKILL.md`: Recebe a descrição de um fluxo de negócio e executa em sequência: (1) define contrato JSON, (2) cria agente/workflow no ADK 2.0 + tool de banco, (3) expõe na API, (4) cria e registra `CatalogItem` no Flutter, (5) atualiza o prompt do agente com exemplo few-shot do novo widget, (6) roda testes e lint.
   - `add-genui-widget/SKILL.md`: Cria um novo widget visual baseado em `AppTokens`, registra no `app_catalog.dart` e documenta o schema para o backend.

### B. Camada Backend (`backend/`)

1. **Stack e Dependências:** Python 3.11+, gerenciado via `uv`, `google-adk` (>= 2.0), `fastapi`, `uvicorn`, `sqlmodel`, `aiosqlite`, `pydantic-settings`, `pytest`.
2. **Banco de Dados:** SQLite assíncrono configurado na inicialização do FastAPI, com tabelas prontas para persistir sessões/histórico e entidades de negócio genéricas (ex: `TaskRecord`).
3. **Abstração ADK 2.0:**
   - Um fluxo exemplo funcional (`workflow_base.py`) demonstrando: recebimento de input (texto ou mídia), consulta ao banco via Tool, raciocínio de Agent e retorno de payload estruturado para renderização no GenUI.
4. **API e Streaming:**
   - Rota REST `/api/health` e CRUD básico `/api/records`.
   - Rota `/api/genui/stream` (SSE / HTTP Stream) conectando o input do app mobile ao Runner do ADK 2.0 e emitindo eventos compatíveis com o transporte do Flutter GenUI.

### C. Camada Mobile (`mobile/`)

1. **Stack e Dependências:** Flutter estável, Material 3, pacote `genui` (SDK oficial Flutter GenUI / protocolo A2UI), `json_schema_builder`, `http`/`dio` para rede, `image_picker` (para suporte rápido a câmera/galeria).
2. **Design System Adaptável (`core/theme/`):**
   - Classe `AppTokens` centralizando `primaryColor`, `secondaryColor`, `surfaceColor`, `errorColor`, `borderRadius`, `spacing` e `textTheme`.
   - Função `AppTheme.build()` que gera o `ThemeData` completo do Material 3 a partir dos tokens.
3. **Integração GenUI (`genui/`):**
   - Configuração pronta do `SurfaceController` e do adaptador de transporte HTTP/SSE apontando para `AppConfig.apiBaseUrl`.
   - **Catálogo Inicial (5 Widgets Prontos):**
     1. `SummaryKpiCard`: Exibe título, valor destaque, variação percentual e status.
     2. `ActionChecklistCard`: Lista interativa de tarefas/itens que o usuário pode marcar e disparar evento de volta ao agente.
     3. `ApprovalConfirmationCard`: Card de revisão com dados resumidos e botões "Aprovar" / "Recusar" que enviam ação ao backend.
     4. `InfoListCard`: Lista estruturada de itens com ícone, título, subtítulo e badge.
     5. `DynamicFormCard`: Formulário curto gerado dinamicamente pelo agente para coletar dados faltantes do usuário.
4. **Telas Base (`features/`):**
   - **Home:** Cabeçalho limpo, cards de atalho para disparar fluxos rápidos e barra inferior com input de texto + botão de câmera/anexo.
   - **Assistant / Canvas:** Área principal renderizando a `GenUiSurface` com indicadores visuais de progresso do agente ("Processando...", "Consultando dados...") e fallback em Markdown.

## 4. Critérios de Aceite da Inicialização

O setup inicial será considerado concluído quando:

1. O backend subir com `uv run fastapi dev app/main.py`, criar o banco SQLite automaticamente e responder `200 OK` em `/api/health`.
2. O app Flutter compilar sem erros (`flutter analyze` limpo) e exibir a Home usando os tokens do Design System.
3. Houver um fluxo de exemplo integrado onde o app mobile envia uma mensagem para o endpoint do backend, o agente ADK 2.0 processa e retorna um `SummaryKpiCard` ou `ActionChecklistCard` renderizado nativamente na tela pelo GenUI.
4. Os arquivos `.claude/rules/*.md` e `.claude/skills/*/SKILL.md` estiverem criados e referenciados no `CLAUDE.md`.
