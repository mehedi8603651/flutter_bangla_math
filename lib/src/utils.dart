import 'dart:ui';

import 'package:characters/characters.dart';

const Locale banglaLocale = Locale('bn');

const int _backslashCodeUnit = 92;

int countEscapingBackslashes(String input, int index) {
  var backslashCount = 0;
  for (
    var cursor = index - 1;
    cursor >= 0 && input.codeUnitAt(cursor) == _backslashCodeUnit;
    cursor--
  ) {
    backslashCount++;
  }
  return backslashCount;
}

bool isEscapedDelimiter(String input, int index) =>
    countEscapingBackslashes(input, index).isOdd;

List<String> splitByGraphemeNewlines(String text) {
  final segments = <String>[];
  final buffer = StringBuffer();

  for (final grapheme in text.characters) {
    if (grapheme == '\n') {
      segments.add(buffer.toString());
      buffer.clear();
      continue;
    }
    buffer.write(grapheme);
  }

  segments.add(buffer.toString());
  return segments;
}

String canonicalizeWhitespace(String value) => value.replaceAll('\r\n', '\n');
