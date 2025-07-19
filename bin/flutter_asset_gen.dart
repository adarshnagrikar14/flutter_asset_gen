import 'dart:io';
import 'package:flutter_asset_gen/flutter_asset_gen.dart';

void main(List<String> args) async {
  String? configPath;
  var verbose = false;
  var dryRun = false;

  for (final a in args) {
    if (a.startsWith('--config=')) {
      configPath = a.substring('--config='.length);
    } else if (a == '--verbose') {
      verbose = true;
    } else if (a == '--dry-run') {
      dryRun = true;
    } else if (a == '--help' || a == '-h') {
      stdout.writeln('Usage: dart run flutter_asset_gen [options]');
      stdout.writeln('  --config=FILE   Use custom config file');
      stdout.writeln('  --verbose       Verbose output');
      stdout.writeln('  --dry-run       Do not write file');
      exit(0);
    }
  }

  await generateAssets(
    configPath: configPath,
    verbose: verbose,
    dryRun: dryRun,
  );
}
