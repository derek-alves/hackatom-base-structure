# Estratégia de dados e ML

**Regra número um:** nenhum dado real de cliente. A aplicação só conhece dados fictícios gerados por `backend/app/modules/family/seed.py` (Família Almeida) e o que é derivado deles por regras versionadas em `policies.py`. Os números reais (Databricks, pesquisas, IRS) aparecem só no pitch e no quadro de produto, com fonte.

## Fontes

| Fonte | O que tem | Tamanho / período | Real, público ou fictício |
|---|---|---|---|
| Databricks (via ideia final) | 14,7 mil clientes acima de US$ 50 mil sem usar Banking; 36% do AUC com clientes de banking ocioso | Base atual | Real, interno, agregado. Só no slide e arredondado ("~15 mil", "~1/3 do AUC"); pergunta 5 do briefing |
| Pesquisa Avenue | 23% da base chegou por indicação da própria família | — | Real, interno, agregado |
| "O Movimento Global", Tribo Investimentos 2026 | Por que investe fora (proteção do real 89%, legado 18%); ponto forte da Avenue (investimento + conta + cartão 46%) | Pesquisa 2026, múltipla escolha | Público |
| JP Morgan (citado pelo time) | 70% dos herdeiros trocam de instituição após a herança | — | Público; conferir a publicação antes do pitch |
| IRS: Form 706-NA, tabela §2001(c), IRC §2105(b) | Alíquotas de 18% a 40%, crédito unificado de US$ 13 mil para não residente (equivale a US$ 60 mil isentos), depósito bancário fora da base | Vigente em 2026 | Público, versionado em `policies.py` com data |
| Seed da Família Almeida | Membros, papéis, contas, cofrinhos, limites, beneficiários | 5 membros + 1 especialista | Fictício, rotulado no app |

## Por que o agente não lê dado bruto

O agente recebe resumos enxutos das tools (o que o membro pode ver, um pedido, um mapa), nunca tabelas inteiras: custa menos, responde mais rápido e reduz alucinação numérica. Além disso, cada tool filtra pelo papel de quem pergunta antes de devolver: o que o papel não libera nunca chega ao modelo.

## Camadas

| Camada | Tabela / arquivo | Conteúdo | Como gera |
|---|---|---|---|
| Bruta | `family/models.py` (SQLite) | `Member`, `Account`, `Piggybank`, `TransferRequest`, `ConsentLog`, `FamilyMessage` | `seed.py` no startup (idempotente) e `POST /api/family/demo/reset` |
| Regras | `family/policies.py` | Matriz de permissões, limites por membro, tabela §2001(c), crédito de US$ 13 mil, lista bloqueada da regra 3, lista fechada de próximos passos | Versionado, com fonte e data |
| Derivada | `family/service.py` | Patrimônio por membro e por titular, limite restante, estimativa educativa, mapa de sucessão | Funções puras com testes |
| Modelo | Não se aplica no P0 | — | ML no roadmap (abaixo) |
| Perfis da demo | `family/seed.py` | Família Almeida (tabela abaixo) | Fictícia; calibrar com o perfil típico do segmento se o agregado sair |

### Família Almeida (fictícia)

| Membro | Papel | Contas e valores | Beneficiário | Regras |
|---|---|---|---|---|
| Marcos, 52 | Owner (titular) | Investimentos em custódia nos EUA US$ 600.000; conta US$ 18.000 | Investimentos: nenhum (titular único); conta: Helena | Aprova pedidos de Dona Lúcia, Ana e Pedro (quando envolve dinheiro de outro membro) |
| Helena, 49 | Owner (cônjuge) | Investimentos US$ 210.000; conta US$ 9.500 | Investimentos: Marcos; conta: nenhum | Vê o patrimônio da família |
| Pedro, 24 | Membro adulto (Boston) | Conta US$ 4.200; cofrinho US$ 1.840 | — | Vê só o que os pais liberaram; decide na própria conta |
| Ana, 16 | Dependente | Cartão de dependente na conta do Marcos, mesada US$ 150/mês; cofrinho do intercâmbio US$ 3.200, meta US$ 8.000 em jul/2027 | — | Não vê patrimônio; sugere ao owner |
| Dona Lúcia, 78 | Membro por voz (mãe do Marcos) | Conta US$ 35.000 | — | Envio até US$ 500/mês, só para a família, aprovado no app do Marcos |
| Rafael | Agente Especialista (humano) | — | — | Vê com consentimento; nunca decide pelo cliente |

Patrimônio da família na Avenue: US$ 881.740. Depois da cena 2: conta da Dona Lúcia US$ 34.800, cofrinho do Pedro US$ 2.040, limite restante dela no mês US$ 300.

### Estimativa educativa de estate tax (motor, sem LLM)

`imposto = tabela §2001(c)(ativos de investimento nos EUA) − 13.000`, mínimo 0. Depósito bancário fica fora (IRC §2105(b)). Sem deduções, cônjuge, tratado ou dívidas: o card diz "estimativa educativa", e o especialista confirma.

| Titular | Base | Tabela | Crédito | Estimativa |
|---|---|---|---|---|
| Marcos | US$ 600.000 | 155.800 + 37% × 100.000 = US$ 192.800 | US$ 13.000 | **US$ 179.800** |
| Helena | US$ 210.000 | 38.800 + 32% × 60.000 = US$ 58.000 | US$ 13.000 | **US$ 45.000** |
| Dona Lúcia | US$ 0 (só conta) | — | — | US$ 0 |

O beneficiário (POD) evita o inventário nos EUA e agiliza a transmissão; não reduz o imposto. O card de sucessão diz isso com essas palavras.

## Modelo de ML

Não se aplica no P0: a IA core do protótipo é generativa (entender a fala de cada membro, resolver parentesco, explicar por membro, briefing do especialista). A banca simulada mostrou que um modelo sem cena na demo vira peso, não nota. Plano para o roadmap (P2):

- Tarefa: detecção de anomalia nos gastos do cartão de dependente, para o aviso de coerência com o plano.
- Features: valor, categoria (MCC), dia da semana, hora, desvio da média móvel de 30 dias do próprio dependente.
- Algoritmo e parâmetros: `IsolationForest(random_state=42, contamination=0.02)`.
- Avaliação e baseline: precisão e recall nas anomalias injetadas num holdout, contra baseline de regra (z-score > 3 na média móvel); matriz de confusão no slide.
- Dados de treino: transações fictícias com seed fixa e anomalias injetadas, declaradas como tal.
- Onde roda: local com `scikit-learn` (`uv add scikit-learn pandas`), exposto como tool; BigQuery ML só se houver base real anonimizada.

## Segmento e persona

- Segmento-alvo e tamanho: clientes acima de US$ 50 mil (Advance, Singular, Private); porta de entrada são os 14,7 mil sem Banking, com 36% do AUC (Databricks).
- Persona (números): Família Almeida, acima. Marcos, 52, US$ 618 mil na Avenue, US$ 600 mil em ativos americanos, titular único nos investimentos e sem beneficiário; quatro membros da família, um deles só por voz. Pendência: calibrar idade e patrimônio com o agregado do segmento.

## Como ligar

```bash
# local (zip): dados fictícios, seed no startup
cd backend && uv sync && uv run fastapi dev app/main.py
curl -X POST http://localhost:8000/api/family/demo/reset   # volta a família ao estado inicial (antes de gravar ou apresentar)

# container
podman compose up --build
podman compose down -v                                     # apaga o banco
```

Nuvem (BigQuery, Cloud Run): não se aplica no protótipo.

## Custos e limites

- Custo do modelo: só o `ui_agent`, uma chamada por turno com tools; meta abaixo de US$ 0,01 por cena (medir no ensaio com o proxy e anotar em `02-arquitetura.md`, seção 11).
- Limites: tools devolvem no máximo um membro ou um mapa por chamada; histórico de 6 turnos por sessão; a thread da família guarda as mensagens da demo.
- Sem chave: `DEMO_MODE=replay` com a gravação versionada fora de `backend/data/`.
