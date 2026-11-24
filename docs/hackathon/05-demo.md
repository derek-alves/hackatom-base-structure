# Roteiro da demo

As mesmas frases servem para gravar (`DEMO_MODE=record`) e apresentar (`DEMO_MODE=replay`): o replay só responde a turnos iguais aos gravados (texto sem diferenciar maiúsculas e espaços, ação de widget ou imagem). Na voz, use o chip com a frase exata quando estiver em replay: a transcrição pode variar ("200" × "duzentos").

Rascunho do D1: os textos dos widgets e os números vêm do motor e da seed de `06-dados.md`; ajustar depois da primeira gravação. Duração alvo: 4 minutos.

Cada frase de chip é única no roteiro: o `turn_key` do replay ignora o membro, então a mesma frase dita por duas pessoas colide. O card "Por trás" é montado pelo código a partir das tool calls; o texto abaixo é o esperado, não o que o modelo escreve. Gravar as cenas 1 e 2 às 21h do D1 e a cena 3 assim que rodar.

| # | Quem faz | Toque / texto exato | O que aparece (widget e números esperados) | Fala de quem narra |
|---|---|---|---|---|
| 1 | Condutor | "Ver como" → Dona Lúcia | Tela simplificada com botão de voz grande; selo "dados fictícios" | "Esta é a Dona Lúcia, 78 anos. Ela não mexe no app: ela fala." |
| 2 | Condutor | Voz (ou chip): "Quanto tem no cofrinho do meu neto? Quero mandar 200 dólares de aniversário." | Resposta lida em voz alta: "O cofrinho do Pedro tem US$ 1.840. Mandei a confirmação para o celular do Marcos." `InfoListCard` "Por trás": "IA entendeu: neto → Pedro · US$ 200 · presente de aniversário"; "Código calculou: limite do mês US$ 500, usados US$ 0; saldo depois US$ 34.800" | "A IA entendeu quem é o neto, o valor e o motivo. O código conferiu o limite. E ela não aprovou nada: a voz nunca mexe no dinheiro sozinha." |
| 3 | Condutor | "Ver como" → Marcos; chip "Decisões pendentes" | `ApprovalConfirmationCard` APR-1 "Presente de aniversário para o Pedro": Valor US$ 200,00; De: Dona Lúcia; Para: cofrinho do Pedro (US$ 1.840 → US$ 2.040); Limite do mês da Dona Lúcia: US$ 300 restantes | "O Marcos é o owner. A decisão é dele, com o impacto para cada membro na tela." |
| 4 | Condutor | Aprovar (+ PIN, se entrar) | Texto: "Pronto: US$ 200 no cofrinho do Pedro. Avisei a Dona Lúcia." | "Quem executou foi o código, não o modelo, e o consentimento ficou registrado: quem pediu, por qual canal, quem aprovou e quando." |
| 5 | Condutor | "Ver como" → Dona Lúcia; chip "Novidades?" | Voz: "Pronto, o Pedro recebeu os seus 200 dólares." | "Antes: ligação, planilha, transferência manual. Agora: a avó fala, o pai decide, o neto recebe." |
| 6 | Condutor | "Ver como" → Marcos; voz ou texto: "Se algo acontecer comigo, o que acontece com meus dólares?" | `InfoListCard` "Mapa da família": Marcos · investimentos nos EUA US$ 600 mil · sem beneficiário (badge "Atenção"); Marcos · conta US$ 18 mil · beneficiária Helena; Helena · investimentos US$ 210 mil · beneficiário Marcos; Helena · conta US$ 9,5 mil · sem beneficiário. `SummaryKpiCard` "Estimativa educativa de estate tax": US$ 179.800, legenda "Sobre US$ 600 mil em ativos americanos, sem deduções. O beneficiário agiliza a transmissão; não reduz o imposto." `ActionChecklistCard` "Próximos passos para levar ao Rafael": indicar beneficiário nos investimentos; revisar titularidade; preparar o Pedro com acesso definido; conversar com o jurídico sobre estate tax | "A pergunta que tira o sono do Marcos. O código montou o mapa e a estimativa; a IA explica. E ela não sugere investimento: o próximo passo é com um especialista." |
| 7 | Condutor | Marca "indicar beneficiário nos investimentos" e "preparar o Pedro" → Confirmar | Texto: "Chamei o Rafael, nosso especialista, para esta conversa. Ele já recebeu a história da família." + "Por trás" | "O Marcos não troca de canal nem repete a história." |
| 8 | Pessoa no papel do Rafael | "Ver como" → Rafael; chip "Abrir caso da família Almeida"; envia: "Marcos, vi o mapa. Vamos começar pelo beneficiário dos investimentos. Amanhã às 10h te mostro como funciona, e você decide." | `InfoListCard` "Briefing da família Almeida" (gerado da conversa): pedido da Dona Lúcia aprovado; investimentos do Marcos sem beneficiário; passos escolhidos pelo Marcos | "O Rafael entra já sabendo a história: quem é quem, o que foi decidido e o que o Marcos quer fazer." |
| 9 | Condutor | "Ver como" → Marcos | Balão "Rafael · Especialista Avenue" com a mensagem, na mesma conversa | "Uma dupla, uma conversa, e quem decide é o cliente." |

## Preparação

- [ ] Banco no estado inicial: `curl -X POST http://localhost:8000/api/family/demo/reset` (ou `podman compose down -v` ou apagar `backend/data/app.db`).
- [ ] Servidores de `MCP_SERVERS` no ar (as tools rodam de verdade no replay): nenhum previsto.
- [ ] Gravação copiada para fora de `backend/data/` (`backend/demo/demo_recordings.json`) e `DEMO_RECORDINGS_PATH` apontando para ela.
- [ ] Emulador/aparelho com o app e `API_BASE_URL` certo; microfone testado; volume alto para a voz da Dona Lúcia.
- [ ] Vídeo de reserva (2-3 min) aberto.
- [ ] Pessoa no papel do Rafael com a mensagem da linha 8 copiada.
