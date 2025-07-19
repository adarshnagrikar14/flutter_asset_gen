import 'package:flutter_asset_gen/src/utils.dart';
import 'package:test/test.dart';

void main() {
  test('camelCase generation', () {
    expect(
      buildIdentifier('icons/play_button.svg', caseStyle: 'camel', prefix: ''),
      'iconsPlayButton',
    );
  });

  test('snake_case generation', () {
    expect(
      buildIdentifier('icons/play-button.svg', caseStyle: 'snake', prefix: ''),
      'icons_play_button',
    );
  });

  test('numeric leading -> prefixed underscore', () {
    expect(
      buildIdentifier('1logo/main.png', caseStyle: 'camel', prefix: ''),
      '_1logoMain',
    );
  });
}
