import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pubspec keeps required package constraints', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('name: flutter_bangla_math'));
    expect(pubspec, contains('flutter_math_fork: ^0.7.4'));
    expect(pubspec, contains('google_fonts: ^8.0.2'));
    expect(pubspec, contains('mockito: ^5.6.3'));
    expect(pubspec, contains('flutter_lints: ^6.0.0'));
    expect(pubspec, contains('sdk: ^3.9.0'));
    expect(pubspec, contains('flutter: ">=3.35.0"'));
  });
}
