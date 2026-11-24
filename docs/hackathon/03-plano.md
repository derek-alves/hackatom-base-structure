# Plano de execução

Feito às 17h do D1, depois da ideia fechada. Uma coluna por pessoa.

| Pessoa | Papel do time | Foco no plano |
|---|---|---|
| Derek Alves | Mobile/Backend | Fatia das cenas 1 e 2, backend e mobile: esqueleto do módulo `family`, motor (permissões, transferência, pendência, consentimento), handler de aprovação, `userId` por membro, seletor "Ver como", chips; zip |
| Leonardo | Mobile/Backend + Produto | Fatia da voz e da cena 3, backend e mobile: voz no app, estimativa de estate tax, mapa de sucessão, caso do especialista, thread e balão do Rafael, APK; condutor da demo. Não está na lista do Time 3 no deck da abertura |
| Vinicius Yamaguti | IA | Agente: provider do AI Proxy, instrução e few-shots, card "Por trás", `check_output`, bateria de avaliação, gravação da demo |
| Jenny Nascimento | Produto | Pitch: roteiro nos 5 slides, números e premissas do impacto; narradora da demo |
| Thyago Rebelato | Produto | Organização: formulários, Slack, perguntas à organização, mentorias, divergências D1-D7 com Produto; faz o Rafael na demo |
| Karine Narumi | Design + Produto | Jornada no Figma, os 5 slides, marca Avenue; roteiro visual da demo |

Derek e Leonardo fazem backend e mobile; a divisão é por fatia vertical, para um não esperar o outro. Os dois mexem em `backend/app/modules/family/`: Derek cria o esqueleto e os modelos até 18h, e cada um fica com os seus arquivos de serviço e tools (`service.py` × `succession.py`; `tools.py` com seções separadas) para evitar conflito de merge. Papéis na apresentação (narradora, condutor, Rafael): proposta, a confirmar com o time.

## Checkpoint das 17h: respostas para o formulário

**1. Qual problema a solução resolve e/ou qual oportunidade ela captura?**

> 70% dos herdeiros trocam de instituição financeira logo após a herança (JP Morgan). Na Avenue, cerca de 15 mil clientes acima de US$ 50 mil, com cerca de um terço do AUC, não usam o banking, e a família está fora da tela: o dinheiro está espalhado, ninguém sabe o que acontece com os dólares se o titular faltar, e os pais idosos não conseguem usar o app. O Agente Familiar Avenue faz da família a unidade de cuidado. No Espaço Família, cada membro conversa com um agente de IA por voz ou texto, o owner aprova tudo que mexe em dinheiro, e um especialista humano entra na mesma conversa quando o assunto é sucessão. A oportunidade é reter o patrimônio na troca de geração, ativar o banking e crescer por convite: 23% da base já chega por indicação da família.

**2. Qual é a arquitetura básica da solução?**

> App Flutter (widgets A2UI) → FastAPI → workflow do Google ADK 2.x. Um nó de código prepara a entrada, um agente Gemini (via AI Proxy) usa tools, e outro nó de código valida a resposta (guardrail de números e da regra de não recomendação) e gera os widgets. As tools chamam um motor determinístico em Python sobre SQLite com dados fictícios: permissões por membro, limites, transferências dentro da família, estimativa educativa de estate tax e mapa de sucessão. Ação com efeito é confirmada pelo owner num card e executada por código, sem LLM, com registro de consentimento. Voz pelo reconhecimento de fala do aparelho. Modelos pelo AI Proxy da Avenue (Proxy SDK). Roda local com Podman.

## Blocos

| Bloco | Derek (cenas 1 e 2, backend + mobile) | Leonardo (voz e cena 3, backend + mobile) | Vinicius (IA) | Jenny (produto) | Thyago (produto) | Karine (design) |
|---|---|---|---|---|---|---|
| D1 17h-18h | `scripts/new_module.sh family`; `models.py`, `seed.py`, `policies.py` (limites, lista bloqueada); `AppModule.action_handlers` em `core/modules.py` e `registry.py`; `userId` por membro em `mobile/lib/core/network/api_models.dart` (hoje fixo em `'mobile-user'`) | `fvm flutter pub add speech_to_text flutter_tts`; permissões de microfone (Android e iOS); botão de voz + leitura da resposta (não depende do backend) | Chave no Dev Portal + Request do modelo de reserva; provider `avenue` com o Proxy SDK como extra opcional (`docs/infra-ia/README.md`); primeira chamada real pelo proxy | Premissas do impacto (`01-ideia.md`); conferir a fonte dos 70% (JP Morgan) | Enviar o formulário do checkpoint (respostas acima); eleger líder e postar "GRUPO 3: <líder>" no Slack; perguntas 3 e 5 do briefing à organização | Jornada das 3 cenas no Figma (T10, T11, T9, T13) |
| D1 18h-21h (opcional) | `service.py`: permissões, transferência, pendência, consentimento; handler de `approval_decided` (texto injetado sem timestamp); tools das cenas 1 e 2 com `tool_context.user_id` e campo `explain`; `family` fora do `/mcp`; seletor "Ver como", chips com frase única por membro, rótulo "dados fictícios"; testes do motor e do handler | `succession.py`: tabela §2001(c) em `policies.py`, `estimate_estate_tax` (teste 179.800), `get_succession_map`, lista fechada de próximos passos; tools da cena 3 com `explain`; testes | Instrução e few-shots das cenas 1 e 2; "Por trás" montado em código no `render_a2ui`; `check_output` v1 (números, `set_model_response` fora) | Rascunho de `04-pitch.md` nos 5 slides oficiais | `05-demo.md` com as frases exatas, junto com Leonardo e Vinicius; agendar mentorias do D2 (Bookings); lista D1-D7 para Produto | Slides 1 e 2; Figma da marca para o `/boot-theme` (P1, quem roda: Leonardo) |
| **D1 21h checkpoint interno** | **Cenas 1 e 2 ponta a ponta no emulador, mesmo feias, e já gravadas com `DEMO_MODE=record` (Vinicius; o `RecordingLlm` acumula no mesmo arquivo); cópia em `backend/demo/`** | | | | | |
| D2 9h15-11h | `get_family_timeline` (pedidos, decisões, mensagens); `POST /api/family/demo/reset`; apoio ao Leonardo na cena 3; `pytest` e `ruff` verdes. PIN só se sobrar tempo ("biometria em produção") | Handler de `checklist_submitted` (cria o caso); `save_specialist_briefing`; thread da família (REST); balão do Rafael com fala fixa vindo da thread; APK de release | Prioridade 1: cena 3 no agente; `check_output` completo (regra 3, briefing, falsos positivos); bateria de 12 perguntas com fakes; gravar a cena 3 assim que rodar | Números finais do pitch (custo por jornada, testes); ensaio 1 | 9h15: pergunta 3 do briefing (replay vale como live?); mentorias das 9h30 às 11h; respostas às perguntas da banca em `04-pitch.md` | Slides 3, 4 e 5; polimento visual |
| **D2 11h freeze** | **Regravar o roteiro inteiro com `DEMO_MODE=record` só se o proxy estiver estável (Vinicius); senão vale a gravação de partes** | | | | | |
| D2 11h-12h | `git archive`, checklist do zip, README de entrega | APK final no zip ou no formulário | Copiar a gravação para `backend/demo/`; testar replay sem chave e sem SDK | Revisar números do deck | Formulário de entrega (código + deck) até 12h | Deck em PDF |
| D2 12h-13h | Plano B testado (Podman + replay) | Aparelho carregado, espelhamento testado | Vídeo de reserva (2-3 min) | Ensaio 2 cronometrado (10 min), narradora | Ensaio 2, no papel do Rafael | Ensaio 2; slides no ar |

## Dependências

| Quem espera | O quê | De quem | Até quando |
|---|---|---|---|
| Vinicius | Chave do app no Dev Portal (`AI_PROXY_API_KEY`) e acesso ao pacote do Hackathon no My Access, se o SSO bloquear | Cada pessoa no Dev Portal | D1 18h |
| Vinicius | Modelo de reserva aprovado no Dev Portal | Time de AI & Data Science | D1 21h |
| Leonardo | Esqueleto do `family`, `models.py` e IDs da seed (`marcos`, `lucia`, `pedro`, `rafael`) | Derek | D1 18h |
| Vinicius | Tools das cenas 1 e 2 com `explain` e handler com testes | Derek | D1 20h |
| Vinicius | Tools da cena 3 com `explain` | Leonardo | D1 21h |
| Leonardo | `get_family_timeline` para o briefing | Derek | D2 10h |
| Jenny | Números finais (custo por jornada, testes) | Vinicius e Derek | D2 10h30 |
| Karine | Jornada e telas aprovadas para o mobile seguir | Karine → Leonardo | D1 19h |
| Todos | Freeze e gravação | Vinicius | D2 11h |

## Slots com especialistas (20 min)

As janelas do D1 fecharam às 17h. Restam as do D2, das 9h30 às 11h, no Foyer da Lua Grande (agendar em https://avne.us/Hackaton).

| Horário | Especialista / área | Pergunta |
|---|---|---|
| D2 9h30 | Produto (Felipe Cozer) | Regra do cartão de dependente (D2 da ideia); cofrinhos e P2P já existem (D6)? Números do Databricks podem ir ao slide, arredondados? |
| D2 10h | AI & Data Science (Lucas Braz) | O AI Proxy aceita áudio para o Gemini? Funciona na máquina da Validação Técnica? |
| D2 10h30 | Engenharia de SW (Martin Pfeifer) | O que a máquina da Validação Técnica tem (Podman, Flutter, emulador)? Aceitam APK? |
| Mesa, quando passar | Mentor Google | O card "Por trás" e o especialista na mesma conversa deixam a IA indispensável para a banca do Google? |

## Riscos e plano B

| Risco | Sinal | Plano B |
|---|---|---|
| Proxy de IA instável ou cota estourada | 429 (cota de 200 mil tokens/min ou `RESOURCE_EXHAUSTED`)/503 | `LLM_FALLBACK_MODELS` com modelo aprovado; `DEMO_MODE=replay` |
| Rede do IPT/USP sem acesso ao proxy | `AvenueConnectionError` | VPN ligada; `ai_proxy.diagnose()`; `DEMO_MODE=replay` |
| Validação Técnica não instala o SDK privado | `uv sync` falha no clone de `avenuesec/ai-proxy-sdk` | SDK como extra opcional; zip roda em replay sem o SDK; README com `uv sync --extra avenue` |
| Microfone do emulador não funciona | Reconhecimento não abre ou volta vazio | Chip com a frase exata da Dona Lúcia; aparelho físico |
| Replay não reconhece a frase transcrita ou mistura membros | Turno diferente do gravado ("200" × "duzentos"); o `turn_key` ignora o `userId`, então a mesma frase de dois membros colide | Chips com frase única por membro; na demo em replay, usar o chip; voz real só ao vivo com o proxy |
| Proxy cai antes da gravação | Nada gravado às 11h | Gravar cenas 1-2 às 21h do D1 e a cena 3 assim que rodar no D2 |
| Guardrail libera tudo ou bloqueia a demo | `set_model_response` conta como tool; "200" da fala ou "179,8 mil" barrados | `check_output` com as exceções de `02-arquitetura.md` (seção 10) e testes de falso positivo |
| IDs ou saldos diferentes entre gravação e demo | Card com APR-2 ou saldo errado | `POST /api/family/demo/reset` antes de gravar e de apresentar |
| Agente fala de ativo ou alocação na cena 3 (regra 3) | Teste do filtro falha ou ensaio mostra termo bloqueado | Lista fechada de próximos passos; filtro de saída; fala do Rafael roteirizada |
| Tool com `ToolContext` quebra o `/mcp` no startup | Erro ao subir o backend | `family` fora do `/mcp` e filtro em `build_mcp_server` (decisão D9) |
| Validação Técnica sem emulador | Pergunta 1 do briefing | Backend com Podman + APK + vídeo de reserva |
| Escopo não cabe | 21h sem cenas 1 e 2 | Cortar P1 inteiro; cena 3 só com o mapa e o handoff |
