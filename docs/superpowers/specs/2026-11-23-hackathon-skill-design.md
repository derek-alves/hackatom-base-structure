# Skill `/hackathon` e subagent `banca-simulada`: design

Data: 2026-11-23. Aprovado no chat (opção C).

## Intenção

Hackathon de IA em 24 e 25/11/2026, com estrutura Google (escritórios Faria Lima e USP/IPT). O tema sai às 9h do dia 1 e nasce da estratégia 2030 da empresa. O time (6 pessoas: engenharia, produto/design, dados/IA) precisa sair da abertura com uma ideia forte e, em poucas horas, ter a ideia encaixada neste repo, com a entrega e o pitch planejados.

A skill concentra o que a pesquisa sobre hackathons Google e de empresas na estrutura Google mostrou sobre projetos campeões: critérios, padrões de ideia, arquitetura e entrega.

## Metas

- Um comando (`/hackathon`) que guia o time por fases: briefing do tema, ideias pontuadas, arquitetura no repo, plano por papel e horário, entrega e pitch.
- Cada fase deixa um artefato em `docs/hackathon/`, para o time e a banca.
- Um subagent `banca-simulada` que pontua ideias, arquitetura e pitch pela rubrica, sem ver o raciocínio de quem escreveu.
- Referências com a pesquisa (vencedores, critérios, fontes), carregadas só na fase em que servem.

## Fora de escopo

- Código novo no backend/mobile (moldes de motor determinístico, ML, dados sintéticos e gráfico ficam para depois).
- Espelhar a skill para Antigravity/Gemini CLI (`AGENTS.md`).

## Anti-metas

- Skill que gera ideias genéricas de chatbot sem amarrar a critério, dado e demo.
- Skill longa demais para ler sob pressão no dia.

## Abordagens consideradas

- A. Uma skill com fases e `references/`: um só ponto de entrada; referências grandes ficam fora do `SKILL.md`.
- B. Três skills separadas: cada uma enxuta, mas mais nomes para lembrar e referências espalhadas.
- C. A + subagent `banca-simulada` (escolhida): avaliação independente pela rubrica, como a avaliação por LLM do hackathon do Itaú; atende o pedido de usar subagents.

## Decisões

- Local: `.claude/skills/hackathon/` (versionado para o time) e `.claude/agents/banca-simulada.md`.
- Idioma: pt-BR, como as outras skills do repo.
- Rubrica padrão provisória até os critérios oficiais saírem na abertura; a skill manda trocar os pesos pelos oficiais.
- A skill reaproveita as skills existentes (`/new-flow`, `/add-genui-widget`, `/boot-theme`, `/add-ds-component`) na fase de construção.

## Deixado para quem constrói

- Texto exato das referências, formato das tabelas e dos modelos de artefato.
