import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:glob/glob.dart';
import 'config.dart';
import 'utils.dart';
import 'hashing.dart';

class GenerationResult {
  final int count;
  final bool skipped;
  final List<String> warnings;
  GenerationResult(this.count, this.skipped, this.warnings);
}

Future<GenerationResult> generateAssets({
  AssetGenConfig? config,
  String? configPath,
  bool dryRun = false,
  bool verbose = false,
}) async {
  final cfg = config ?? loadConfig(configPath);
  final excludeGlobs = cfg.exclude.map((e) => Glob(e)).toList();
  final warnings = <String>[];

  final entries = <_E>[];

  for (final root in cfg.roots) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    for (final ent in dir.listSync(recursive: true)) {
      if (ent is! File) continue;
      final rel = p.relative(ent.path, from: root).replaceAll('\\', '/');
      if (rel.endsWith('/')) continue;
      final full = '${root.replaceAll('\\', '/')}/$rel';

      if (excludeGlobs.any((g) => g.matches(full))) continue;

      if (cfg.includeExtensions != null) {
        final ext = p.extension(rel).toLowerCase();
        if (!cfg.includeExtensions!.contains(ext)) continue;
      }

      final id =
          buildIdentifier(rel, caseStyle: cfg.namingCase, prefix: cfg.prefix);

      entries.add(_E(root: root, rel: rel, id: id));
    }
  }

  // Deduplicate
  final used = <String, int>{};
  for (var i = 0; i < entries.length; i++) {
    final e = entries[i];
    if (used.containsKey(e.id)) {
      final base = e.id;
      var n = used[base]! + 2;
      var cand = '$base$n';
      while (used.containsKey(cand)) {
        n++;
        cand = '$base$n';
      }
      warnings.add('Duplicate "$base" for ${e.rel} -> $cand');
      entries[i] = e.copy(id: cand);
      used[cand] = 1;
    } else {
      used[e.id] = 1;
    }
  }

  // Sort
  if (cfg.sort == 'path') {
    entries.sort((a, b) => a.rel.compareTo(b.rel));
  } else {
    entries.sort((a, b) => a.id.compareTo(b.id));
  }

  // Build content
  final b = StringBuffer();
  if (cfg.addHeader) {
    b
      ..writeln('// GENERATED CODE – DO NOT MODIFY.')
      ..writeln('// Run: dart run flutter_asset_gen')
      ..writeln();
  }
  b
    ..writeln('class ${cfg.className} {')
    ..writeln('  const ${cfg.className}._();')
    ..writeln();

  if (cfg.groupByRoot) {
    final rootsOrder = entries.map((e) => e.root).toSet();
    for (final r in rootsOrder) {
      b.writeln('  // --- $r ---');
      for (final e in entries.where((x) => x.root == r)) {
        final path = '${r.replaceAll('\\', '/')}/${e.rel}';
        b
          ..writeln('  /// $path')
          ..writeln('  static const ${e.id} = "$path";');
      }
      b.writeln();
    }
  } else {
    for (final e in entries) {
      final path = '${e.root.replaceAll('\\', '/')}/${e.rel}';
      b
        ..writeln('  /// $path')
        ..writeln('  static const ${e.id} = "$path";');
    }
    b.writeln();
  }

  if (cfg.generateMap) {
    b.writeln('  static const Map<String,String> all = {');
    for (final e in entries) {
      b.writeln('    "${e.id}": ${e.id},');
    }
    b.writeln('  };');
  }
  b.writeln('}');

  final out = File(cfg.output)..createSync(recursive: true);
  final newContent = b.toString();
  final newHash = contentHash(newContent);
  final oldContent = out.existsSync() ? out.readAsStringSync() : '';
  final oldHash = contentHash(oldContent);
  final skipped = newHash == oldHash;

  if (!dryRun && !skipped) {
    out.writeAsStringSync(newContent);
  }

  if (verbose) {
    stdout.writeln(skipped
        ? 'No changes. (${entries.length} assets)'
        : 'Generated ${entries.length} assets → ${cfg.output}');
    for (final w in warnings) {
      stdout.writeln('WARN: $w');
    }
  }

  return GenerationResult(entries.length, skipped, warnings);
}

class _E {
  final String root;
  final String rel;
  final String id;
  _E({required this.root, required this.rel, required this.id});
  _E copy({String? id}) => _E(root: root, rel: rel, id: id ?? this.id);
}
