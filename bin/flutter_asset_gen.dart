import 'dart:io';
import 'package:flutter_asset_gen/flutter_asset_gen.dart';

void main(List<String> args) async {
  String? configPath;
  var verbose = false;
  var dryRun = false;
  var watch = false;
  var validate = true;

  for (final a in args) {
    if (a.startsWith('--config=')) {
      configPath = a.substring('--config='.length);
    } else if (a == '--verbose') {
      verbose = true;
    } else if (a == '--dry-run') {
      dryRun = true;
    } else if (a == '--watch') {
      watch = true;
    } else if (a == '--no-validate') {
      validate = false;
    } else if (a == '--help' || a == '-h') {
      stdout.writeln('Usage: dart run flutter_asset_gen [options]');
      stdout.writeln('  --config=FILE   Use custom config file');
      stdout.writeln('  --verbose       Verbose output');
      stdout.writeln('  --dry-run       Do not write file');
      stdout
          .writeln('  --watch         Watch mode - regenerate on file changes');
      stdout.writeln('  --no-validate   Skip pubspec.yaml validation');
      stdout.writeln('  --help, -h      Show this help');
      exit(0);
    }
  }

  if (watch) {
    final config = loadConfig(configPath);
    final watcher = AssetWatcher(config);

    // Handle Ctrl+C gracefully
    ProcessSignal.sigint.watch().listen((_) async {
      await watcher.stop();
      exit(0);
    });

    await watcher.start();
  } else {
    var config = loadConfig(configPath);
    if (!validate) {
      config = config.copyWith(validatePubspec: false);
    }

    await generateAssets(
      config: config,
      verbose: verbose,
      dryRun: dryRun,
    );
  }
}
