# 0006 - Provider `avenue`: AI Proxy da Avenue pelo `ai-proxy-sdk`

Status: aceita (2026-11-24).

## Contexto

No hackathon, a IA chama os modelos pelo AI Proxy da Avenue (Apigee). Cada app tem uma chave no Dev Portal, com cota por app e por modelo. Os detalhes estão em `docs/infra-ia/README.md`.

O provider `apigee` da ADR 0004 usa o `ApigeeLlm` puro. Ele manda a chave como chave do Gemini, mas o proxy exige os headers `x-apikey` e `x-llm-action`, além de URLs que só o SDK conhece. O time da Plataforma de IA mantém o `ai-proxy-sdk` (repo privado `avenuesec/ai-proxy-sdk`), que monta tudo isso.

## Decisão

**Provider `LLM_PROVIDER=avenue`.** `app/core/llm.py` importa `app/core/avenue_llm.py` só nesse provider. O módulo monta `AvenueLLM(Model, is_adk=True)` do SDK, e o SDK escolhe a classe do ADK:

| Modelo | Classe do SDK | Base no ADK |
|---|---|---|
| Gemini (`gemini-*`) | `AvenueGemini` | `ApigeeLlm` |
| Claude, Mistral, Gemma | `AvenueMultiLLM` | `LiteLlm` (o SDK depende de `litellm`) |

- `LLM_MODEL` e `LLM_FALLBACK_MODELS` aceitam o id do modelo (`gemini-3.5-flash`) ou o nome do enum `ai_proxy.Model` (`GEMINI_3_5_FLASH`). Nome fora do enum falha ao subir, com a lista dos válidos.
- Chave: `LLM_API_KEY` ou `AI_PROXY_API_KEY`. Cada provider só pega a própria chave, então o `GEMINI_API_KEY` do AI Studio nunca vai para o proxy. `AI_PROXY_TEAM`, `AI_PROXY_DEBUG` e `AI_PROXY_SSL_VERIFY` o SDK lê sozinho.
- O `ApigeeLlm` exige `GOOGLE_CLOUD_PROJECT` e `GOOGLE_CLOUD_LOCATION` para os modelos `apigee/vertex_ai/`. Usamos o projeto e a região do próprio SDK só durante a montagem do modelo e depois restauramos o ambiente.

**SDK como extra opcional** (`[project.optional-dependencies] avenue`, fonte git em `[tool.uv.sources]`). `uv sync --extra avenue` instala o SDK; o `uv.lock` grava o commit. Sem o extra, `uv sync --locked` não precisa de git nem de acesso à `avenuesec`. Isso foi verificado com cache vazio e sem credencial, e mantém o Containerfile e o zip dos jurados funcionando. Com `LLM_PROVIDER=avenue` e sem o SDK, o backend falha ao subir e diz o comando.

**ADK 2.15.** O commit do SDK que usávamos (`215e0c2`) foi feito para o ADK 1.x e chamava `ApigeeLlm._merge_tracking_headers`, que existe até o ADK 2.12 e saiu na 2.13. Na 2.14, o cliente do Gemini quebrava com `AttributeError`. Avaliamos três caminhos:

1. Shim no nosso código: subclasse com o método. Funcionava, mas era código nosso cobrindo um bug do SDK.
2. ADK 2.12, sem shim. Exigia descer também o FastAPI de 0.162 para 0.141, porque o ADK 2.12 pede `opentelemetry-api<=1.42.1` e o FastAPI 0.160+ pede `>=1.44`. A suíte passava, mas travava duas libs.
3. SDK novo. No mesmo dia saiu o commit `d1c7ef0` ("require google-adk 2.15 and use its merge_tracking_headers"), que corrige o bug e exige `google-adk>=2.15,<3`.

Ficamos com o 3: `google-adk>=2.15,<3`, a versão mais recente, sem shim e sem downgrade. O ADK 2.15 com o SDK atual inviabiliza o caminho 2.

## Consequências

- Os testes de `tests/core/test_llm.py` montam o modelo e o cliente `google-genai` sem rede, e conferem os headers e a URL do proxy. São pulados (`importorskip`) se o SDK não estiver instalado. Se o SDK e o ADK voltarem a divergir, esses testes falham.
- **Retry.** No Gemini, o SDK transforma 4xx/5xx do proxy em `ApigeeError` num hook do `httpx`, antes do `google-genai`. O `HttpRetryOptions` (`LLM_RETRY_ATTEMPTS`) só repete timeout e erro de conexão. Para 429 e 5xx, o que vale é o `LLM_FALLBACK_MODELS`: o `FallbackModel` lê o `status_code` do `ApigeeError`. Nos modelos `LiteLlm`, o retry é o do SDK (`num_retries=2`).
- **Claude fora do GCP pede ADC.** O LiteLLM (provider `vertex_ai`) busca um token do Google antes de chamar o proxy e falha com `DefaultCredentialsError` sem `gcloud auth application-default login`. Ele reporta o erro como 500, que o `FallbackModel` não trata como retriável. Gemini, Mistral e Gemma não precisam de ADC. Para a reserva, preferir outro Gemini aprovado no Dev Portal.
- Dependências novas, só no extra: `ai-proxy-sdk`, `litellm` e `google-cloud-aiplatform`.
- Quem atualizar o ADK precisa conferir o `pyproject.toml` do SDK, que fixa a versão mínima.

## Verificação

- 2026-11-24: 145 testes do backend verdes (`uv run pytest -m "not e2e"`) com ADK 2.15.0, FastAPI 0.165.0 e SDK `ee059ed`; `ruff` limpo.
- Chamada real com chave falsa: Gemini e Mistral chegam ao Apigee e recebem 401 (URL `.../v1/projects/prj-avn-ai-dev-01/locations/global/publishers/google/models/gemini-3.5-flash:generateContent`). Claude para antes, no `DefaultCredentialsError`.
- Pendente: chamada com a chave real do Dev Portal (`-m e2e`, com pedido explícito).
