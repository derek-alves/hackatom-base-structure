# Hackathons Google e de empresas na estrutura Google: critérios, vencedores e padrões

Pesquisa feita em 2026-11-23. Use para calibrar ideias, arquitetura e pitch. Números e pesos vêm das fontes no fim; onde a fonte é um espelho ou relato de terceiros, está marcado.

## Índice

1. Critérios de avaliação conhecidos
2. Casos por hackathon
3. Padrões dos campeões
4. O que os jurados penalizaram
5. Contexto de mercado (investimentos, pessoa física)
6. Fontes

## 1. Critérios de avaliação conhecidos

| Evento | Critérios e pesos | Observação |
|---|---|---|
| Batalha de Agentes (Itaú + Google Cloud + Santo Digital, SP, set/2026) | Arquitetura, engenharia e dados 50% (inclui segurança, LGPD, desenho de experimentação) · Negócio 30% · Design e experiência 20% | Banca humana + avaliação complementar por LLM. Pitch de 5 min. 5 entregáveis, de proposta de negócio a desenho de arquitetura e protótipo funcional. |
| ADK Hackathon (Google Cloud, Devpost, 2025) | Implementação técnica 50% (código limpo, uso dos conceitos do ADK, vários agentes colaborando) · Inovação e criatividade 30% (problema claro, demo, documentação, diagrama de arquitetura) · resto não confirmado (provável demo) | Pesos vistos em espelho da página. Bônus: post/vídeo publicado, contribuição ao ADK, uso de Cloud Run, BigQuery, Agent Engine, Vertex. Exigia diagrama de arquitetura e vídeo. |
| Gemini Live Agent Challenge (2026) | Inovação e UX multimodal 40% ("quebra o paradigma da caixa de texto"? persona/voz própria?) · demais não confirmados | Categorias: Live Agent, Creative Storyteller, UI Navigator. |
| Hackathon de LLM do Nubank | Impacto no negócio · Inovação · Viabilidade | Pitch de 5 min. Organizadores: difícil comparar projetos com escopo e completude muito diferentes. |
| Capgemini + Google Cloud | Inovação · Viabilidade · Alinhamento com necessidade de negócio | 49 mentores e jurados; vários projetos viraram piloto de MVP. |
| Hackathon interno (briefing do organizador, 24-25/11) | IA (generativa ou tradicional) como core é o requisito nº 1 · "sair da caixa" é critério · um critério é avaliado por jurados do Google | Critérios completos saem na abertura. |

## 2. Casos por hackathon

### Batalha de Agentes, Itaú (o caso mais parecido)

- Formato: 2 dias presenciais em SP, times de 4-5 montados pela empresa, mentoria técnica Santo Digital, capacitação prévia com Google. Desafio: agente conversacional de IA generativa para uma jornada financeira real, justificada com dados.
- Dados: base sintética fornecida pelo evento (467.585 lançamentos de extrato, 1.000 clientes, jan-dez/2025).
- Vencedor (selo de 1º lugar no próprio repositório): **zera.ai**, renegociação de dívida que cabe no mês da cliente.
  - Problema saiu da base, não de ideia pronta: k-means (k=4) no BigQuery ML; cluster mais endividado = 16% da base; persona "Cleide" = medoide do cluster (cliente real mais típico), com números (renda R$ 8.632, 11 de 12 meses no vermelho, R$ 603/mês só de juros).
  - "O modelo explica; nunca faz conta": motor determinístico em Python puro com testes produz todo número; guardrail de saída confere cada número do texto contra os resultados das tools da sessão.
  - Só a cliente contrata: `FunctionTool(require_confirmation=True)` do ADK e um botão "Contratar" determinístico que não passa pelo Gemini. Consentimento registrado com canal, frase e hora.
  - Roteamento determinístico antes do agente (cumprimentos, "1", "2", "3" resolvidos sem modelo). Experiência guiada com 0 tokens; conversa é uma via a mais sobre o mesmo motor.
  - Bloqueio de guardrail vira encaminhamento para humano, sem linguagem técnica na tela.
  - Stack: ADK 2.10, Gemini Flash no Vertex AI (endpoint `global`, temperatura 0,2), BigQuery + BigQuery ML, 1 serviço Cloud Run (UI + API + agente), React na UI.
  - Engenharia: 101 testes sem rede (motor, fluxo, agente com HITL via FakeLlm, ataques aos guardrails), `ML.EVALUATE` do k-means, smoke test em produção, logs JSON, `/metrics` com p50/p95 e custo por jornada (~US$ 0,002).
  - Ciclo de vida do agente em 7 fases (definir, dados, desenhar, construir, avaliar, implantar, observar), cada uma com artefato no repo.
  - Entregáveis: README com sumário, documento explicativo, C4 níveis 1 e 2, diagramas de sequência, PRD, quadro único de produto (30 linhas), estratégia de dados, 17 decisões de arquitetura + 16 de dados/algoritmos, pitch de 3 slides, vídeo de contingência, QR da demo em produção.
  - Métrica principal de produto: cumprimento em D+90 (manter o acordo, não só fechar).
  - Armadilha real: o projeto Google Cloud do evento não permitia criar service account nem repositório; usaram a SA existente e plano B com chave de API no Secret Manager.

### Hackathon de LLM do Nubank

- 114 participantes, ~1,5 dia de mão na massa, times mistos (BA, engenharia, PM).
- Vencedor: agente para escalar negociações (empréstimos, dívida atrasada, seguro), PoC em notebook com LangGraph + React.
- Outros: identificação precoce de crise de fraude, sugestão de métricas para teste A/B, parser de PDFs jurídicos, respostas de IA na central de ajuda.
- Lições dos organizadores: infra de IA testada antes; definir "protótipo funcionando" na abertura; escopo comparável entre times.

### ADK Hackathon (Google Cloud, 2025): 10.400+ participantes, 477 projetos

- Grand prize: SalesShortcut, SDR com vários agentes (lead, pesquisa, proposta, contato).
- América Latina: Edu.AI, sistema educacional para o Brasil com agentes que corrigem redação, montam plano de estudo e simulados.
- América do Norte: Energy Agent AI, atendimento de energia com orquestração ADK.
- APAC: GreenOps, "time de IA" que audita, prevê e otimiza nuvem para sustentabilidade.
- EMEA: Nexora-AI, ensino com aulas interativas, visuais e quizzes.
- Menções: TradeSageAI (avaliação de hipóteses de trading com vários agentes; ADK, Agent Engine, Cloud Run, Vertex), Bleach (construtor visual de agentes), Particle Physics Agent.

### GKE Turns 10 Hackathon (agentes no GKE com Gemini)

- Finanças: CardOS (pré-aprovação de crédito com vários agentes, equilibra lucro do banco e valor ao cliente), Voice Teller (agente de voz no lugar da URA do banco; ADK + MCP), Vigil AI (fraude com 4 agentes: monitor, orquestrador, investigação, atuador).
- Grand prize: assistente "do carrinho à cozinha" (Gemini, ADK, A2A).

### Gemini Live Agent Challenge (2026)

- Grand prize: ORION, assistente de voz para centro cirúrgico.
- Destaques: Wand (vê, navega e clica com o usuário), JohnKeats.AI ("o agente que sabe quando ficar quieto", proatividade com timing), Rayan Memory (memória), drone-copilot.

### Gemini API Developer Competition (2024)

- Jayu (assistente que opera outras apps), Vite Vere (passo a passo para pessoas com deficiência cognitiva), **Prospera** (coach de vendas em tempo real, Most Useful + Best Flutter), Gaze Link, Trippy (Firebase), ViddyScribe.

### Kaggle x Google DeepMind, Gemini 3 (dez/2025, 50 vencedores)

- Distribuição: Developer Tools 12, Creative 9, Ciência 7, Educação 7, Saúde 5, Finanças/Negócios 3. Único claramente de investimento: VOLT ("trading com IA para todos").
- Leituras do analista (não da banca): nicho com execução profunda vence app genérico; quase todos usam vídeo, voz ou imagem; 40 de 50 eram solo.

### Gen AI Exchange (Google Cloud + Hack2skill, Índia, 4.457 protótipos)

- Fábrica de cimento: agentes monitoram e otimizam; humanos aprovam decisões de alto nível (único HITL explícito).
- GovernAI: ML prevê risco + agentes recomendam política + chatbot cidadão (ML tradicional + agentes).
- PitchLense: análise de investimento em startups (lê documentos, relatório de risco, copiloto de analista).
- Outros: saúde mental jovem (índice de risco), marketplace de artesãos, assistente jurídico com RAG, deepfake, carreira, casos de teste a partir de PRD.

### Google for Startups AI Agents Challenge (relatório dos jurados, set/2026)

Ver seção 3, padrões 6 a 9.

## 3. Padrões dos campeões

1. **Uma jornada vertical, um momento de decisão.** Processo de negócio de ponta a ponta com começo, meio e fim; não chat genérico.
2. **O problema nasce do dado.** Segmentação (ML tradicional) → persona real com números → dor quantificada. ML tradicional + generativa juntos atendem "IA como core" pelos dois lados.
3. **O LLM explica; código calcula.** Motor determinístico testado gera números, elegibilidade e termos; o LLM entende a intenção, chama tools e explica. Guardrail confere os números do texto.
4. **Humano no circuito para ações com efeito.** Proposta → card de confirmação → execução determinística. Consentimento registrado. Encaminhar para humano é saída prevista.
5. **Proatividade com gatilho.** O agente aparece no momento certo (evento no extrato, no mercado, na carteira), com permissão do cliente.
6. **Vários agentes só quando há especialistas de verdade** (ferramentas e dados diferentes, rodando em paralelo quando reagem ao mesmo evento). Jurados Google desclassificam "cadeia de prompts com nomes de agente".
7. **Roteamento em camadas.** Regras locais (0 tokens) → modelo barato para classificar → modelo forte só para o que sobra. Num time, a 1ª camada resolveu mais de 40% das mensagens.
8. **Reserva com a mesma barra.** O modelo de reserva passa pela mesma validação do principal (uma função de validação para todos os caminhos).
9. **Ferramentas com respostas enxutas** (um resumo, um registro), nunca a tabela inteira no contexto. Expor as tools via MCP para outros agentes é bônus.
10. **Multimodal quando muda a experiência:** voz, imagem, documento. Ganha categorias de UX.
11. **Engenharia visível:** testes sem rede, avaliação do modelo de ML, observabilidade, custo por jornada, deploy em Cloud Run. Pesa nos 50% técnicos.
12. **Entrega completa:** diagrama de arquitetura, vídeo de reserva, demo que roda, decisões registradas, quadro de produto com métricas.

## 4. O que os jurados penalizaram

- "Multi-agente" que é um modelo só com cadeia de prompts.
- Chamadas lineares onde agentes poderiam rodar em paralelo (latência somada).
- Resultado de consulta inteiro jogado no contexto.
- Retry no mesmo modelo em vez de reserva; reserva sem a validação do caminho principal.
- Mandar pergunta fácil para o modelo caro.
- Demo confusa: projeto forte com demo confusa perde para projeto simples que a banca entende (relato de jurado).
- Cinco features pela metade em vez de uma polida.

## 5. Contexto de mercado (investimentos, pessoa física)

- Investimento de brasileiros no exterior cresceu ~14% ao ano em 2020-2025 (contra ~6,7% em 2015-2020); ainda é menos de 4% do PIB (Anbima). Ações (48%) e ETFs (15%) lideram os bens declarados no exterior (Receita).
- FGV (set/2026): internacionalizar segue sendo exceção; cita piso de 16% do patrimônio no exterior para proteger o consumo; carteira com bloco internacional por regra fixa teve Sharpe 0,43 contra 0,05 da doméstica (2005-2026).
- Deloitte (via WEF): ferramentas de IA serão a principal fonte de conselho do investidor de varejo até 2027; clientes vão esperar respostas rápidas, personalizadas e contato proativo.
- BCG/McKinsey: cenário provável é o assessor humano supervisionando agentes de IA; foco humano nas decisões que exigem julgamento.
- Já é commodity: "nota da carteira" e análise de carteira com IA (Nubank Nu Smart Invest, BTG, XP, Itaú). Ideia de investimento precisa de outro ângulo para ser "fora da caixa".
- Google Cloud (pesquisa com instituições financeiras): casos de agente mais citados são atendimento/experiência do cliente (57%), finanças e contabilidade, segurança, fraude, inovação de produto e onboarding.

## 6. Fontes

- https://github.com/dcdaniiel/zera.ai-itau (README e `docs/quadro-produto.md`)
- https://www.letsmoney.com.br/ia/batalha-de-agentes-itau-zera-ai-renegociacao/
- https://coletivo.tech/noticias/itau-hackathon-batalha-de-agentes/
- https://building.nu.com/nubank-llm-hackathon-lessons-learned/
- https://cloud.google.com/blog/products/ai-machine-learning/adk-hackathon-results-winners-and-highlights
- https://nodejs2025.netlify.app/host-https-googlecloudmultiagents.devpost.com (espelho da página do ADK Hackathon)
- https://cloud.google.com/blog/topics/developers-practitioners/winners-and-highlights-of-the-gemini-live-agent-challenge
- https://cloud.google.com/blog/topics/developers-practitioners/winners-and-highlights-from-gke-hackathon
- https://developers.googleblog.com/en/announcing-the-winners-of-the-gemini-api-developer-competition/
- https://adrianwwwang.github.io/Kaggle_Google_deepmind_winner_analysis/gemini3_winners_analysis.html
- https://blog.hack2skill.com/gen-ai-exchange-hackathon-finale
- https://developers.googleblog.com/en/4-engineering-patterns-behind-the-strongest-ai-agents-challenge-submissions/
- https://www.capgemini.com/be-en/insights/expert-perspectives/agentic-ai-in-action-lessons-from-the-capgemini-and-google-cloud-hackathon/
- https://bpmoney.com.br/mercado/investimento-brasileiros-exterior-dobra-cinco-anos-anbima/
- https://eaesp.fgv.br/sites/default/files/uploads/FGVcef/PROJETOS/Ir%20para%20o%20exterior%20%C3%A9%20fundamental/estudo-investimentos-no-exterior-set2026.pdf
- https://www.weforum.org/stories/emerging-technologies/ai-wealth-management-and-trust-could-machines-replace-human-advisors/
- https://www.deloitte.com/us/en/insights/industry/financial-services/financial-services-industry-predictions/2026/agentic-ai-wealth-management-productivity.html
- https://www.letsmoney.com.br/fintech/nubank-nu-smart-invest-ia-carteira/
- https://cloud.google.com/transform/new-research-shows-how-ai-agents-are-driving-value-for-financial-services
