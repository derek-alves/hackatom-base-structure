# 0004 - Provider de LLM configurável, fallback e modo demo

Status: aceita (2026-11-23).

## Contexto

No hackathon, a IA da solução fala com os modelos por um proxy de IA da empresa, na infra do Google, com chave de API. O proxy oferece modelos Gemini, Anthropic e open source. O formato do proxy só será mostrado no dia.

Até aqui o backend só falava com o Gemini pelo AI Studio (`GEMINI_API_KEY` e `GEMINI_MODEL`). Nos testes de 2026-11-23, o Gemini devolveu `429 RESOURCE_EXHAUSTED` (cota grátis de 20 requisições/dia) e `503 UNAVAILABLE`. A apresentação dura 10 minutos e é ao vivo, então uma falha de rede ou de cota derruba a demo.

## Decisão

**Provider por variável.** `app/core/llm.py` monta o modelo a partir de `LLM_PROVIDER`, com adaptadores que já vêm no ADK 2.x:

| `LLM_PROVIDER` | Classe do ADK | Uso |
|---|---|---|
| `gemini` (padrão) | `Gemini` | AI Studio. A chave vai para `GEMINI_API_KEY` no ambiente, que é onde o `google-genai` a lê |
| `apigee` | `ApigeeLlm` | Proxy Apigee do Google. `LLM_BASE_URL` é a URL do proxy, e o prefixo `apigee/` entra sozinho no modelo |
| `openai` | `OpenAILlm` (`google-adk[openai]`) | Qualquer endpoint compatível com OpenAI, como LiteLLM proxy e gateways. Serve para Claude e open source |

Os nomes `GEMINI_API_KEY` e `GEMINI_MODEL` continuam valendo como fallback de `LLM_API_KEY` e `LLM_MODEL`. Um `LLM_*` vazio, como vem do `.env.example`, não esconde um `GEMINI_*` preenchido.

**Retry e fallback.**
- Cada modelo recebe retry próprio (`LLM_RETRY_ATTEMPTS`, padrão 3) para 408, 429 e 5xx. No `gemini` e no `apigee` isso é `HttpRetryOptions`; no `openai`, `max_retries` do cliente.
- Com `LLM_FALLBACK_MODELS`, o `FallbackModel` do ADK tenta os modelos em ordem quando um falha com 429 ou 5xx. O recurso é experimental no ADK, mas vem ligado por padrão e só emite um aviso.
- O fallback fica no mesmo provider, o que basta para o proxy, que já reúne vários modelos.

**Modo demo** (`app/modules/assistant/demo.py`):
- `DEMO_MODE=record` embrulha o modelo em `RecordingLlm`, que grava cada resposta em `DEMO_RECORDINGS_PATH`.
- `DEMO_MODE=replay` troca o modelo por `ReplayLlm`, que responde da gravação sem chamar o LLM e sem chave.
- As tools rodam de verdade nos dois modos.
- Chave da gravação: o turno do usuário (texto normalizado, linhas `[ui_action]` e hash das imagens), sem o histórico e o "Contexto do banco" que o `prepare_input` acrescenta, mais o índice da chamada dentro do turno. Assim a ordem das perguntas no palco pode mudar, e os KPIs podem estar diferentes do ensaio.
- A gravação guarda o `output_schema_and_tools` do modelo gravado. O `ReplayLlm` reporta o mesmo valor; sem isso, o ADK não registraria a tool `set_model_response` que as respostas gravadas chamam.
- Pergunta fora do roteiro responde com aviso (`REPLAY_MISS_MESSAGE`), não com erro.
- O `/api/health` mostra `llmProvider` e `demoMode`, e `llmConfigured` fica `true` no `replay`.

O modo demo fica no módulo `assistant`, não no `core`, porque a chave depende do formato do turno que o `workflow.py` monta. O `main.py` (composition root) chama `build_assistant_model(settings)`.

## Consequências

- No dia, trocar para o proxy é editar `backend/.env`.
- Os três providers reportam hoje `output_schema_and_tools=False`, então todos usam o caminho `set_model_response`, já coberto pelos testes com `StudioLlm`. Risco: Claude ou modelos open source via proxy podem preencher o schema pior que o Gemini. O `coerce_prose_reply` salva respostas em prosa, mas não um schema errado.
- A dependência `openai` entrou com o extra `google-adk[openai]`.
- Os testes ganharam uma fixture `autouse` que limpa `LLM_*`, `GEMINI_*` e `DEMO_*` do ambiente. O `lifespan` exporta `GEMINI_API_KEY`, e sem a limpeza uma chave de um teste vazava para o próximo e chegava ao Gemini real.
- `data/` não é versionado e, no Podman, fica no volume. Para entregar uma gravação, copie o arquivo para fora de `data/` e aponte `DEMO_RECORDINGS_PATH` para ele.

## Alternativas consideradas

- **`LiteLlm` para endpoints OpenAI.** Descartado: puxa o pacote `litellm` inteiro, e o `OpenAILlm` do próprio ADK cobre o mesmo caso com o SDK oficial.
- **`Claude` direto (Anthropic ou Vertex).** Adiado: exige `anthropic` e credenciais do GCP. Pelo proxy, o Claude já chega via `openai` ou `apigee`.
- **Fallback entre providers diferentes.** Adiado: exigiria uma lista de pares provider/modelo. Dá para adicionar se o proxy não reunir todos os modelos.
- **Replay com chave pelo request inteiro.** Descartado: histórico, KPIs e ids de chamada de função mudam entre ensaio e palco, e nada bateria.

## Verificação

- 2026-11-23: 117 testes do backend verdes (`uv run pytest -m "not e2e"`), com `ruff` limpo. Os testes cobrem a montagem dos providers, a cadeia de fallback, o record/replay nos caminhos nativo e `set_model_response`, o aviso fora do roteiro e o stream em `replay` sem chave.
- Pendente: proxy real, fallback e demo com modelo real. Ver o item 5 de `docs/test-plan.md`.
