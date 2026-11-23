# Entrega

Na entrega, as seções de "README de entrega" viram o topo do `README.md` da raiz (o README atual de como rodar o starter continua abaixo).

## README de entrega (modelo)

````markdown
# <Nome>

**<Frase de valor>.** <Uma linha: o que o agente faz, para quem, no momento certo.>
*<Princípio em uma frase, ex.: O modelo explica; o código calcula.>*

[Vídeo](docs/hackathon/<video>) · [Pitch](docs/hackathon/<pitch.pdf>) · [Arquitetura](docs/hackathon/02-arquitetura.md) · [Dados](docs/hackathon/06-dados.md) · [Quadro de produto](docs/hackathon/01-ideia.md)

## 1. O problema
<persona com números, segmento do dado, dado de mercado com fonte>

## 2. A solução em passos
| Passo | O que acontece | Quem faz (arquivo) |
|---|---|---|

## 3. Princípios
| Princípio | Como se garante |
|---|---|

## 4. Arquitetura
<C4 nível 2 e um fluxo; link para 02-arquitetura.md>

## 5. Decisões
<as 5-8 decisões que definem o produto, uma linha cada>

## 6. IA no centro
<ML tradicional (modelo, métrica) + generativa (papel) + o que quebra sem IA>

## 7. Rodar local (modo demo, sem chave)
```bash
cp backend/.env.example backend/.env   # DEMO_MODE=replay, DEMO_RECORDINGS_PATH=demo/demo_recordings.json
podman compose up --build              # ou: cd backend && uv sync && uv run fastapi dev app/main.py
cd mobile && fvm flutter run
```

## 8. Stack Google
| Serviço | Uso |
|---|---|

## 9. Qualidade, custo e métricas
<testes, bateria de avaliação, custo por jornada, métrica principal>

## 10. Limitações e próximos passos

## 11. Time
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
