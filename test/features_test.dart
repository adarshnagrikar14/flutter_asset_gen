import 'package:test/test.dart';
import 'package:flutter_asset_gen/flutter_asset_gen.dart';

void main() {
  group('New Features Tests', () {
    test('Config supports new options', () {
      final config = AssetGenConfig.defaults();

      expect(config.watchMode, isFalse);
      expect(config.generateEnum, isFalse);
      expect(config.validatePubspec, isTrue);
      expect(config.buildRunnerMode, isFalse);
      expect(config.pubspecPath, isNull);
    });

    test('Config copyWith works with new options', () {
      final config = AssetGenConfig.defaults();
      final newConfig = config.copyWith(
        watchMode: true,
        generateEnum: true,
        validatePubspec: false,
        buildRunnerMode: true,
        pubspecPath: 'custom_pubspec.yaml',
      );

      expect(newConfig.watchMode, isTrue);
      expect(newConfig.generateEnum, isTrue);
      expect(newConfig.validatePubspec, isFalse);
      expect(newConfig.buildRunnerMode, isTrue);
      expect(newConfig.pubspecPath, equals('custom_pubspec.yaml'));
    });

    test('ValidationResult structure', () {
      final result = ValidationResult(
        isValid: true,
        missingAssets: ['asset1.png'],
        unusedAssets: ['asset2.png'],
        warnings: ['warning1'],
      );

      expect(result.isValid, isTrue);
      expect(result.missingAssets, contains('asset1.png'));
      expect(result.unusedAssets, contains('asset2.png'));
      expect(result.warnings, contains('warning1'));
    });

    test('AssetWatcher can be instantiated', () {
      final config = AssetGenConfig.defaults();
      final watcher = AssetWatcher(config);

      expect(watcher, isNotNull);
    });

    test('AssetGenBuilder can be instantiated', () {
      final builder = AssetGenBuilder();

      expect(builder, isNotNull);
      expect(builder.buildExtensions, isA<Map<String, List<String>>>());
    });
  });
}
