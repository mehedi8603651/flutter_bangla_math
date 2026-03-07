import 'package:flutter/foundation.dart';

import 'utils.dart';

const int _backslashCodeUnit = 92;
const int _dollarCodeUnit = 36;
const String _banglaFractionCommand = r'\bnfrac';

@immutable

/// Base token type produced by [BanglaMathParser] and [parseBanglaMath].
sealed class BanglaMathToken {
  /// Creates a token with a raw string [value].
  const BanglaMathToken(this.value);

  /// Raw token payload used by text and math tokens.
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

/// Plain text outside any math delimiters.
final class TextToken extends BanglaMathToken {
  /// Creates a text token.
  const TextToken(super.value);
}

@immutable

/// Inline math content extracted from `$...$`.
final class InlineMathToken extends BanglaMathToken {
  /// Creates an inline math token.
  const InlineMathToken(super.value);
}

@immutable

/// Display math content extracted from `$$...$$`.
final class BlockMathToken extends BanglaMathToken {
  /// Creates a block math token.
  const BlockMathToken(super.value);
}

@immutable

/// Inline Bangla fraction content extracted from `\bnfrac{...}{...}`.
final class BanglaFractionToken extends BanglaMathToken {
  /// Creates a Bangla fraction token with numerator and denominator content.
  const BanglaFractionToken({
    required this.numerator,
    required this.denominator,
  }) : super('');

  /// Fraction numerator content rendered with [BanglaMathText].
  final String numerator;

  /// Fraction denominator content rendered with [BanglaMathText].
  final String denominator;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BanglaFractionToken &&
          other.numerator == numerator &&
          other.denominator == denominator;

  @override
  int get hashCode => Object.hash(runtimeType, numerator, denominator);
}

enum _ParserMode { text, inlineMath, blockMath }

/// Parses mixed Bangla text and math into token objects.
class BanglaMathParser {
  /// Creates a parser for mixed Bangla text and math.
  const BanglaMathParser();

  /// Tokenizes [input] into text, inline math, block math, and `\bnfrac`
  /// segments.
  List<BanglaMathToken> parse(String input) => parseBanglaMath(input);
}

/// Tokenizes [input] into a sequence of Bangla text and math tokens.
///
/// Supported syntax:
/// - plain text
/// - inline math with `$...$`
/// - block math with `$$...$$`
/// - inline Bangla fractions with `\bnfrac{...}{...}`
/// - escaped dollar signs with `\$`
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
        final fractionResult = _tryParseBanglaFraction(normalizedInput, index);
        if (fractionResult != null) {
          emitText(textBuffer);
          tokens.add(fractionResult.token);
          index = fractionResult.endIndex;
          continue;
        }

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

        final hasSecondDollar = index + 1 < normalizedInput.length &&
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
        final hasSecondDollar = index + 1 < normalizedInput.length &&
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

_BanglaFractionParseResult? _tryParseBanglaFraction(String input, int start) {
  if (!input.startsWith(_banglaFractionCommand, start)) {
    return null;
  }

  var cursor = start + _banglaFractionCommand.length;
  cursor = _skipWhitespace(input, cursor);

  final numerator = _readBalancedArgument(input, cursor);
  if (numerator == null) {
    return null;
  }

  cursor = _skipWhitespace(input, numerator.endIndex + 1);
  final denominator = _readBalancedArgument(input, cursor);
  if (denominator == null) {
    return null;
  }

  return _BanglaFractionParseResult(
    token: BanglaFractionToken(
      numerator: numerator.content,
      denominator: denominator.content,
    ),
    endIndex: denominator.endIndex,
  );
}

int _skipWhitespace(String input, int start) {
  var cursor = start;
  while (cursor < input.length) {
    final character = input[cursor];
    if (character != ' ' && character != '\n' && character != '\t') {
      break;
    }
    cursor++;
  }
  return cursor;
}

_BalancedArgumentRead? _readBalancedArgument(String input, int start) {
  if (start >= input.length || input.codeUnitAt(start) != '{'.codeUnitAt(0)) {
    return null;
  }

  var depth = 1;
  for (var index = start + 1; index < input.length; index++) {
    final codeUnit = input.codeUnitAt(index);
    if (codeUnit == '{'.codeUnitAt(0) && !_isEscapedCharacter(input, index)) {
      depth++;
      continue;
    }

    if (codeUnit == '}'.codeUnitAt(0) && !_isEscapedCharacter(input, index)) {
      depth--;
      if (depth == 0) {
        return _BalancedArgumentRead(
          content: input.substring(start + 1, index),
          endIndex: index,
        );
      }
    }
  }

  return null;
}

bool _isEscapedCharacter(String input, int index) =>
    countEscapingBackslashes(input, index).isOdd;

@immutable
final class _BalancedArgumentRead {
  const _BalancedArgumentRead({required this.content, required this.endIndex});

  final String content;
  final int endIndex;
}

@immutable
final class _BanglaFractionParseResult {
  const _BanglaFractionParseResult({
    required this.token,
    required this.endIndex,
  });

  final BanglaFractionToken token;
  final int endIndex;
}
