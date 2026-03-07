import 'dart:ui';

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

String canonicalizeWhitespace(String value) => value.replaceAll('\r\n', '\n');
