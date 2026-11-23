---
name: hackathon
description: Use quando o tema do hackathon for revelado ou o time precisar escolher a ideia, encaixá-la neste repo, dividir o trabalho por papel e horário, preparar o pitch de 10 minutos, gravar a demo ou montar o zip de entrega para os jurados.
argument-hint: "[fase: briefing | ideias | arquitetura | plano | entrega] [texto do tema ou contexto]"
---

# /hackathon

Guia o time do tema revelado até a entrega, com o que a pesquisa sobre hackathons Google e de empresas na estrutura Google mostrou sobre projetos campeões. Cada fase deixa um artefato em `docs/hackathon/`.

**Princípio:** banca premia uma jornada real, provada com dado, com IA no centro, código que calcula, humano que confirma e uma demo que a banca entende em um fluxo. Arquitetura, engenharia e dados pesam 30-50% da nota nos eventos pesquisados.

## Fatos do evento (briefing do organizador)

- 24/11 (Google Faria Lima): 8h30 credenciamento; 9h abertura com tema, critérios e entregáveis; até 12h30 sessão com o Google para ideação e formulação do problema; depois construção até 18h (opcional até 21h).
- 25/11 (USP/IPT): 8h30 café; construção pela manhã; 13h apresentações de 10 min por time; 15h deliberação; 16h resultado.
- Requisito nº 1: IA como core, generativa ou tradicional (classificador, rede neural, etc.). "Sair da caixa" é critério. Jurados do Google avaliam um critério.
- Tema nasce da estratégia 2030 da empresa; há materiais de dores de clientes do time de produto como ponto de partida.
- Modelos via proxy de IA na infra Google (Gemini, Anthropic, open-source) com chave de API, em `backend/.env`: `LLM_PROVIDER=apigee` ou `openai` conforme o formato do proxy (`gemini` é o AI Studio direto), mais `LLM_BASE_URL` e `LLM_API_KEY`.
- Se a abertura mudar horários ou regras, vale o `00-briefing.md`, não esta seção.
- Proibido dado real de cliente. Entrega por formulário; zip para rodar local é suficiente.
- Apoio: slots de 20 min com especialistas das áreas, mentores Google e SoftwareOne circulando. Times de 6: engenharia, produto/design, dados ou IA.

## Fases

Se o usuário indicar a fase, comece por ela. Senão, descubra pelo que já existe em `docs/hackathon/` e continue da primeira fase sem artefato.

| Fase | Quando | Artefato |
|---|---|---|
| 0. Prontidão | antes das 9h | checklist abaixo, sem arquivo |
| 1. Briefing | 9h-9h30 | `docs/hackathon/00-briefing.md` |
| 2. Ideias | sessão de ideação, até 12h30 | `docs/hackathon/01-ideia.md` |
| 3. Arquitetura | 12h30-13h30 | `docs/hackathon/02-arquitetura.md`, `06-dados.md` |
| 4. Plano | junto com a fase 3 | `docs/hackathon/03-plano.md` |
| 5. Entrega | dia 2, até 12h30 | `04-pitch.md`, `05-demo.md`, `07-entrega.md`, gravação, vídeo, zip |

Os modelos já existem em `docs/hackathon/` (padrão zera.ai): preencha no lugar, sem apagar seções. Guia de pitch, gravação e zip: `references/entrega.md`.

### 0. Prontidão

1. `cd backend && uv run pytest -m "not e2e"` passa.
2. Backend sobe e o app conversa com ele (`fvm flutter run --dart-define=API_BASE_URL=...`).
3. Proxy de IA testado com uma pergunta real assim que a chave sair. Sem chave ainda: `DEMO_MODE=replay` mantém o app vivo.
4. `LLM_FALLBACK_MODELS` com ao menos um modelo de reserva.

### 1. Briefing

Preencha `00-briefing.md` com o texto literal do tema, critérios, pesos e entregáveis anunciados. Os critérios oficiais substituem os pesos provisórios de `references/rubrica.md`. Liste perguntas para os mentores.

### 2. Ideias

1. **Diverja antes de escolher:** gere pelo menos 8 ideias, cada uma no formato:
   `[persona com números] + [momento/gatilho] + [decisão que o agente ajuda] + [ML tradicional faz X] + [LLM faz Y] + [ação que o cliente confirma]`.
   Fontes, uma ideia de cada no mínimo: frentes do organizador, dores de clientes do material de produto, o dataset do evento (se houver), e os padrões campeões de `references/vencedores.md` (seção 3).
2. **A dor sai do dado:**
   - Evento deu dataset: peça à pessoa de dados uma segmentação rápida (k-means ou regras) e a persona = cliente mais típico do segmento-alvo, com números.
   - Sem dataset: quantifique a dor com dado público citado (Anbima, B3, Banco Central, FGV, séries de mercado) e use dados fictícios só para a demo. Prefira ML que não dependa de rótulo inventado (segmentação, anomalia, modelo treinado em série pública); classificador em rótulo sintético exige baseline de regra (ver `references/arquitetura.md`, padrão 6).
3. **Filtre** pelos eliminatórios de `references/rubrica.md`. Marque como "commodity" o que já existe no mercado (ex.: nota/diagnóstico de carteira, chatbot de FAQ) e exija um ângulo novo ou descarte.
4. **Pontue** as restantes com a rubrica, em tabela, e fique com as 3 melhores.
5. **Banca independente:** despache o subagent `banca-simulada` com só o texto das 3 ideias e o caminho da rubrica (nunca seu raciocínio nem sua nota). Compare as notas; divergência maior que 1 ponto num critério vira discussão do time.
6. Escolha com o time e preencha `01-ideia.md` (quadro de produto enxuto), com as ideias avaliadas e o parecer da banca no fim.

Saída da fase: uma persona, um gatilho, uma jornada, uma métrica principal.

### 3. Arquitetura

Leia `references/arquitetura.md`. Em `02-arquitetura.md`:

1. Contrato do agente: pode, não pode, quando encaminha.
2. Padrões obrigatórios: motor determinístico (o LLM nunca calcula), guardrail de números, ação com confirmação executada por código, ML tradicional como tool com uma métrica de avaliação, dados fictícios rotulados.
3. Padrões opcionais, só se a ideia pedir: roteamento em camadas, proatividade, vários agentes com especialistas reais, multimodal, MCP (consumir servidores da empresa ou publicar nossas tools: `/add-mcp`), Cloud Run.
4. C4 nível 1-2 (modelo Mermaid na referência) e tabela de decisões.
5. Mapeie cada peça para arquivos do repo e para as skills de construção: `scripts/new_module.sh`, `/new-flow`, `/add-genui-widget`, `/add-ds-component`, `/boot-theme`, `/add-mcp`.
6. Rode a `banca-simulada` sobre `01-ideia.md` + `02-arquitetura.md` e corrija os riscos baratos.

### 4. Plano

`03-plano.md`, por pessoa e bloco. Ponto de partida (ajuste as colunas às pessoas do time; quem acumula papéis junta as colunas):

| Bloco | Backend | Mobile | Dados | IA | Produto | Design |
|---|---|---|---|---|---|---|
| D1 9h-12h30 (sessão Google) | ideação; fase 0 em paralelo se der | ideação | ideação; explorar dataset | ideação; testar proxy e reserva | conduz ideação, `00/01` | ideação; Figma da jornada |
| D1 12h30-13h30 | `02-arquitetura` | contratos dos widgets | contrato do modelo (features, rótulo, métrica) | contrato do agente, bateria de avaliação | `01-ideia` final | fluxo da jornada |
| D1 13h30-17h30 | motor + tools com stubs → reais | jornada no app com widgets | dados fictícios + modelo + métrica | instrução, tools ligadas, guardrail | métricas, roteiro do pitch | `/boot-theme`, slides |
| **D1 17h30** | **checkpoint: jornada ponta a ponta, mesmo feia** | | | | | |
| D1 até 21h (opcional) | confirmação por código, testes | polimento | BigQuery ML ou sensibilidade | bateria de avaliação, custo por jornada | `04-pitch` rascunho | slides |
| D2 até 11h | testes, logs de custo | polimento, APK | números do pitch | ajustes | ensaio 1 | polimento visual |
| **D2 11h** | **freeze de funcionalidade** | | | | | |
| D2 11h-12h30 | gravar demo, zip | APK final | revisar números | vídeo de reserva | ensaio 2 com timer | slides finais |

Não marque construção para quem está na sessão de ideação do Google; a sessão é o lugar de fechar o problema.

### 5. Entrega

Siga `references/entrega.md`: pitch de 10 minutos, roteiro da demo, gravação com `DEMO_MODE=record` e cópia para fora de `backend/data/`, vídeo de reserva, `git archive` e checklist do zip. Rode a `banca-simulada` sobre `04-pitch.md` e prepare resposta para as 5 perguntas que ela levantar.

## Erros comuns

| Erro | Correção |
|---|---|
| Escolher a primeira ideia boa | Gerar 8+, filtrar, pontuar, banca independente |
| Dor tirada da cabeça | Dor e persona saem do dado (segmento, tamanho, números) |
| LLM fazendo conta ou inventando taxa | Motor em Python com testes + guardrail de números |
| `approval_decided` executando via LLM | Nó de código executa; o agente só narra |
| "Multi-agente" que é cadeia de prompts | Um agente com tools; vários só com especialistas reais |
| Ideia que já existe no mercado | Marcar commodity e achar o ângulo novo |
| Demo com 3 jornadas | Uma jornada ponta a ponta, contraste antes × depois |
| Pitch sem métrica | Métrica principal com fórmula e premissa |
| Zip sem a gravação ou com `.env` | `git archive` + gravação fora de `data/` + checklist |

## Referências

- `references/vencedores.md`: critérios conhecidos, casos (Itaú zera.ai, Nubank, ADK, GKE, Gemini Live, Kaggle), padrões campeões, o que jurados penalizaram, contexto de mercado, fontes.
- `references/rubrica.md`: pesos provisórios, filtros eliminatórios, formato da avaliação.
- `references/arquitetura.md`: padrões mapeados no repo, C4 em Mermaid, tabela de decisões.
- `references/entrega.md`: modelos de `00` a `05`, pitch, demo, gravação, zip.
- Subagent `banca-simulada` (`.claude/agents/banca-simulada.md`). Se o tipo `banca-simulada` não estiver disponível (sessão aberta antes do arquivo existir, ou outra ferramenta), despache um agente genérico com: "Leia `.claude/agents/banca-simulada.md` e siga o corpo como suas instruções. Avalie: <caminhos ou texto>".
