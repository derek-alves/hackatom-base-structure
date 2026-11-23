# Roteiro da demo

As mesmas frases servem para gravar (`DEMO_MODE=record`) e apresentar (`DEMO_MODE=replay`): o replay só responde a turnos iguais aos gravados (texto sem diferenciar maiúsculas e espaços, ação de widget ou imagem).

| # | Quem faz | Toque / texto exato | O que aparece (widget e números esperados) | Fala de quem narra |
|---|---|---|---|---|
| 1 | | | | |

## Preparação

- [ ] Banco no estado inicial (`podman compose down -v` ou apagar `backend/data/app.db`).
- [ ] Servidores de `MCP_SERVERS` no ar (as tools rodam de verdade no replay).
- [ ] Gravação copiada para fora de `backend/data/` e `DEMO_RECORDINGS_PATH` apontando para ela.
- [ ] Emulador/aparelho com o app e `API_BASE_URL` certo.
- [ ] Vídeo de reserva (2-3 min) aberto.
