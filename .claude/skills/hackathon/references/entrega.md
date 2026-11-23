# Modelos de artefato, pitch, demo e zip

Use nas fases 1, 2, 4 e 5. Os artefatos ficam em `docs/hackathon/` e são versionados.

## `00-briefing.md` (fase 1)

```markdown
# Briefing do tema

- Tema (texto exato da abertura):
- Ligação com a estratégia 2030 (o que o organizador disse):
- Frentes sugeridas pelo organizador:
- Materiais disponíveis (dores de clientes do time de produto, datasets, APIs):
- Critérios oficiais e pesos (copiar literal):
- Critério avaliado pelos jurados Google:
- Entregáveis exigidos e formato (formulário, zip, vídeo, slides):
- Restrições (dados, modelos via proxy, stack, IP):
- Horários: freeze, entrega, ordem das apresentações:
- Perguntas para o organizador/mentores:
```

## `01-ideia.md` (fase 2): quadro de produto enxuto

```markdown
# <nome do produto>: <frase de uma linha>

**Tese:** Ao <o que o agente faz> para <público>, no momento <gatilho>, esperamos <resultado para o cliente> e <resultado para o negócio>.

| Etapa | Definição | Evidência ou pendência |
|---|---|---|
| Problema | | dado que comprova |
| Público e persona | persona com números (medoide do segmento, se houver ML) | |
| Momento/gatilho | | |
| Decisão que o agente ajuda | | |
| IA core | ML tradicional: ... · Generativa: ... · Tirar a IA quebra o quê? | |
| Motor determinístico | o que o código calcula | |
| Papel do LLM | entender, perguntar, explicar | |
| Ação com confirmação | o que o cliente confirma | |
| Diferencial ("fora da caixa") | o que a concorrência não faz | |
| Métrica principal | fórmula | baseline |
| Métricas de apoio | conversão, custo por jornada, encaminhamentos | |
| Guardrails | números, tom, dados, consentimento | |
| Escopo do MVP | uma persona, um gatilho, uma jornada | |
| Fora do MVP | | |
| Evolução | piloto → visão ampliada | |
```

Anexe ao fim: as ideias avaliadas, com nota da rubrica, e o parecer da `banca-simulada`.

## `03-plano.md` (fase 4)

Tabela por bloco de horário com uma linha por pessoa: tarefa, artefato que entrega, de quem depende. Marque os checkpoints e o freeze. Modelo de horários na tabela da fase 4 do `SKILL.md`.

## Pitch de 10 minutos (`04-pitch.md`)

| Tempo | Bloco | Conteúdo |
|---|---|---|
| 0:00-1:00 | Dor | Persona com números e o momento em que ela sofre. Um dado de mercado com fonte. |
| 1:00-2:00 | Insight | O que os dados mostraram (segmento, tamanho, padrão). Por que agora (estratégia 2030). |
| 2:00-6:00 | Demo | Uma jornada só, ponta a ponta, com o contraste antes × depois e um momento "isso agora é possível". Termina na ação confirmada pelo cliente. |
| 6:00-7:30 | Como funciona | C4 nível 2 em um slide: onde está a IA tradicional, onde está a generativa, o motor que calcula, o guardrail, a confirmação humana. Stack Google nomeada. |
| 7:30-8:30 | Resultado | Métrica principal, impacto estimado com premissa explícita, custo por jornada. |
| 8:30-9:30 | Próximos passos | Piloto, o que é simulado hoje, o que precisa para produzir. |
| 9:30-10:00 | Fecho | Frase da tese. |

Regras: uma pessoa conduz a demo, outra fala. Ensaiar 2 vezes cronometrado. Demo ao vivo em `DEMO_MODE=replay` com as perguntas do ensaio; vídeo de reserva aberto em outra aba. Prepare respostas para as 5 perguntas que a `banca-simulada` levantar.

## Roteiro da demo (`05-demo.md`)

Liste cada passo: o que a pessoa toca/digita (texto exato), o que aparece (widget e números esperados) e a frase de quem narra. Use as mesmas frases ao gravar com `DEMO_MODE=record`: o replay só responde a perguntas iguais às gravadas.

## Gravação e reserva

1. Backend com o modelo real e `DEMO_MODE=record`; rode o roteiro inteiro.
2. Copie `backend/data/demo_recordings.json` para fora de `data/` (ex.: `backend/demo/demo_recordings.json`): `backend/data/` está no `.gitignore` e no Podman fica no volume.
3. Teste com `DEMO_MODE=replay` e `DEMO_RECORDINGS_PATH` apontando para a cópia, sem chave de API.
4. Grave um vídeo de 2-3 minutos da jornada (tela do emulador + narração) como reserva.

## Zip para os jurados

Gerar a partir do git, para não levar segredos:

```bash
git archive --format=zip -o entrega.zip HEAD
```

Checklist antes de enviar:

- [ ] Nenhum `.env`, chave ou token no zip (`unzip -l entrega.zip | grep -i env` não mostra `backend/.env`).
- [ ] Gravação da demo versionada fora de `data/` e `DEMO_RECORDINGS_PATH` documentado.
- [ ] README do topo com "rodar em 3 comandos" em modo replay (Podman: `podman compose up --build` com `DEMO_MODE=replay`).
- [ ] APK ou instrução de `fvm flutter run --dart-define=API_BASE_URL=...`; quem não tiver emulador assiste ao vídeo.
- [ ] `docs/hackathon/` completo: briefing, ideia, arquitetura com C4 e decisões, plano, pitch, roteiro da demo.
- [ ] Slides e vídeo anexados no formulário.
- [ ] Testes passam: `cd backend && uv run pytest -m "not e2e"`.
