---
name: boot-theme
description: Use quando precisar aplicar a identidade visual de um projeto (marca, cores, fonte, tom) ao app Flutter, a partir de um briefing de marca.
argument-hint: "<nome da marca> <tagline> <cores hex> [fonte] [tom]"
---

# /boot-theme

Aplica um briefing de marca ao app. Só mexe em `AppTokens.light` e `AppBrand`; nenhum widget muda.

## Entrada esperada

- Nome e tagline da marca.
- Cores hex: primária e, se houver, secundária e superfície.
- Fonte (opcional, nome do Google Fonts).
- Tom (opcional): vira a copy de `AppBrand` em pt-BR.

Se faltar a cor primária, pergunte antes de seguir.

## Passos

1. Derive a paleta a partir das cores do briefing. Cada par texto/fundo usado pelo tema precisa de contraste AA (4.5:1 para texto normal). Cores semânticas (`errorColor`, `successColor`, `warningColor`) ficam legíveis sobre `surfaceColor`.
2. Edite `mobile/lib/core/theme/app_tokens.dart`: só os valores de `AppTokens.light` (`primaryColor`, `secondaryColor`, `surfaceColor`, `errorColor`, `successColor`, `warningColor`). Não altere os campos, `copyWith` nem `lerp`.
3. Edite `mobile/lib/core/theme/app_brand.dart`: `AppBrand.name` e `AppBrand.tagline`.
4. Fonte custom (opcional):
   1. `cd mobile && fvm flutter pub add google_fonts`.
   2. Em `AppTokens.light`, ajuste `fontFamily` e o `textTheme` (via `GoogleFonts.<fonte>TextTheme(...)` ou `GoogleFonts.<fonte>().fontFamily`). Isso só pode acontecer em `lib/core/theme/`.
5. Não escreva cor, tamanho de fonte, `EdgeInsets` ou raio literal fora de `lib/core/theme/`. O teste `test/architecture/no_hardcoded_style_test.dart` falha se isso acontecer.
6. Se algum teste compara valores do tema antigo, atualize em `mobile/test/core/theme/app_theme_test.dart`.

## Verificação

```bash
cd mobile && fvm flutter analyze && fvm dart format --set-exit-if-changed lib test && fvm flutter test
```

## Pronto quando

- `AppTokens.light` e `AppBrand` refletem o briefing e os pares de cor passam AA.
- Nenhum arquivo fora de `mobile/lib/core/theme/` (e `pubspec.yaml`/`pubspec.lock` se houve fonte) mudou, exceto testes de tema.
- Analyze e testes passam.
