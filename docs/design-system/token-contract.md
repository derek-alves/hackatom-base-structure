# Contrato de tokens do design system

Para designers. Define como nomear as variáveis do Figma para que o app aplique a marca do projeto só trocando dados (tokens, `mapping.yaml`, fontes e `AppBrand`), sem editar widget.

Se o seu Figma não segue estes nomes, não tem problema: a IA (`/boot-theme`) preenche `tokens/mapping.yaml` ligando seus nomes aos do contrato. Seguir o contrato só evita esse passo.

## Formato

- W3C DTCG 2025.10: `$value`, `$type`, aliases `{grupo.token}`.
- No Figma, os grupos são separados por `/` (ex.: `color/on-primary`). No JSON, viram aninhamento.
- Cores aceitam hex (`#9ECAFF`) ou objeto DTCG (`colorSpace`/`components`/`alpha`/`hex`).
- Aliases para primitivos (ex.: `palette/blue/500`) são resolvidos no build, inclusive entre arquivos.

## Modos e arquivos

- `light` é obrigatório. `dark` é opcional: sem ele o app só tem tema claro.
- Um arquivo por coleção e modo, como no export nativo do Figma (ex.: `Colors.Light.tokens.json`, `Colors.Dark.tokens.json`, `Spacing.Mode 1.tokens.json`). Os arquivos vão em `mobile/packages/design_system/tokens/figma/`.
- O modo vem do nome do arquivo:
  - Nome com `dark` ou `escuro` (qualquer caixa) é o modo dark. Ex.: `Colors.Dark.tokens.json`, `Colors.Escuro.tokens.json`.
  - Qualquer outro nome é light. Ex.: `Colors.Light.tokens.json`, `Colors.Claro.tokens.json`, `Spacing.Mode 1.tokens.json`.
  - Se o modo escuro tiver outro nome (ex.: `Noite`), renomeie o arquivo antes do build.
- O dark herda do light o que não definir.
- Um token só pode aparecer em um arquivo de cada modo. Se o mesmo nome estiver em dois arquivos do mesmo modo, o build falha citando o token e os dois arquivos. Isso acontece quando a amostra do kit (`light.tokens.json` e `dark.tokens.json`) fica ao lado do export do projeto: apague a amostra.

## Tokens

| Grupo | Tokens | Obrigatório? | Se faltar |
|---|---|---|---|
| `color` (núcleo) | `primary`, `on-primary`, `secondary`, `on-secondary`, `error`, `on-error`, `surface`, `on-surface`, `outline` | Sim | O build falha listando os nomes, salvo se estiverem em `defaults` do `mapping.yaml` |
| `color` (demais papéis M3) | `primary-container`, `on-primary-container`, `secondary-container`, `on-secondary-container`, `tertiary`, `on-tertiary`, `tertiary-container`, `on-tertiary-container`, `error-container`, `on-error-container`, `on-surface-variant`, `surface-container-lowest`, `-low`, `surface-container`, `-high`, `-highest`, `outline-variant`, `inverse-surface`, `on-inverse-surface`, `inverse-primary`, `scrim`, `shadow` | Não | Derivado por `ColorScheme.fromSeed` a partir de `primary` |
| `color` (extensão) | `success`, `on-success`, `warning`, `on-warning`, `info`, `on-info` | Não | Valor padrão do kit |
| `color` (skeleton) | `skeleton-base`, `skeleton-highlight` | Não | Derivado de `surface-container-highest` / `surface-container-low` |
| `spacing` | `xs` 4, `sm` 8, `md` 16, `lg` 24, `xl` 32 | Não | Valor padrão do kit (o indicado) |
| `radius` | `sm` 8, `md` 12, `lg` 20, `full` 999 | Não | Valor padrão do kit |
| `size` | `control-sm` 32, `control-md` 40, `control-lg` 48 (altura de botão, campo e chip) | Não | Valor padrão do kit |
| `type` | `family` e a escala M3: `display`, `headline`, `title`, `body`, `label`, cada um em `lg`/`md`/`sm`, com `size`, `line-height`, `weight`, `letter-spacing` | `family` sim | A escala usa o padrão M3 |

Nomes de cor seguem os papéis do Material 3. Valores de dimensão em px. `weight` é número (400, 500, 600...). Todo valor derivado ou herdado do padrão aparece no relatório do `build_tokens`; o relatório também lista o que veio do Figma e não está no contrato (ignorado) e avisa sobre contraste abaixo de 4.5:1 (WCAG AA) nos pares `on-*`. O aviso não falha o build.

### Tipografia como variáveis

O export nativo do Figma não leva text styles. Por isso a tipografia é definida como variáveis, uma por propriedade e estilo:

```text
type/family                    (string)  ex.: "Inter"; "system" usa a fonte da plataforma
type/title-lg/size             (number)  22
type/title-lg/line-height      (number)  28
type/title-lg/weight           (number)  600
type/title-lg/letter-spacing   (number)  0
```

O build também aceita o token composto `typography` que o plugin TokensBrücke exporta, em vez das quatro variáveis.

Fonte própria: entregue os arquivos de fonte; a IA os coloca em `mobile/packages/design_system/fonts/` e declara no `pubspec.yaml` do pacote. O valor de `type/family` é o nome da família declarado ali.

## Como exportar do Figma

Duas opções; o pipeline aceita as duas.

1. Export nativo de variáveis ("Export variables" do modal de variáveis, quando disponível no seu plano e versão do Figma). Gera um JSON por coleção e modo.
2. Plugin TokensBrücke, que exporta DTCG e também o composto `typography`.

Salve os arquivos em `mobile/packages/design_system/tokens/figma/` e rode `/boot-theme` (ou `fvm dart run design_system:build_tokens` no diretório do pacote).

Observação: o MCP do Figma (`get_variable_defs`) só traz o modo padrão e a seleção atual. Para ter light e dark, exporte os arquivos.

## Como começar do contrato do kit

O padrão do kit está em `mobile/packages/design_system/tokens/contract/` (`light.tokens.json` e `dark.tokens.json`). Copie esses arquivos como base e troque os valores. Eles têm todos os nomes obrigatórios e os papéis opcionais que o kit define.

## Importar no Figma

Status: **a validar no primeiro projeto.** Não foi possível testar o import no Figma durante a construção do kit.

O que se sabe, e o que não:

- O guia oficial de variáveis do Figma (`help.figma.com`, "Guide to variables in Figma") não descreve import ou export de variáveis em JSON/DTCG nem cita nomes de menu. Não vamos inventar os passos aqui.
- O mesmo guia cita um plugin de exemplo da comunidade que importa e exporta variáveis via a plugin API; ele não define o formato.
- Caminho prático a testar no primeiro projeto: abrir o modal de variáveis do arquivo e procurar a opção nativa de importar variáveis a partir de JSON; se não houver ou não aceitar os arquivos de `tokens/contract/`, usar o plugin TokensBrücke (que lê e escreve DTCG) ou recriar as variáveis à mão com os nomes da tabela acima.

Quem validar: registre aqui o caminho que funcionou (menu ou plugin, versão do Figma, plano) e tire a marca "a validar".
