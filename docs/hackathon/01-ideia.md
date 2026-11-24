# Agente Familiar Avenue: cuidando da sua família, seu maior patrimônio

**Tese:** Ao reunir a família num Espaço Família, com um Agente Familiar de IA (voz ou texto) e um Agente Especialista humano na mesma conversa, para clientes Avenue acima de US$ 50 mil, no momento em que um membro pede para mover dinheiro ou o titular pergunta "se algo acontecer comigo, o que acontece com meus dólares?", esperamos que a família resolva tudo num lugar só, com o owner decidindo, e que a Avenue retenha o patrimônio na troca de geração e ative banking e novos membros.

**Leitura:** problema → evidência → público → resultados → solução → proteção → métricas → evolução. O que não foi demonstrado fica marcado como hipótese ou pendência.

Fonte única da ideia: `docs/direcionamento/ideia-final/Contexto do Agente Familiar (1).html` (junta o deck Legado Avenue, o pitch HTML do Agente Familiar, as anotações do time e os dados de "O Movimento Global"). Nomes, saldos e conversas são fictícios; só os números com fonte são reais. "(suposição)" = o time ainda não confirmou. "(sugestão)" = proposta para fechar uma lacuna.

Posicionamento: "Onde eu guardo meus dólares" → "Quem cuida do meu patrimônio comigo" → "Quem cuida da minha família, hoje e depois de mim".

## Quadro de produto

| Etapa | Definição | Evidência, entrega ou pendência |
|---|---|---|
| 01 · Problema | O dinheiro da família está espalhado ("em cinco telas e numa planilha"), ninguém sabe o que acontece com os dólares se o titular faltar, o IR de todos é refeito todo ano e os mais velhos não conseguem usar o app. | Quatro dores das anotações do time: centralização, sucessão, falta de tempo, acessibilidade. 70% dos herdeiros trocam de instituição financeira logo após a herança (JP Morgan, citado no deck do time; conferir a publicação). |
| 02 · Oportunidade de negócio | Reter o AUC na transferência de geração, ativar o banking ocioso e crescer pela família (cada membro convidado é uma conta). | 14,7 mil clientes acima de US$ 50 mil sem usar Banking, com 36% do AUC (Databricks, interno). 23% da base chegou por indicação da própria família (Pesquisa Avenue). Baseline a levantar: AUC que sai por ano em eventos de sucessão. |
| 03 · Dados de mercado | Por que o brasileiro investe fora: proteção do real 89%, potencial de ganho 36%, legado familiar 18%, morar fora 7% (múltipla escolha). Ponto forte da Avenue: investimento + conta + cartão 46%, diversificação 42%. | "O Movimento Global", Tribo Investimentos 2026. Estate tax de não residente: alíquotas de 18% a 40% sobre ativos americanos, com crédito unificado de US$ 13 mil, que equivale a isentar os primeiros US$ 60 mil (IRS, Form 706-NA, tabela §2001(c)). |
| 04 · Público e segmento | Clientes Avenue acima de US$ 50 mil (Advance, Singular, Private) com família: cônjuge, filhos e pais. Porta de entrada: os 14,7 mil sem Banking. | Pendência: quantos têm dependentes ou cartão de dependente (dado do produto). |
| 05 · Persona | Família Almeida (fictícia). Owners: Marcos, 52, titular, US$ 618 mil na Avenue (US$ 600 mil em ativos americanos), usa app e voz no carro; Helena, 49, cônjuge, US$ 219,5 mil. Membros: Pedro, 24, em Boston, cofrinho US$ 1.840; Ana, 16, dependente com cartão e mesada de US$ 150; Dona Lúcia, 78, mãe do Marcos, US$ 35 mil, usa só voz. Especialista: Rafael. | Fictícia, rotulada na tela. Valores em `06-dados.md`. Pendência: calibrar com o perfil típico do segmento (Databricks, agregado). |
| 06 · Momento / gatilho | Um membro pede algo por voz ou texto (Dona Lúcia quer mandar US$ 200 de aniversário ao neto) ou o owner pergunta sobre sucessão ("Se algo acontecer comigo, o que acontece com meus dólares?"). | Demo: cenas 1 e 3 de `05-demo.md`. |
| 07 · Decisão que o agente ajuda | O owner aprova ou recusa a movimentação que outro membro pediu, vendo valor, limite e impacto por membro. O owner escolhe, numa lista fechada, o próximo passo da sucessão para levar ao especialista (indicar beneficiário POD, revisar titularidade, agendar com o jurídico). | |
| 08 · Resultados para o cliente | A família resolve num lugar só; a Dona Lúcia usa por voz sem depender de ninguém; o Marcos aprova em um toque; o Pedro herda o conhecimento e encontra tudo encaminhado; ninguém repete a história ao especialista. | Medir: tempo do pedido à aprovação; % de pedidos por voz resolvidos sem contato humano; NPS da família. |
| 09 · Resultados para o negócio | AUC retido na sucessão; banking ativado; contas novas por convite; especialista atende com o contexto pronto (menos tempo por caso, mais famílias por especialista). | Medir: AUC de famílias ativas vs. controle; membros ativos por família; tempo de atendimento do especialista. |
| 10 · Proposta de valor | "Quem cuida da minha família, hoje e depois de mim." Os bancos guardam o dinheiro; a Avenue guarda também a história da família que vem com ele. | |
| 11 · Diferencial ("fora da caixa") | (1) A unidade é a família, com owners, papéis e permissões, não a conta. (2) A voz põe o idoso para dentro, e a aprovação fica no app do owner. (3) A dupla IA + especialista humano na mesma conversa, com a história da família: o cliente não troca de canal nem repete nada. (4) Sucessão cross-border preparada antes do evento, com os herdeiros já dentro. | Contas globais (Nomad, Wise, Inter Global) e agregadores tratam a conta individual. Comparação a validar com Produto. |
| 12 · IA core | Generativa: entende a fala informal de cada membro, resolve parentesco no grafo da família ("meu neto" → Pedro), extrai valor e motivo, pergunta o que falta, transforma regra em linguagem natural em regra estruturada (mesada, P1), explica no nível de cada membro e escreve o briefing do especialista a partir da história da família. Um card "Por trás", montado em código a partir das tool calls do turno, mostra em cada cena o que a IA entendeu e o que o código calculou. Sem IA, o que quebra: a Dona Lúcia fica de fora, a regra da mesada vira formulário e o especialista começa do zero. | ML tradicional fica no roadmap (P2): a banca mostrou que um detector sem cena na demo vira peso, não nota. |
| 13 · Motor determinístico | Patrimônio consolidado por membro, filtrado pela permissão de quem pergunta; saldo, limite e frequência definidos pelo owner; transferência só para contas e cofrinhos da família; estimativa educativa de estate tax; mapa de sucessão por titular (beneficiário POD, titular único); lista fechada de próximos passos; ritmo do cofrinho contra a meta (P1). | `backend/app/modules/family/service.py`, testes em `backend/tests/modules/family/`. Caso fixo: US$ 600 mil → tabela US$ 192,8 mil − crédito US$ 13 mil = **US$ 179,8 mil**. |
| 14 · Papel do LLM | Entender, resolver quem é quem, perguntar o que falta, explicar no tom de cada membro, redigir mensagem para outro membro e o briefing do especialista. Nunca calcula, nunca aprova, nunca vê dado que o papel não libera. | Contrato em `02-arquitetura.md`. |
| 15 · Ação com confirmação | O owner aprova no app (card com valor, limite restante e impacto, valores sobrescritos pelo código com a pendência do banco; biometria em produção, PIN no protótipo se sobrar tempo). O código executa e registra o consentimento: quem pediu, canal, texto mostrado, quem decidiu e quando. A voz nunca aprova sozinha. Mudança de beneficiário ou titularidade exige dupla aprovação (P2). | Nó de código no workflow, sem LLM. |
| 16 · Guardrails | Números só de tool; permissões aplicadas no código; sem recomendação de investimento, carteira, alocação ou ordem (regra 3): filtro de saída bloqueia nome de ativo, "ETF", "alocação", "realocar", e "como pago menos imposto?" vai para o especialista; card de sucessão diz "O POD agiliza a transmissão; não reduz o imposto"; texto de estate tax marcado "estimativa educativa", versão final pelo Jurídico; destino de transferência só dentro da família; limites por valor e frequência; pedido incomum de idoso vai ao owner com alerta; consentimento por membro (LGPD), revogável; trilha de auditoria por membro. | Testes de ataque em `02-arquitetura.md`, seção 10. |
| 17 · Métrica principal | Famílias ativas = clientes acima de US$ 50 mil com 2 ou mais membros ativos no Espaço Família em 30 dias ÷ clientes acima de US$ 50 mil. | Baseline 0 (produto novo). Meta do piloto: 10% dos 14,7 mil em 6 meses (premissa). Resultado de negócio: AUC retido (abaixo). |
| 18 · Métricas de apoio | Membros por família; % de pedidos por voz resolvidos sem humano; tempo do pedido à aprovação; encaminhamentos ao especialista com briefing e tempo de atendimento; bloqueios do guardrail; custo por jornada em tokens. | |
| 19 · Escopo do MVP | Uma família (Almeida), uma história com 3 cenas: pedido por voz da Dona Lúcia → aprovação do Marcos → sucessão com o Rafael na mesma conversa. | `05-demo.md`. |
| 20 · Evolução | Piloto com famílias Singular e Private que já têm cartão de dependente → Espaço Família para todo o segmento acima de US$ 50 mil → integração com CX Agent AI (voz), pit-mcp (consentimento por membro), Salesforce (especialista), MyProfit (IR da família) e Seguros. | Gates: consentimento por membro aprovado pelo Jurídico e LGPD; adoção de 2+ membros por família. |

### Impacto estimado (premissa explícita, para o slide 4)

`AUC retido por ano = N × p × AUC médio × (s_sem − s_com)`

| Termo | Valor | Fonte |
|---|---|---|
| N | 14.700 clientes acima de US$ 50 mil sem Banking | Databricks (interno; no slide, "~15 mil") |
| p | 1% ao ano com evento sucessório | Premissa: ordem de grandeza da mortalidade anual entre 50 e 60 anos (tábua IBGE, conferir) |
| AUC médio | US$ 250 mil | Premissa; trocar pelo dado do Databricks |
| s_sem | 70% dos herdeiros trocam de instituição | JP Morgan (citado pelo time) |
| s_com | 40% com Espaço Família ativo | Premissa: herdeiro já convidado, com conta e conhecimento |

Resultado: 14.700 × 1% × US$ 250 mil × 30% ≈ **US$ 11 milhões de AUC retido por ano**, sem contar banking ativado e contas novas por convite. Sensibilidade: cada 10 p.p. de herdeiros retidos ≈ US$ 3,7 milhões por ano.

Leitura para o C-level:
- **AUC em risco por ano:** sem nada, 14.700 × 1% × US$ 250 mil × 70% ≈ US$ 25,7 milhões saem só desse grupo.
- **O ganho acumula:** o AUC retido fica na casa. Em 10 anos, são cerca de US$ 110 milhões retidos, sem contar a valorização.
- **N é conservador:** usa só os clientes sem Banking. A base inteira acima de US$ 50 mil multiplica o número; o tamanho dela é dado a levantar.
- **O patrimônio em jogo é maior:** 36% do AUC está nesse segmento.

## Escopo

- **P0 (a demo depende disso):**
  - Dados fictícios da Família Almeida (seed rotulada), com os papéis e permissões da ideia final.
  - Motor: permissões, saldo e limite, transferência para cofrinho, pedido pendente, aprovação, registro de consentimento, estimativa educativa de estate tax, mapa de sucessão por titular, lista fechada de próximos passos.
  - Tools do agente que usam o membro da sessão (nunca um parâmetro escolhido pelo LLM).
  - Um app só, com seletor "Ver como" (Dona Lúcia, Marcos, Rafael) sobre a mesma conversa da família no SQLite, marcado como recurso de demo.
  - Voz na cena da Dona Lúcia: reconhecimento de fala no aparelho, resposta lida em voz alta e alternativa em texto.
  - Aprovação no app do Marcos (`ApprovalConfirmationCard`) executada por código.
  - Card "Por trás" em cada cena, montado em código a partir das tool calls: "IA entendeu" e "Código calculou".
  - Gravação com `DEMO_MODE=record` de cada cena assim que ela rodar (cenas 1 e 2 no D1); chips com frase única por membro.
  - Sucessão: mapa da família, estimativa educativa, próximos passos em lista fechada e handoff ao Rafael com briefing; o Rafael responde na mesma conversa (fala roteirizada na demo).
  - Guardrail de números e da regra 3, com testes e bateria de avaliação.
- **P1 (se der tempo):**
  - Espaço Família (T1) como tela com cards por membro e decisões pendentes.
  - Áudio da Dona Lúcia direto ao Gemini (multimodal nativo): o Proxy SDK aceita áudio (`docs/infra-ia/README.md`); o reconhecimento no aparelho fica como reserva.
  - Mesada com regra em linguagem natural e mensagem para a Ana (T8).
  - Coerência com o plano (T12 reformulada, sem investimento): ritmo do cofrinho do intercâmbio contra a meta.
  - PIN na aprovação, checado no servidor (biometria com `local_auth` só no aparelho); convite de membro (T2, T3); marca Avenue no tema (`/boot-theme`).
- **P2 (só no slide de roadmap):** evolução patrimonial (T4) e Retrospectiva do ano (T5); despesas do casal (T6); rendimento para o filho (T7); IR da família com MyProfit (F13); cofrinhos e P2P entre membros como produto (F14); Seguros (F16); detector de anomalia nos gastos do cartão de dependente (ML com baseline de regra); integração com pit-mcp, CX Agent AI e Salesforce; carteira recomendada pelo especialista certificado, só em produção (F8).
- **Não-objetivos:** dinheiro de verdade; cálculo real de imposto; texto jurídico final; conta nova para menores; qualquer recomendação, carteira, alocação, ordem ou comentário sobre composição de investimentos (regra 3); dado real de cliente.

## Ideias avaliadas

Fórmula: `[persona com números] + [gatilho] + [decisão] + [ML tradicional] + [LLM] + [ação que o cliente confirma]`. Nota pelos pesos oficiais (Impacto 40% · Funcionalidade 20% · Diferenciação 20% · UX 20%), na ordem I/F/D/U.

A ideia final nasceu da ideação do D1: o time fundiu o Check-up Família Global (gestão acima de US$ 50 mil), o Avenue Hub 360 (Espaço Família) e o deck Legado Avenue no Agente Familiar. As versões anteriores ficam no histórico do git.

| # | Ideia (fórmula da skill) | Filtros | Nota | Observação |
|---|---|---|---|---|
| Final | **Agente Familiar Avenue.** Família Almeida (fictícia; Marcos, 52, US$ 600 mil em ativos americanos; segmento de 14,7 mil clientes acima de US$ 50 mil sem Banking, 36% do AUC) + pedido de um membro por voz ou pergunta de sucessão do owner + owner aprova a movimentação ou escolhe o próximo passo da sucessão + (ML tradicional no roadmap) + LLM entende a fala de cada membro, resolve parentesco, explica por membro e escreve o briefing do especialista + owner aprova no app, o código executa e registra, o especialista entra na mesma conversa | Passa nos 4 filtros da rubrica e nas 5 eliminatórias, com dois cortes da regra 3: F8 (Carteira recomendada) sai da demo e a T12 deixa de falar de "100% em ações" e passa a falar do ritmo do cofrinho. Não é commodity: nenhuma conta global trata a família como unidade, com voz e especialista na mesma conversa | Time antes da banca: 4,2 (4/4/5/4). Time depois dos ajustes: 4,0 (4/4/4/4) | Maior risco: escopo de 16 funcionalidades e 13 telas. Corte: uma história com 3 cenas (P0 acima) |

Divergências da ideia final ainda abertas, com a decisão adotada aqui (suposição até o time confirmar):

| # | Tema | Decisão adotada |
|---|---|---|
| D1 | Produto para menores | Cartão de dependente, que já existe; conta nova para menores vai para o roadmap |
| D2 | Regra do cartão de dependente (13-17 anos e até 4 cartões, ou 12-18 anos e 1 cartão) | Validar com Produto; a Ana de 16 anos cabe nas duas |
| D3 | "Separar contas" do casal | Contas individuais com orçamento comum (P2) |
| D4 | 49,5% de paridade Invest-Banking e −40% de contatos | Fora do pitch até ter fonte |
| D5 | "Demo 10/12" | É a demo do pit-mcp, não do hackathon; roadmap sem data |
| D6 | Cofrinhos e P2P "já existem" | Confirmar com Produto; no protótipo são simulados |
| D7 | Número da UBS (Brasil em 2º, US$ 9 trilhões) | Fora do deck até confirmar o que mede |

## Parecer da banca simulada

Avaliação de 24/11, ~17h, sobre o texto reescrito da ideia (sem as notas do time), com os pesos oficiais.

| | Impacto (40%) | Funcionalidade (20%) | Diferenciação (20%) | UX (20%) | Final | Google |
|---|---|---|---|---|---|---|
| Banca | 4 | 3 | 3 | 4 | **3,6** | 3 |
| Time, antes da banca | 4 | 4 | 5 | 4 | 4,2 | — |
| Divergência > 1 | não | não | **sim (2 pontos)** | não | | |

Filtros: passa nos cinco eliminatórios, com alertas na regra 3 (cena 3), na regra 4 (números do Databricks; pergunta 5 do briefing) e na regra 2 (voz e biometria na máquina da Validação Técnica).

**Discussão do time (Diferenciação, 5 × 3):** para a banca, as peças já existem na Avenue e quem decide (aprovação, limite, estate tax, permissão) é código, então a IA parece interface; com a voz reconhecida no aparelho, o Gemini some do momento multimodal. Resposta adotada: card "Por trás" em cada cena, briefing do Rafael gerado da história da família e áudio direto ao Gemini em P1.

Riscos e correção mais barata (todas adotadas no escopo acima):

1. **Cena 3 encosta na regra 3 e mistura POD com imposto.** Depois do valor do imposto, a pergunta natural é "como pago menos?", e a resposta de mercado é mexer nos ativos. O POD evita o inventário nos EUA, não reduz o estate tax. A conta certa é imposto da tabela sobre US$ 600 mil (US$ 192,8 mil) menos o crédito de US$ 13 mil, que já é a isenção de US$ 60 mil; não se desconta duas vezes. Correção: lista fechada de próximos passos no código, fala do Rafael roteirizada, filtro de saída para nome de ativo, "ETF", "alocação" e "realocar", card "O POD agiliza a transmissão; não reduz o imposto", teste que fixa 179.800.
2. **Escopo pode não rodar na máquina da Validação Técnica** (voz, dois aparelhos com biometria, humano em tempo real, ML sem cena). Correção: um app com seletor de perfil sobre a mesma conversa no SQLite, voz com alternativa em texto, PIN no emulador, ML para o roadmap, gravação com `DEMO_MODE=record`.
3. **A IA pode parecer só interface** (tirando a voz, tudo funciona com botões). Correção: card "Por trás" em cada cena ("IA entendeu: meu neto → Pedro, US$ 200, presente"; "Código calculou: saldo, limite restante, impacto") e o briefing do Rafael gerado da história da família.

Perguntas prováveis da banca (respostas em `04-pitch.md`):

1. (C-level) "Qual número muda se isso for ao ar: Banking ativado entre os 14,7 mil, AUC retido na sucessão ou famílias indicadas? Quanto isso vale em US$?"
2. (Google) "Se eu tirar o Gemini, o que quebra? Aprovação, limite, estate tax e permissão são código."
3. (Produto e Jurídico) "O Marcos pergunta 'como eu pago menos estate tax?'. O que o agente e o Rafael respondem sem recomendar ativo? E o POD reduz o imposto?"
4. (Engenharia e Segurança) "Como vocês sabem que quem fala é a Dona Lúcia? O que impede alguém de pedir uma transferência por voz em nome dela, ou para alguém de fora da família?"
5. (C-level e Operações) "O Rafael entra em tempo real? Quantas famílias um especialista atende, e como isso escala sem custo linear?"

O que falta frente aos campeões, segundo a banca: persona que nasce do dado (a Família Almeida é inventada; calibrar com o agregado do segmento), um único momento de decisão, guardrail que confere os números do texto contra as tools, testes sem rede visíveis e Gemini no momento multimodal.

#### 2ª rodada: ideia + arquitetura (24/11, ~17h30)

A banca leu `01-ideia.md`, `02-arquitetura.md`, `06-dados.md` e `03-plano.md`, conferiu as premissas no código do starter e ignorou as notas do time.

| | Impacto (40%) | Funcionalidade (20%) | Diferenciação (20%) | UX (20%) | Final | Google |
|---|---|---|---|---|---|---|
| Banca, 2ª rodada | 4 | 3 | 3 | 4 | **3,6** | 3 |

Veredito: a arquitetura sustenta a demo de 3 cenas até 11h do D2, desde que o time corrija 2 furos de contrato e 1 de cronograma antes das 21h do D1. Funcionalidade fica em 3 porque o módulo `family` ainda não existe. Diferenciação fica em 3 porque, com a voz reconhecida no aparelho e o parentesco resolvido no grafo, o Gemini fica sem momento multimodal; consolidação familiar e sucessão com IA já existem para assessores nos EUA (Wealth.com, Vanilla, Addepar). O que segue em aberto: perguntas 3 (replay vale como live?) e 5 (Databricks no slide) do briefing.

Furos e correção adotada (todas em `02-arquitetura.md` e `03-plano.md`):

1. **Guardrail furado.** Com o proxy, o ADK entrega a resposta final pela tool `set_model_response`, que passa pelo `after_tool_callback` e liberaria todos os números. O briefing gravado por tool escapava do filtro. Havia falsos positivos ("200" da fala, "179,8 mil" × 179800, "ativos americanos", regex de ticker). Correção: `check_output(text, allowed)` único na resposta e no briefing; o callback ignora `set_model_response`; `allowed` inclui os números do turno do usuário, normalizados; lista bloqueada com UCITS, irlandês, trust, holding, estrutura offshore e seguro de vida.
2. **"Por trás" não cabia no contrato.** O `UiResponse` aceita um `InfoListCard` por turno. Correção: o `render_a2ui` monta o "Por trás" em código a partir das tool calls (argumentos e `explain`) e sobrescreve valor e limite do card de aprovação com a pendência do banco.
3. **Cronograma e replay.** O `userId` está fixo em `'mobile-user'` no core do mobile. O `turn_key` do replay ignora o `userId`, e a gravação só às 11h não deixava plano B. Correção: `userId` por membro; chips com frase única por membro; gravar as cenas 1 e 2 às 21h do D1 e a cena 3 assim que rodar; no D2, cena 3 com guardrail antes do polling; PIN só se sobrar tempo.

Furos menores corrigidos: um caminho só na cena 3 (o handler de `checklist_submitted` cria o caso; o agente só escreve o briefing); tool nova `get_family_timeline` para o briefing ter a história da família; texto injetado pelo handler sem timestamp; módulo `family` inteiro fora do `/mcp`; leitura do impacto com AUC em risco, acumulado em 10 anos e N conservador.

O que o time mudou na 1ª rodada: card "Por trás" em cada cena; um app com seletor de perfil (o Rafael também) em vez de dois aparelhos; PIN no emulador; ML tradicional para o roadmap; lista fechada de próximos passos e filtro de saída da regra 3; conta do estate tax corrigida e fixada em teste; destino de transferência só dentro da família; áudio direto ao Gemini em P1.
