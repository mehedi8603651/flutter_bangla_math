import 'package:flutter/foundation.dart';

import 'utils.dart';

const int _backslashCodeUnit = 92;
const int _dollarCodeUnit = 36;

@immutable
sealed class BanglaMathToken {
  const BanglaMathToken(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other.runtimeType == runtimeType &&
          other is BanglaMathToken &&
          other.value == value;

  @override
  int get hashCode => Object.hash(runtimeType, value);
}

@immutable
final class TextToken extends BanglaMathToken {
  const TextToken(super.value);
}

@immutable
final class InlineMathToken extends BanglaMathToken {
  const InlineMathToken(super.value);
}

@immutable
final class BlockMathToken extends BanglaMathToken {
  const BlockMathToken(super.value);
}

enum _ParserMode { text, inlineMath, blockMath }

class BanglaMathParser {
  const BanglaMathParser();

  List<BanglaMathToken> parse(String input) => parseBanglaMath(input);
}

List<BanglaMathToken> parseBanglaMath(String input) {
  final normalizedInput = canonicalizeWhitespace(input);
  final tokens = <BanglaMathToken>[];
  final textBuffer = <int>[];
  final mathBuffer = <int>[];
  var mode = _ParserMode.text;

  void emitText(List<int> buffer) {
    if (buffer.isEmpty) {
      return;
    }
    final text = String.fromCharCodes(buffer);
    buffer.clear();
    if (text.isEmpty) {
      return;
    }
    if (tokens case [..., final TextToken previous]) {
      tokens[tokens.length - 1] = TextToken('${previous.value}$text');
      return;
    }
    tokens.add(TextToken(text));
  }

  void emitMath(List<int> buffer, BanglaMathToken Function(String) factory) {
    final expression = String.fromCharCodes(buffer);
    buffer.clear();
    tokens.add(factory(expression));
  }

  for (var index = 0; index < normalizedInput.length; index++) {
    final codeUnit = normalizedInput.codeUnitAt(index);

    switch (mode) {
      case _ParserMode.text:
        if (codeUnit != _dollarCodeUnit) {
          textBuffer.add(codeUnit);
          continue;
        }

        if (isEscapedDelimiter(normalizedInput, index)) {
          if (textBuffer.isNotEmpty && textBuffer.last == _backslashCodeUnit) {
            textBuffer.removeLast();
          }
          textBuffer.add(_dollarCodeUnit);
          continue;
        }

        final hasSecondDollar =
            index + 1 < normalizedInput.length &&
            normalizedInput.codeUnitAt(index + 1) == _dollarCodeUnit;

        emitText(textBuffer);
        if (hasSecondDollar) {
          mode = _ParserMode.blockMath;
          index++;
        } else {
          mode = _ParserMode.inlineMath;
        }

      case _ParserMode.inlineMath:
        if (codeUnit == _dollarCodeUnit &&
            !isEscapedDelimiter(normalizedInput, index)) {
          emitMath(mathBuffer, InlineMathToken.new);
          mode = _ParserMode.text;
          continue;
        }
        mathBuffer.add(codeUnit);

      case _ParserMode.blockMath:
        final hasSecondDollar =
            index + 1 < normalizedInput.length &&
            normalizedInput.codeUnitAt(index + 1) == _dollarCodeUnit;

        if (codeUnit == _dollarCodeUnit &&
            hasSecondDollar &&
            !isEscapedDelimiter(normalizedInput, index)) {
          emitMath(mathBuffer, BlockMathToken.new);
          mode = _ParserMode.text;
          index++;
          continue;
        }
        mathBuffer.add(codeUnit);
    }
  }

  switch (mode) {
    case _ParserMode.text:
      emitText(textBuffer);

    case _ParserMode.inlineMath:
      textBuffer
        ..add(_dollarCodeUnit)
        ..addAll(mathBuffer);
      mathBuffer.clear();
      emitText(textBuffer);

    case _ParserMode.blockMath:
      textBuffer
        ..add(_dollarCodeUnit)
        ..add(_dollarCodeUnit)
        ..addAll(mathBuffer);
      mathBuffer.clear();
      emitText(textBuffer);
  }

  return List.unmodifiable(tokens);
}
