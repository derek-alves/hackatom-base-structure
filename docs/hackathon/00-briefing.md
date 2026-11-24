# Briefing do tema

Fonte: `docs/direcionamento/ideia-final/AI Hackathon Avenue 2026 - Abertura (1).pdf` (deck da abertura, 28 slides, 24/11). Onde este arquivo diverge da skill `/hackathon` ou de `fluxo-do-evento.md`, vale este arquivo.

Formato (slide 3): 2 dias de imersão no ambiente Google, 10 times multidisciplinares, 60 pessoas. Abertura: Leonardo Soares (AI & Data Science Lead). Pitch executivo "Ambição 2030 e o mandato deste hackathon": Henry Conceição (CTIO/CMO; o conteúdo não está no PDF). Enquadramento e ideação: Débora Lalo (Global Innovation and Transformation Lead, Google). AI Proxy + SDK: Lucas Braz (AI & Data Science).

## Tema

- Texto exato: "Diáspora patrimonial. Como a inteligência artificial contribui para o posicionamento da Avenue como plataforma de vida financeira global do brasileiro?"
- Ligação com a estratégia 2030 (o que o organizador disse): "O patrimônio do brasileiro está cruzando fronteiras." → "Quem cruza fronteiras precisa de apoio local para lidar com o offshore." → "Atender a essa demanda exige dar ao relacional a escala do transacional."
- Frentes sugeridas (o time elege 1 primária; interseções são bem-vindas):
  1. Novas linhas de receita e produtos globais: "Ofertas cross-border com monetização direta."
  2. Experiência do cliente e plataforma integral: "De corretora no exterior a hub financeiro diário do brasileiro."
  3. Eficiência de plataforma e escala operacional: "Crescer sem custo linear, na dupla jurisdição Brasil e EUA."
- Frente primária do time: 2 (experiência e plataforma integral), com interseção na 1 (Espaço Família, Avenue Legacy e Seguros como produtos novos).

## Critérios de avaliação

Os pesos oficiais substituem os provisórios de `.claude/skills/hackathon/references/rubrica.md`.

| Critério (texto oficial) | Peso | O que a banca disse que conta |
|---|---|---|
| Impacto no negócio e ambição estratégica | 40% | "O quanto a solução aproxima a Avenue da plataforma de vida financeira global." Avalia: C-level. |
| Funcionalidade, engenharia e viabilidade | 20% | "O que roda de verdade, a qualidade da arquitetura e o potencial de evolução até produção." Avaliam: lideranças de Engenharia, IT Services, AI & DS, Dados e Produto & Design. O time de apoio roda o código para testar. |
| Diferenciação e inovação | 20% | "O quanto a solução é inédita e o quanto a IA é o motor indispensável da entrega." Avaliam: C-level, lideranças técnicas e banca do Google Cloud. |
| Experiência do usuário | 20% | "Jornada clara e interação com a IA transparente e compreensível para quem usa." Avalia: liderança de Produto & Design. |

Cálculo (slide 23): cada jurado dá de 1 a 5 só nos critérios da sua cadeira; a nota do critério é a média simples dos jurados dele; a final é ponderada 40 · 20 · 20 · 20. Exemplo oficial: 4 × 40% + 5 × 20% + 3 × 20% + 4 × 20% = 4,0. Funcionalidade parte da Validação Técnica Assistida ("O time de apoio roda o código para testar minimamente a solução"). A banca delibera em espaço reservado. Empate: decide a liderança executiva.

Regras eliminatórias ("O descumprimento de quaisquer regras acima pode resultar na desclassificação do grupo."):

1. IA no core: "Generativa ou tradicional. Sem IA, está fora."
2. Execução ao vivo: "Solução rodando de ponta a ponta."
3. Sem recomendação de investimento: "Nem carteira, alocação ou ordens. Nem como exemplo."
4. Dados protegidos: "Nada de PII, saldos ou segredos reais."
5. Entrega no prazo: "Código entregue até as 12h do segundo dia (25/11), em .zip e/ou GitHub."

- Critério avaliado pelos jurados do Google: Diferenciação e inovação. Não há nota separada de stack Google; ADK e Gemini contam como engenharia.
- Definição de "protótipo funcionando": solução rodando de ponta a ponta, com live demo feita pelo time. A Validação Técnica roda o código em outra máquina: "Se não rodar, não tem como validar."

## Entregáveis e formato

- [ ] Formulário de envio: D1 às 17h, checkpoint com duas perguntas ("Qual problema a solução resolve e/ou qual oportunidade ela captura?" e "Qual é a arquitetura básica da solução?"; respostas prontas em `03-plano.md`). D2 a partir das 11h, formulário com código e deck.
- [ ] Zip / repositório: .zip e/ou GitHub, "com README de execução e de arquitetura"; dependências com versões fixas; `.env.example` sem segredos; container ou script único de setup.
- [ ] Vídeo: não pedido. Gravação da demo fica como plano B.
- [ ] Slides: até 5, em pptx ou PDF, nesta ordem: 1. Problema e oportunidade; 2. Solução e diferencial de IA; 3. Arquitetura e stack; 4. Impacto no negócio; 5. Roadmap pós-hackathon.
- [ ] Outros: pitch de 10 min com live demo pelo próprio time, D2 às 13h.

## Materiais e acessos

- Dores de clientes (material de produto): consolidado na ideia final (`docs/direcionamento/ideia-final/`), com dados do Databricks, da pesquisa "O Movimento Global" e da Pesquisa Avenue. Resumo em `01-ideia.md`.
- Datasets (onde, formato, tamanho, dicionário): nenhum dataset do evento. Salesforce e Insider via API, com chave distribuída pela organização (não usados).
- Proxy de IA (URL, formato `apigee`/`openai`, modelos): AI Proxy da Avenue (Apigee → Vertex AI), acessado pelo Proxy SDK (`ai-proxy-sdk`, `AvenueLLM(Model.X, is_adk=True)` no ADK). Chave por app no Dev Portal (`AI_PROXY_API_KEY`); sem URL para configurar; local exige rede corporativa ou VPN; cota de dev de 200 mil tokens/min por app e modelo; `gemini-3.5-flash` liberado na hora, demais modelos com aprovação. Passo a passo e encaixe no starter: [`docs/infra-ia/README.md`](../infra-ia/README.md).
- Servidores MCP ou APIs liberadas: nenhum servidor MCP anunciado.
- Projeto Google Cloud do time (permissões: service account, BigQuery, Cloud Run): opcional e sem peso na avaliação ("Pode rodar local").

## Restrições

- Dados: nada de PII, saldos ou segredos reais. Todo dado da demo é fictício e rotulado na tela. Números internos (Databricks) aparecem arredondados no slide.
- Produto: nenhuma tela, fala ou exemplo com carteira, alocação, ordem ou sugestão de ativo. Na ideia final, isso tira da demo a F8 (Carteira recomendada) e a T12 no formato "reserva 100% em ações".
- Modelos e stack: stack livre; modelos preferencialmente pelo AI Proxy; só bibliotecas com licença livre ou comercial; SaaS e APIs pagas só se homologadas pela Avenue. Mobile é opcional e não tem peso extra.
- Propriedade intelectual: não informado.

## Horários

- D1 (24/11), Google Faria Lima, sala Maracanã: 8h30 café; 9h15 abertura e revelação do desafio; 9h30 pitch executivo; 9h45 dinâmica e regras; 10h enquadramento e ideação (Google); 12h almoço (área comum do 18º andar); 13h demo do AI Proxy; 13h30 Construção I; 17h checkpoint (formulário de registro da solução); 18h encerramento oficial; construção opcional até 21h.
- D2 (25/11), Campus IPT/USP, Roca: 8h30 café; 9h15 Construção II; 11h abre o formulário de entrega; 12h fim da construção e prazo do código (eliminatório); 13h pitches e live demo; 15h deliberação; 16h premiação; 17h happy hour.
- Freeze: D2 às 11h.
- Envio: formulário do D2, das 11h às 12h.
- Ordem e tempo das apresentações: 10 min por time com live demo, a partir das 13h; ordem não informada.

## Mentorias

- Agendar pelo Bookings: https://avne.us/Hackaton. Slots de 20 min, com 10 min de intervalo entre agendas.
- Janelas: 24/11 das 13h30 às 17h (mesas reservadas da Maracanã); 25/11 das 9h30 às 11h (Foyer da Lua Grande).
- Áreas: AI & Data Science (Lucas Braz), Engenharia de SW (Martin Pfeifer), Dados (Victoria Reis), Produto (Felipe Cozer), Design (Armando Freire).
- Remoto em 24/11: Cloud (Bruno Pinheiro), Cybersegurança (Otavio Carmo), QA (Thamyres Moraes). Plantão remoto de IAM: Rafael Ramos.
- Mentores do Google e da SoftwareOne circulam entre as mesas.

## Premiação

- 1º lugar: "Discovery: entrada garantida em discovery, com time e prazo definidos".
- 2º e 3º: "Solução em backlog".
- Prêmios exclusivos Google.

## Time

- Time 3, mesa 3, 5 pessoas: Thyago Rebelato, Derek Alves, Vinicius Yamaguti, Jenny Nascimento, Karine Narumi.
- Primeiro passo (slide 13): eleger líder e postar no grupo do Slack do hackathon uma mensagem por time: "GRUPO 3: <NOME DO(A) LIDER>".
- Papéis sugeridos: Back-end, Front-end, Produto, Design. "Nem todo time tem todos os papéis: pessoas de outras especialidades podem assumir as funções." "Apresentar a solução como mobile não é requisito e não tem peso diferente na avaliação."
- Divisão de papéis do time (`03-plano.md`): Mobile/Backend: Derek e Leonardo (os dois nas duas camadas); Produto: Jenny, Karine, Leonardo e Thyago; Design: Karine; IA: Vinicius. O Leonardo do time não é o Leonardo Soares da organização e não está na lista do deck.

## Diferenças em relação à skill e ao starter

1. Impacto no negócio vale 40% e domina a nota; engenharia vale 20%, não os 30-50% da pesquisa da skill. Pitch precisa de número e premissa ligando a solução à "plataforma de vida financeira global".
2. Os jurados do Google avaliam Diferenciação e inovação; não há nota de stack Google.
3. Regra eliminatória específica: sem recomendação de investimento, nem como exemplo de tela. A `banca-simulada` aplica como filtro.
4. Live demo é eliminatória: a demo roda ao vivo pelo AI Proxy; `DEMO_MODE=replay` e vídeo ficam como plano B (pergunta 3).
5. Checkpoint às 17h (formulário), não às 17h30. Formulário do D2 abre às 11h; código fecha às 12h.
6. No máximo 5 slides, na ordem oficial; a demo acontece fora dos slides.
7. A Validação Técnica roda o código noutra máquina: backend com `podman compose up --build`, APK pronto e README com passo a passo. O app Flutter só tem `android/` e `ios/`.
8. O deck lista 5 pessoas no Time 3; com o Leonardo, o time tem 6. O plano tem uma coluna por pessoa.
9. Sem dataset do evento: a dor sai dos dados citados na ideia final e de dado público (IRS, legislação); dados da demo são fictícios.

## Perguntas para organizador e mentores

1. (Organização) A máquina da Validação Técnica tem Podman ou Docker, Flutter e emulador Android? Aceitam APK?
2. (AI & DS, Lucas Braz) O AI Proxy funciona na rede do IPT/USP sem VPN? A máquina da Validação Técnica tem acesso à org `avenuesec` (para instalar o SDK) e à rede do proxy, ou ela roda só o modo replay?
3. (Organização) Se o proxy cair na apresentação, a demo pode usar respostas gravadas (`DEMO_MODE=replay`) desde que o time avise?
4. (Produto) Mostrar patrimônio fictício por membro (só total, sem ativos) e uma estimativa educativa de estate tax encosta na regra 3?
5. (Organização) Os números internos do Databricks (14,7 mil clientes, 36% do AUC) podem aparecer no slide, arredondados?
