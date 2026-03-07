import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pubspec keeps required package constraints', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('name: flutter_bangla_math'));
    expect(pubspec, contains('flutter_math_fork: ^0.7.4'));
    expect(pubspec, isNot(contains('google_fonts:')));
    expect(pubspec, isNot(contains('mockito:')));
    expect(pubspec, contains('flutter_lints: ^4.0.0'));
    expect(pubspec, contains('sdk: ">=3.2.0 <4.0.0"'));
    expect(pubspec, contains('flutter: ">=3.16.0"'));
  });
}
