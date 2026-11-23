# Rubrica para pontuar ideias, arquitetura e pitch

Usada pela fase 2 (ideias), pelo subagent `banca-simulada` e no ensaio do pitch.

## Pesos

Fonte da verdade: os critérios oficiais anunciados na abertura, copiados em `docs/hackathon/00-briefing.md`. Se o briefing tem critérios oficiais, use os pesos dele e ignore a tabela abaixo.

Pesos provisórios (até sair o oficial), calibrados com Itaú 50/30/20, ADK 50/30/20, Nubank e Capgemini (impacto, inovação, viabilidade) e o briefing do organizador ("IA core" e "sair da caixa"):

| Critério | Peso | Nota 5 | Nota 1 |
|---|---|---|---|
| Técnica, dados e IA core | 30% | Tirar a IA mata o produto; ML tradicional e/ou generativa com papel claro; código calcula, LLM explica; guardrails, testes, segurança e LGPD visíveis | IA é enfeite (chat sobre FAQ); números vindos do LLM; nada testado |
| Negócio e estratégia | 25% | Dor quantificada com dado; persona com números; métrica principal definida; ligação explícita com a estratégia 2030 | Dor genérica; sem métrica; "seria legal ter" |
| Inovação ("fora da caixa") | 20% | Ângulo que a concorrência não tem (proatividade, momento certo, multimodal, novo público); não é cópia de produto existente | Já existe pronto no mercado (ex.: nota da carteira) |
| Experiência e design | 15% | Uma jornada clara, linguagem do cliente, confirmação humana nas ações, saída para humano, UI do kit com a marca | Muro de texto; sem confirmação; telas soltas |
| Viabilidade em 1,5 dia | 10% | Demo ponta a ponta de um fluxo cabe até 17h30 do dia 1; dado sintético viável; sem dependência externa bloqueante | Depende de integração real, dado real de cliente ou API que o time não controla |

Critério do jurado Google (avaliado à parte, peso oficial desconhecido): uso visível e correto da stack Google (ADK, Gemini/Vertex via proxy, BigQuery/BigQuery ML, Cloud Run, A2UI/GenUI). Pontue de 1 a 5 em linha separada.

## Filtros eliminatórios (antes de pontuar)

Uma ideia que falha em qualquer filtro sai da lista ou é reformulada:

1. Usa dado real de cliente.
2. A IA não é core: o produto funciona igual sem ela.
3. A demo não cabe em um fluxo de até 4 minutos.
4. Depende de algo que o time não controla até amanhã 11h (integração real, aprovação, dado que não existe).

## Cálculo

`nota_final = Σ (nota_critério × peso)`, de 1,0 a 5,0, com uma casa decimal. Empate: vence a ideia com maior nota em "Técnica, dados e IA core" e depois em "Negócio".

## Formato da avaliação

Uma tabela por item avaliado:

| Critério | Nota (1-5) | Justificativa em uma frase, com evidência do texto avaliado |
|---|---|---|

Depois da tabela: nota final, nota do critério Google, os 3 maiores riscos (cada um com a correção mais barata) e as 5 perguntas mais prováveis da banca.
