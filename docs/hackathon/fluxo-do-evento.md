# Fluxo do evento com a skill `/hackathon`

A skill `/hackathon` conduz o time do tema revelado até a entrega. Cada fase preenche um arquivo em `docs/hackathon/`, e as skills de construção entram na hora de codar. A `banca-simulada` avalia ideias, arquitetura e pitch pela rubrica, sem ver o raciocínio de quem escreveu.

## Antes das 8h30

1. Quem usa Claude Code: `git pull` na `main` e abrir uma sessão nova do Claude Code. Só numa sessão nova o subagent `banca-simulada` aparece.
2. Quem usa Antigravity ou outra ferramenta: ler `.claude/skills/hackathon/SKILL.md` direto. Para a banca, pedir ao agente: "leia `.claude/agents/banca-simulada.md` e siga o corpo como suas instruções".

## Dia 1 (Google Faria Lima)

| Hora | Comando | Resultado |
|---|---|---|
| 8h30 | `/hackathon prontidão` | Testes passando, backend no ar, `backend/.env` com o proxy (`LLM_PROVIDER`, `LLM_BASE_URL`, `LLM_API_KEY`) e `LLM_FALLBACK_MODELS` |
| 9h | `/hackathon briefing` + colar o texto do tema e dos critérios | `00-briefing.md`, com os pesos oficiais no lugar dos provisórios |
| 9h30-12h30 (sessão do Google) | `/hackathon ideias` | 8 ou mais ideias, filtros, notas e avaliação da `banca-simulada` → `01-ideia.md` |
| a qualquer hora | `/hackathon validar` + a ideia do time | Ideia reescrita no formato, lacunas, filtros, nota, banca, 2 variações e veredito (seguir, ajustar ou trocar) → `01-ideia.md` |
| 12h30 | `/hackathon arquitetura` | Contrato do agente, C4, decisões e mapa no repo → `02-arquitetura.md` e `06-dados.md`; a banca revisa |
| 12h30 | `/hackathon plano` | Tarefas por pessoa e horário → `03-plano.md` |
| 13h30-17h30 | `scripts/new_module.sh`, `/new-flow`, `/add-genui-widget`, `/add-mcp`, `/boot-theme`, `/add-ds-component` | Construção |
| 17h30 | Checkpoint | Jornada ponta a ponta funcionando, mesmo feia |
| até 21h (opcional) | Construção | Confirmação por código, testes, bateria de avaliação, rascunho do pitch |

## Dia 2 (USP/IPT)

| Hora | Comando | Resultado |
|---|---|---|
| até 11h | Polimento e testes | |
| 11h | Freeze de funcionalidade, depois `/hackathon entrega` | `04-pitch.md`, `05-demo.md` e `07-entrega.md`; gravação com `DEMO_MODE=record`, vídeo de reserva, zip com `git archive` |
| 12h | `banca-simulada` sobre o pitch | As 5 perguntas prováveis da banca, com resposta pronta |
| 13h | Apresentação (10 min) | Demo em `DEMO_MODE=replay`, vídeo de reserva aberto |

## Regras práticas

- Rodar `/hackathon` sem indicar a fase faz a skill descobrir onde o time parou, pelos arquivos já preenchidos em `docs/hackathon/`.
- Fazer commit dos arquivos de `docs/hackathon/` a cada fase, para o time todo ver o mesmo estado.
- Se a abertura mudar horários ou regras, vale o que estiver no `00-briefing.md`, não o que está fixo na skill.
- Na rede do evento, se o backend estiver aberto para outras máquinas, definir `MCP_SERVER_TOKEN`: as tools de escrita também saem em `/mcp`.

## Configuração do `backend/.env` no evento

| Variável | Valor |
|---|---|
| `LLM_PROVIDER` | `apigee` ou `openai`, conforme o formato do proxy |
| `LLM_BASE_URL` | URL do proxy |
| `LLM_API_KEY` | Chave do proxy |
| `LLM_MODEL` | Modelo principal |
| `LLM_FALLBACK_MODELS` | Modelos de reserva, ex.: `'["gemini-3.1-flash-lite"]'` |
| `MCP_SERVERS` | Servidores MCP que o agente vai usar, se houver (ver `/add-mcp`) |
| `MCP_SERVER_TOKEN` | Token do `/mcp`, se o backend ficar aberto na rede |
| `MCP_SERVER_ALLOWED_HOSTS` | IP da máquina para colegas conectarem no `/mcp`, ex.: `'["192.168.0.10:*"]'` |
| `DEMO_MODE` | `record` no ensaio, `replay` na apresentação |
