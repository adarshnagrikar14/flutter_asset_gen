import 'package:flutter_asset_gen/flutter_asset_gen.dart';

Future<void> main() async {
  // Run generation using the example's asset_gen.yaml
  await generateAssets(configPath: 'asset_gen.yaml', verbose: true);

  // After running, the file lib/assets.dart will exist. (In real use,
  // consumers run via CLI, not inside main()).
  print('Example generation complete.');
}
