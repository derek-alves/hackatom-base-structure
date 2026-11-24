# Infra de IA da Avenue: Dev Portal, AI Proxy e Proxy SDK

Contexto para o hackathon: como o backend chama modelos pela plataforma de IA da empresa. Fontes nesta pasta: `content.md` (mensagem do time da Plataforma de IA, com os links) e `Plataforma de IA da Avenue (1).html` (slides da apresentação de 24/11). Detalhes do SDK: README de `python/` no repositório `avenuesec/ai-proxy-sdk` (privado, lido em 24/11).

Nunca escreva chave neste repositório. A chave fica só em `backend/.env` (no `.gitignore`) ou num secret do ambiente.

## As três peças

| Peça | O que faz | Onde |
|---|---|---|
| Dev Portal | Cada app recebe a sua chave; catálogo de modelos; aprovação automática ou manual por modelo | https://devportal-ai.avenuesec.io/ |
| AI Proxy (Apigee) | Todo tráfego de IA passa por ele; cota de tokens por app e modelo; uso registrado | Host público (local, exige rede corporativa ou VPN) e host interno (GCP); o SDK escolhe |
| Proxy SDK | Python e Go; Gemini, Claude, Gemma e Mistral pelo mesmo pacote; streaming, tools, imagem, PDF, áudio, saída estruturada, batch, ADK, métricas OpenTelemetry | https://github.com/avenuesec/ai-proxy-sdk |

Exemplos de uso e de deploy: https://github.com/avenuesec/ai-proxy-sdk-deploy-examples

## Pegar a chave (uma vez por pessoa ou por app)

1. Entrar em https://devportal-ai.avenuesec.io/ → Sign In → Login with SAML (SSO da Avenue).
2. Erro `AADSTS50105` ("...is blocked because they are not a direct member of a group with access"): pedir o pacote de permissões do Hackathon no My Access (link em `content.md`).
3. Menu na seta ao lado do e-mail → Apps → `+ new app`.
4. Dar nome ao app, clicar em Request nos modelos que vai usar e em Save. O `gemini-3.5-flash` sai na hora; os demais passam por aprovação do time de AI & Data Science (pedir cedo o modelo de reserva).
5. Copiar a chave do app: ela vira `AI_PROXY_API_KEY`.

## Instalar o SDK no backend

```bash
# uma vez por máquina: o uv clona o repositório privado pelo git, com o token do gh
gh auth login && gh auth setup-git

# no backend: o SDK já está no pyproject.toml como extra opcional `avenue`
cd backend
uv sync --extra avenue
uv lock --upgrade-package ai-proxy-sdk && uv sync --extra avenue   # para atualizar depois
```

Requer Python 3.12+ (o backend usa 3.14). O pacote instala como `ai-proxy-sdk` e importa como `ai_proxy`. Sem registry: basta acesso à org `avenuesec` no GitHub. O `uv.lock` grava o commit do SDK.

Um `uv sync` sem `--extra avenue` remove o SDK do `.venv` (o `uv run` não remove). Sem o extra, `uv sync --locked` não precisa de git nem de acesso à `avenuesec`. Isso vale para o Containerfile e para quem só roda o zip.

O SDK fixa a versão mínima do ADK: o commit `d1c7ef0` (24/11) passou a exigir `google-adk>=2.15`. Antes disso, ele chamava `_merge_tracking_headers`, que saiu do ADK na 2.13.

## Configuração (variáveis de ambiente, com fallback em `./.env`)

| Variável | Default | Uso |
|---|---|---|
| `AI_PROXY_API_KEY` | — | Obrigatória. Chave do app no Dev Portal (vai no header `x-apikey`) |
| `AI_PROXY_TEAM` | `""` | Time consumidor (header `x-avenue-team`), para atribuir custo |
| `AI_PROXY_DEBUG` | `true` | Log das requisições no stderr, com headers sensíveis mascarados |
| `AI_PROXY_SSL_VERIFY` | `true` | `true`, `false` ou caminho de um bundle de CA (rede com inspeção TLS) |
| `AGENT_ENVIRONMENT` | — | `dev` ou `prd`; obrigatório em deploy |

Não há URL para configurar: local usa o host público (exige rede corporativa ou VPN); no GCP (Agent Runtime, Cloud Run, GKE) usa o host interno.

## Uso

```python
from ai_proxy import AvenueLLM, Model

# Fora do ADK: cliente google-genai (Gemini) ou formato OpenAI (Claude, Mistral, Gemma)
g = AvenueLLM(Model.GEMINI_3_5_FLASH, is_adk=False)
print(g.generate_content(prompt="Responda só: pong").text)

# No ADK: modelo para o LlmAgent; trocar de modelo é trocar o enum
from google.adk.agents import LlmAgent
agent = LlmAgent(name="assistente", model=AvenueLLM(Model.GEMINI_3_5_FLASH, is_adk=True), tools=tools)
```

- Modelo é sempre um `ai_proxy.Model` (string dá `ModelError`): `GEMINI_3_5_FLASH` (default), `CLAUDE_OPUS_4_7`, `MISTRAL_7B`, `GEMMA4_31B`, entre outros (lista no autocomplete).
- No ADK com Gemini, o SDK devolve `AvenueGemini`, subclasse do `ApigeeLlm` do ADK, com os headers do proxy (`x-apikey`, `x-llm-action`) e rota `/v1`. Com Claude, Mistral e Gemma, devolve `AvenueMultiLLM`, subclasse do `LiteLlm`.
- Imagem, PDF e áudio: `types.Part.from_bytes(data=..., mime_type=...)`, sujeito ao limite de payload do proxy.
- Diagnóstico de rede ou TLS: `uv run python -c "import pprint, ai_proxy; pprint.pprint(ai_proxy.diagnose())"`.

## Erros e cota

| Situação | Resposta | O que fazer |
|---|---|---|
| Modelo não liberado para o app | 401 `InvalidApiKeyForGivenResource` ou 403 `LLM_MODEL_NOT_ALLOWED` | Request do modelo no Dev Portal |
| Chave inválida, revogada ou de outro ambiente | outro 401 | Conferir `AI_PROXY_API_KEY` |
| Cota do proxy | 429 "Limite de tokens LLM excedido" | Esperar o minuto virar ou pedir aumento |
| Vertex sem capacidade | 429 `RESOURCE_EXHAUSTED` | Modelo de reserva em `LLM_FALLBACK_MODELS`. O `retry_options` não repete esse erro (ver "Encaixe neste starter") |
| Rede (VPN, Cloudflare Access, TLS) | `AvenueConnectionError`, `AvenueSSLError` | `ai_proxy.diagnose()`; conectar a VPN |
| Claude pelo ADK, fora do GCP | `DefaultCredentialsError` ("Your default credentials were not found"), como 500 do LiteLLM | `gcloud auth application-default login`. O LiteLLM pede um token do Google antes de chamar o proxy; Gemini, Mistral e Gemma não precisam |

Cota em dev: 200.000 tokens por minuto, por app e por modelo (entrada + saída; no Gemini a saída inclui raciocínio).

## Encaixe neste starter

Implementado em 24/11 (ADR `docs/decisions/0006-avenue-ai-proxy.md`). O `apigee` do starter usa o `ApigeeLlm` puro, que manda a chave como chave do Gemini, mas o AI Proxy exige `x-apikey` e `x-llm-action`. Por isso existe o provider `avenue`, que usa o SDK.

Para ligar, em `backend/.env`:

```bash
LLM_PROVIDER=avenue
AI_PROXY_API_KEY=<chave do app no Dev Portal>
LLM_MODEL=gemini-4-neon                         # ou o nome do enum: GEMINI_4_NEON
LLM_FALLBACK_MODELS='["gemini-3.5-flash"]'      # reserva para 429/5xx; também aprovada no app
AI_PROXY_DEBUG=false                            # opcional: sem log de cada requisição
```

Depois: `uv sync --extra avenue` e `uv run fastapi dev app/main.py`, com VPN. O `GET /api/health` mostra `"llmProvider": "avenue"`.

Como funciona:

- `app/core/llm.py` importa `app/core/avenue_llm.py` só quando `LLM_PROVIDER=avenue`. Sem o SDK, o backend falha ao subir e diz para rodar `uv sync --extra avenue`.
- `avenue_llm.py` monta `AvenueLLM(Model, is_adk=True)`. O `LLM_MODEL` aceita o id do modelo (`gemini-3.5-flash`) ou o nome do enum (`GEMINI_3_5_FLASH`). Nome fora do enum falha ao subir, com a lista dos modelos válidos.
- Chave: `LLM_API_KEY` ou `AI_PROXY_API_KEY`. O `GEMINI_API_KEY` do AI Studio nunca vai para o proxy. `AI_PROXY_TEAM`, `AI_PROXY_DEBUG` e `AI_PROXY_SSL_VERIFY` o próprio SDK lê do ambiente ou do `.env`.
- O `ApigeeLlm` do ADK exige `GOOGLE_CLOUD_PROJECT` e `GOOGLE_CLOUD_LOCATION` para os modelos `apigee/vertex_ai/`. O `avenue_llm.py` usa os valores do próprio SDK (`prj-avn-ai-dev-01`, `global`) só durante a montagem do modelo e depois devolve o ambiente como estava.
- Retry: no Gemini, o SDK transforma 4xx/5xx do proxy em `ApigeeError` antes do `google-genai` ver a resposta. Por isso o `retry_options` (`LLM_RETRY_ATTEMPTS`) só repete timeout e erro de conexão. Para 429 e 5xx, o que vale é o `LLM_FALLBACK_MODELS`: o `FallbackModel` lê o `status_code` do `ApigeeError`. Claude, Mistral e Gemma passam pelo `LiteLlm`, com o retry do próprio SDK (`num_retries=2`).
- Testes sem rede continuam com `FakeLlm`/`StudioLlm`. Os testes do provider em `tests/core/test_llm.py` montam o modelo e o cliente `google-genai` sem rede, e são pulados se o SDK não estiver instalado.
- Verificado em 24/11, com chave falsa: Gemini e Mistral chegam ao Apigee e recebem 401. Claude para antes, por falta de ADC.

## Riscos para o hackathon

| Risco | Por quê | Plano |
|---|---|---|
| Validação Técnica não instala o SDK | Pacote privado: `uv sync` precisa de `gh auth` com acesso à `avenuesec`; o `uv.lock` grava o commit | SDK como dependência opcional (`uv add --optional avenue ...`), README com `uv sync --extra avenue`; zip roda em `DEMO_MODE=replay` sem o SDK |
| Container não instala o SDK | Imagem `-slim` sem `git` e sem token | Build com secret (`podman build --secret id=netrc,src=<arquivo .netrc>`), nunca `ARG`/`ENV`; ou imagem do zip só com replay |
| Rede do evento sem acesso ao proxy | Host público exige rede corporativa ou VPN (D2 no IPT/USP) | VPN ligada; testar às 9h15 do D2; `DEMO_MODE=replay` como plano B |
| Cota estourada no ensaio | 200 mil tokens/min por app e modelo | Um app por pessoa no Dev Portal; modelo de reserva aprovado |
| Modelo de reserva não aprovado a tempo | Só o Flash sai na hora | Pedir o segundo modelo no Dev Portal já no D1 |

## Deploy (opcional, sem peso na nota)

| O que é | Onde roda | Como chega ao proxy | O que pedir |
|---|---|---|---|
| Serviço ou API | GKE da `vpc-d` | Rede do cluster | Nada |
| Serviço ou API | Cloud Run com Direct VPC egress na `vpc-d-shared-workloads` | Host interno | Nada |
| Agente | Agent Runtime (us-east4), via Agent Gateway do `prj-avn-ai-dev-01` | Host interno | 2 pedidos de IAM por projeto |

Todo deploy leva `AI_PROXY_API_KEY` (de um secret) e `AGENT_ENVIRONMENT`. Guias no repositório do SDK: `docs/deploy.md` e `docs/agent-runtime.md`.
