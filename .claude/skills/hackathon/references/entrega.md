# Modelos de artefato, pitch, demo e zip

Use nas fases 1 a 5. Os artefatos ficam em `docs/hackathon/` e são versionados.

## Modelos

Os modelos ficam em `docs/hackathon/` e são preenchidos no lugar:

| Arquivo | Conteúdo |
|---|---|
| `00-briefing.md` | tema literal, critérios e pesos oficiais, entregáveis, materiais, restrições, horários |
| `01-ideia.md` | quadro de produto (20 linhas), escopo P0/P1/P2, ideias avaliadas, parecer da banca |
| `02-arquitetura.md` | resumo, princípios, contrato do agente, C4, componentes no repo, integrações Google, fluxos, decisões, segurança, qualidade, rastreabilidade |
| `03-plano.md` | blocos × pessoas, dependências, slots com especialistas, riscos |
| `04-pitch.md` | roteiro de 10 min e perguntas da banca |
| `05-demo.md` | passos exatos da demo e preparação |
| `06-dados.md` | fontes, camadas, modelo de ML e avaliação, persona |
| `07-entrega.md` | README de entrega, runbook, checklist do zip |

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
