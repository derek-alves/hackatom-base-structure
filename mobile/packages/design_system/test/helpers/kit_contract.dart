import 'package:design_system/design_system.dart';
import 'package:design_system/src/build/build_tokens.dart';
import 'package:design_system/src/build/token_files.dart';

/// The kit contract (`tokens/contract/`) as build inputs, with an empty
/// mapping. Independent of the brand in `tokens/figma/`.
TokenInputs kitContractInputs() {
  final current = readTokenInputs('.');
  return TokenInputs(
    figmaFiles: {
      for (final MapEntry(:key, :value) in current.contractFiles.entries)
        '$key.tokens.json': value,
    },
    mappingYaml: '',
    contractFiles: current.contractFiles,
  );
}

TokenBuildResult buildKitContract() {
  final inputs = kitContractInputs();
  return buildTokens(
    figmaFiles: inputs.figmaFiles,
    mappingYaml: inputs.mappingYaml,
    contractFiles: inputs.contractFiles,
  );
}

/// Contract tokens for [mode] (`light` or `dark`).
TokenSet kitContractTokens([String mode = 'light']) =>
    TokenSet.fromResolvedJson(buildKitContract().resolved[mode]!);
