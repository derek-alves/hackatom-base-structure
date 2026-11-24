# Entrega

Na entrega, as seções de "README de entrega" viram o topo do `README.md` da raiz (o README atual de como rodar o starter continua abaixo).

## README de entrega (modelo)

Rascunho do D1, a fechar no D2 depois do freeze (vídeo, deck, números de custo e testes).

````markdown
# Agente Familiar Avenue

**Cuidando da sua família, seu maior patrimônio.** Um agente de IA, por voz ou texto, cuida da vida financeira global da família no Espaço Família; o especialista humano entra na mesma conversa quando o assunto pede, e o owner decide.
*O modelo entende e explica; o código calcula e executa; o cliente decide.*

[Vídeo](docs/hackathon/<video>) · [Pitch](docs/hackathon/<pitch.pdf>) · [Arquitetura](docs/hackathon/02-arquitetura.md) · [Dados](docs/hackathon/06-dados.md) · [Quadro de produto](docs/hackathon/01-ideia.md)

## 1. O problema
70% dos herdeiros trocam de instituição financeira logo após a herança (JP Morgan). Na Avenue, cerca de 15 mil clientes acima de US$ 50 mil, com cerca de um terço do AUC, não usam o banking (Databricks). Na família, o dinheiro está espalhado, ninguém sabe o que acontece com os dólares se o titular faltar, e os pais idosos não usam o app. Persona (fictícia): a Família Almeida. O Marcos, 52, tem US$ 600 mil em ativos americanos sem beneficiário; a mãe dele, Dona Lúcia, 78, só usa voz.

## 2. A solução em passos
| Passo | O que acontece | Quem faz (arquivo) |
|---|---|---|
| 1 | A Dona Lúcia pede por voz: US$ 200 de aniversário para o neto | App: voz no aparelho (`mobile/lib/modules/family/`) |
| 2 | A IA entende "meu neto" → Pedro, valor e motivo; o código confere o limite e cria um pedido pendente | `ui_agent` + `backend/app/modules/family/tools.py`, `service.py` |
| 3 | O Marcos (owner) vê o pedido com valor, limite e impacto e aprova | `ApprovalConfirmationCard` |
| 4 | O código executa e registra o consentimento, sem LLM; a Dona Lúcia ouve "Pronto, o Pedro recebeu" | Handler de ação (`assistant/router.py` + `AppModule.action_handlers`) |
| 5 | O Marcos pergunta sobre sucessão: o código monta o mapa e a estimativa educativa de estate tax; a IA explica | `family/service.py`, `policies.py` |
| 6 | O Marcos escolhe os próximos passos; o código cria o caso; a IA escreve o briefing da família (filtrado); o Rafael entra na mesma conversa; o Marcos decide | Handler de `checklist_submitted`, `get_family_timeline`, `save_specialist_briefing`, `family/router.py` (thread) |

## 3. Princípios
| Princípio | Como se garante |
|---|---|
| O LLM nunca calcula | Motor em Python com testes + guardrail de números |
| Só o owner confirma ação com efeito | Card de aprovação + handler de código; a voz nunca aprova |
| O agente só vê o que o papel libera | Membro vem da sessão (`tool_context.user_id`); filtro no código |
| Sem recomendação de investimento | Contrato + filtro de saída + lista fechada de próximos passos |
| Nenhum dado real | Família Almeida fictícia, rotulada no app |

## 4. Arquitetura
C4 nível 2 e fluxos em [`02-arquitetura.md`](docs/hackathon/02-arquitetura.md): App Flutter (A2UI) → FastAPI → Workflow ADK 2.x (`prepare_input` → `ui_agent` Gemini via AI Proxy → `render_a2ui` com guardrails) → motor `family` sobre SQLite.

## 5. Decisões
- Motor determinístico separado do LLM.
- Ação com efeito executada por handler de código registrado pelo módulo.
- Membro da sessão nas tools, nunca argumento do LLM.
- Um app com seletor de perfil sobre a mesma conversa da família.
- Voz no aparelho, com áudio direto ao Gemini como evolução.
- Um agente com tools; o segundo agente da dupla é humano.
- Modelo pelo Proxy SDK da Avenue, opcional, para o projeto rodar em replay sem o pacote privado.

## 6. IA no centro
Generativa (Gemini via AI Proxy, orquestrado pelo ADK): entende a fala de cada membro, resolve parentesco no grafo da família, pergunta o que falta, explica no nível de cada pessoa e escreve o briefing do especialista. O card "Por trás" mostra em cada cena o que a IA entendeu e o que o código calculou. Sem IA, a Dona Lúcia fica de fora e o especialista recomeça do zero. ML tradicional: no roadmap (detector de anomalia no cartão de dependente, com baseline de regra).

## 7. Rodar local (modo demo, sem chave)
```bash
cp backend/.env.example backend/.env   # DEMO_MODE=replay, DEMO_RECORDINGS_PATH=demo/demo_recordings.json
podman compose up --build              # ou: cd backend && uv sync && uv run fastapi dev app/main.py
cd mobile && fvm flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```
Com o modelo real (rede corporativa ou VPN, acesso à org `avenuesec`): `gh auth setup-git`, `cd backend && uv sync --extra avenue`, `LLM_PROVIDER=avenue` e `AI_PROXY_API_KEY` em `backend/.env` (ver `docs/infra-ia/README.md`).

## 8. Stack Google
| Serviço | Uso |
|---|---|
| Gemini (Vertex AI) via AI Proxy da Avenue | Agente Familiar |
| Google ADK 2.x | Workflow, tools, callbacks de guardrail, modelo de reserva |
| A2UI | Widgets do agente no app |

## 9. Qualidade, custo e métricas
<testes (quantos, o que cobrem), bateria de 12 perguntas, custo por cena em tokens, métrica principal: famílias ativas>

## 10. Limitações e próximos passos
Simulado: login (seletor de perfil), dinheiro (SQLite), biometria (fica para produção), especialista (pessoa do time), estimativa de imposto (educativa). Para produzir: CX Agent AI (voz), pit-mcp (consentimento por membro), `accounts`, `banking`, `insights`, Salesforce, MyProfit, revisão do Jurídico.

## 11. Time
Time 3: Thyago Rebelato (produto), Derek Alves (backend e mobile), Leonardo <sobrenome> (backend, mobile e produto), Vinicius Yamaguti (IA), Jenny Nascimento (produto), Karine Narumi (design e produto).
````

## Runbook

- Rodar local: ver seção 7 do modelo acima.
- Gravação da demo: `DEMO_MODE=record`, roteiro de `05-demo.md`, copiar `backend/data/demo_recordings.json` para `backend/demo/`.
- Deploy opcional (Cloud Run): `backend/Containerfile`; se o projeto do evento bloquear service account, use a chave do proxy via variável.
- Plano B: `DEMO_MODE=replay` + vídeo de reserva.

## Checklist do zip

```bash
git archive --format=zip -o entrega.zip HEAD
unzip -l entrega.zip | grep -iE '(^|/)\.env$' && echo "PARE: .env no zip"
```

- [ ] Nenhum `.env`, chave ou token no zip.
- [ ] Gravação versionada fora de `data/` e `DEMO_RECORDINGS_PATH` documentado.
- [ ] README de entrega no topo do `README.md`.
- [ ] APK ou instrução de `fvm flutter run`; vídeo para quem não tiver emulador.
- [ ] `docs/hackathon/` preenchido.
- [ ] Slides e vídeo no formulário.
- [ ] `cd backend && uv run pytest -m "not e2e"` passa.
