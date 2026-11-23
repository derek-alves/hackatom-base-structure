# Estratégia de dados e ML

**Regra número um:** nenhum dado real de cliente. A aplicação só conhece <a base do evento | dados fictícios gerados por `seed.py` | dados públicos citados> e o que é derivado deles por regras versionadas.

## Fontes

| Fonte | O que tem | Tamanho / período | Real, público ou fictício |
|---|---|---|---|
| | | | |

## Por que o agente não lê dado bruto

O agente recebe resumos enxutos das tools (um perfil, um resultado), nunca tabelas inteiras: custa menos, responde mais rápido e reduz alucinação numérica.

## Camadas

| Camada | Tabela / arquivo | Conteúdo | Como gera |
|---|---|---|---|
| Bruta | | | |
| Features | | | |
| Modelo | | | |
| Perfis da demo | | persona = cliente mais típico do segmento-alvo | |

## Modelo de ML

- Tarefa (segmentação, classificação, anomalia, previsão):
- Features:
- Algoritmo e parâmetros (`random_state` fixo):
- Avaliação (métrica, holdout) e baseline de regra:
- Como os dados de treino foram gerados (se fictícios):
- Onde roda (local `scikit-learn` / BigQuery ML) e como a tool o chama:

## Segmento e persona

- Segmento-alvo e tamanho:
- Persona (números):

## Como ligar

```bash
# local (zip): dados fictícios
# nuvem (opcional): BigQuery / BigQuery ML
```

## Custos e limites

-
