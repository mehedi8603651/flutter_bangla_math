import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import 'cache.dart';
import 'font_loader.dart';
import 'parser.dart';
import 'utils.dart';

@immutable
class MathConfig {
  const MathConfig({
    this.inlineScale = 1.05,
    this.blockScale = 1.2,
    this.inlineBaselineFactor = 0.82,
    this.blockVerticalMargin = 12,
    this.blockAlignment = Alignment.center,
    this.logicalPpi,
    this.errorStyle,
    this.parserSettings = const TexParserSettings(),
  });

  final double inlineScale;
  final double blockScale;
  final double inlineBaselineFactor;
  final double blockVerticalMargin;
  final AlignmentGeometry blockAlignment;
  final double? logicalPpi;
  final TextStyle? errorStyle;
  final TexParserSettings parserSettings;

  MathConfig copyWith({
    double? inlineScale,
    double? blockScale,
    double? inlineBaselineFactor,
    double? blockVerticalMargin,
    AlignmentGeometry? blockAlignment,
    double? logicalPpi,
    TextStyle? errorStyle,
    TexParserSettings? parserSettings,
  }) {
    return MathConfig(
      inlineScale: inlineScale ?? this.inlineScale,
      blockScale: blockScale ?? this.blockScale,
      inlineBaselineFactor: inlineBaselineFactor ?? this.inlineBaselineFactor,
      blockVerticalMargin: blockVerticalMargin ?? this.blockVerticalMargin,
      blockAlignment: blockAlignment ?? this.blockAlignment,
      logicalPpi: logicalPpi ?? this.logicalPpi,
      errorStyle: errorStyle ?? this.errorStyle,
      parserSettings: parserSettings ?? this.parserSettings,
    );
  }
}

class BanglaMathText extends StatelessWidget {
  const BanglaMathText({
    super.key,
    required this.data,
    this.style,
    this.mathConfig,
    this.fontFamily,
    this.locale = banglaLocale,
    this.textAlign = TextAlign.start,
    this.softWrap = true,
    this.textScaler,
    this.cache,
  });

  final String data;
  final TextStyle? style;
  final MathConfig? mathConfig;
  final String? fontFamily;
  final Locale locale;
  final TextAlign textAlign;
  final bool softWrap;
  final TextScaler? textScaler;
  final MathWidgetCache? cache;

  @override
  Widget build(BuildContext context) {
    final effectiveConfig = mathConfig ?? const MathConfig();
    final effectiveTextScaler = textScaler ?? MediaQuery.textScalerOf(context);
    final defaultStyle = DefaultTextStyle.of(context).style;
    final baseStyle = defaultStyle.merge(style);
    final effectiveStyle = _resolveTextStyle(baseStyle);
    final effectiveCache = cache ?? MathWidgetCache.shared;
    final tokens = const BanglaMathParser().parse(data);

    final segments = <_RenderSegment>[];
    var inlineSpans = <InlineSpan>[];

    void flushInline() {
      if (inlineSpans.isEmpty) {
        return;
      }
      segments.add(_InlineSegment(List<InlineSpan>.unmodifiable(inlineSpans)));
      inlineSpans = <InlineSpan>[];
    }

    for (final token in tokens) {
      switch (token) {
        case TextToken():
          if (token.value.isEmpty) {
            continue;
          }
          inlineSpans.add(
            TextSpan(text: token.value, style: effectiveStyle, locale: locale),
          );

        case InlineMathToken():
          inlineSpans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: _InlineMath(
                token: token,
                baseStyle: effectiveStyle,
                config: effectiveConfig,
                textScaler: effectiveTextScaler,
                cache: effectiveCache,
              ),
            ),
          );

        case BlockMathToken():
          flushInline();
          segments.add(
            _BlockSegment(
              token: token,
              baseStyle: effectiveStyle,
              config: effectiveConfig,
              textScaler: effectiveTextScaler,
              cache: effectiveCache,
            ),
          );
      }
    }

    flushInline();

    if (segments.isEmpty) {
      return RichText(
        text: TextSpan(style: effectiveStyle, text: ''),
        textAlign: textAlign,
        softWrap: softWrap,
        textScaler: effectiveTextScaler,
      );
    }

    if (segments case [final _InlineSegment segment]) {
      return RichText(
        text: TextSpan(style: effectiveStyle, children: segment.spans),
        textAlign: textAlign,
        softWrap: softWrap,
        textScaler: effectiveTextScaler,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: segments
          .map((segment) {
            return switch (segment) {
              _InlineSegment(:final spans) => RichText(
                text: TextSpan(style: effectiveStyle, children: spans),
                textAlign: textAlign,
                softWrap: softWrap,
                textScaler: effectiveTextScaler,
              ),
              _BlockSegment(
                :final token,
                :final baseStyle,
                :final config,
                :final textScaler,
                :final cache,
              ) =>
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: config.blockVerticalMargin / 2,
                  ),
                  child: Align(
                    alignment: config.blockAlignment,
                    child: _BlockMath(
                      token: token,
                      baseStyle: baseStyle,
                      config: config,
                      textScaler: textScaler,
                      cache: cache,
                    ),
                  ),
                ),
            };
          })
          .toList(growable: false),
    );
  }

  TextStyle _resolveTextStyle(TextStyle baseStyle) {
    final localizedStyle = baseStyle.copyWith(locale: locale);

    if (fontFamily != null && fontFamily!.isNotEmpty) {
      return localizedStyle.copyWith(fontFamily: fontFamily);
    }

    if ((style?.fontFamily ?? baseStyle.fontFamily) != null) {
      return localizedStyle;
    }

    return defaultBanglaStyle(localizedStyle);
  }
}

sealed class _RenderSegment {
  const _RenderSegment();
}

class _InlineSegment extends _RenderSegment {
  const _InlineSegment(this.spans);

  final List<InlineSpan> spans;
}

class _BlockSegment extends _RenderSegment {
  const _BlockSegment({
    required this.token,
    required this.baseStyle,
    required this.config,
    required this.textScaler,
    required this.cache,
  });

  final BlockMathToken token;
  final TextStyle baseStyle;
  final MathConfig config;
  final TextScaler textScaler;
  final MathWidgetCache cache;
}

class _InlineMath extends StatelessWidget {
  const _InlineMath({
    required this.token,
    required this.baseStyle,
    required this.config,
    required this.textScaler,
    required this.cache,
  });

  final InlineMathToken token;
  final TextStyle baseStyle;
  final MathConfig config;
  final TextScaler textScaler;
  final MathWidgetCache cache;

  @override
  Widget build(BuildContext context) {
    final scaledFontSize =
        textScaler.scale(baseStyle.fontSize ?? 14) * config.inlineScale;
    final baseline = scaledFontSize * config.inlineBaselineFactor;

    return Baseline(
      baseline: baseline,
      baselineType: TextBaseline.alphabetic,
      child: cache.putIfAbsent(
        _cacheKey(
          tex: token.value,
          style: MathStyle.text,
          fontSize: scaledFontSize,
          color: baseStyle.color,
          fontWeight: baseStyle.fontWeight,
          fontStyle: baseStyle.fontStyle,
          config: config,
        ),
        () => _buildMathWidget(
          tex: token.value,
          mathStyle: MathStyle.text,
          fontSize: scaledFontSize,
          baseStyle: baseStyle,
          config: config,
        ),
      ),
    );
  }
}

class _BlockMath extends StatelessWidget {
  const _BlockMath({
    required this.token,
    required this.baseStyle,
    required this.config,
    required this.textScaler,
    required this.cache,
  });

  final BlockMathToken token;
  final TextStyle baseStyle;
  final MathConfig config;
  final TextScaler textScaler;
  final MathWidgetCache cache;

  @override
  Widget build(BuildContext context) {
    final scaledFontSize =
        textScaler.scale(baseStyle.fontSize ?? 14) * config.blockScale;

    return cache.putIfAbsent(
      _cacheKey(
        tex: token.value,
        style: MathStyle.display,
        fontSize: scaledFontSize,
        color: baseStyle.color,
        fontWeight: baseStyle.fontWeight,
        fontStyle: baseStyle.fontStyle,
        config: config,
      ),
      () => _buildMathWidget(
        tex: token.value,
        mathStyle: MathStyle.display,
        fontSize: scaledFontSize,
        baseStyle: baseStyle,
        config: config,
      ),
    );
  }
}

Widget _buildMathWidget({
  required String tex,
  required MathStyle mathStyle,
  required double fontSize,
  required TextStyle baseStyle,
  required MathConfig config,
}) {
  final fallbackStyle = (config.errorStyle ?? const TextStyle()).merge(
    baseStyle.copyWith(
      fontFamily: 'monospace',
      color: Colors.red.shade700,
      fontSize: fontSize,
      locale: banglaLocale,
    ),
  );

  return Math.tex(
    tex,
    mathStyle: mathStyle,
    settings: config.parserSettings,
    options: MathOptions(
      style: mathStyle,
      color: baseStyle.color ?? Colors.black,
      fontSize: fontSize,
      logicalPpi: config.logicalPpi,
      mathFontOptions: _fontOptionsFromTextStyle(baseStyle),
    ),
    onErrorFallback: (error) => Text(
      mathStyle == MathStyle.display ? '\$\$$tex\$\$' : '\$$tex\$',
      style: fallbackStyle,
    ),
  );
}

FontOptions? _fontOptionsFromTextStyle(TextStyle style) {
  final fontWeight = style.fontWeight ?? FontWeight.normal;
  final fontShape = style.fontStyle ?? FontStyle.normal;

  if (fontWeight == FontWeight.normal && fontShape == FontStyle.normal) {
    return null;
  }

  return FontOptions(fontWeight: fontWeight, fontShape: fontShape);
}

String _cacheKey({
  required String tex,
  required MathStyle style,
  required double fontSize,
  required Color? color,
  required FontWeight? fontWeight,
  required FontStyle? fontStyle,
  required MathConfig config,
}) {
  return [
    style.name,
    tex,
    fontSize.toStringAsFixed(3),
    color?.toARGB32().toRadixString(16) ?? 'null',
    fontWeight?.value.toString() ?? 'null',
    fontStyle?.name ?? 'null',
    config.logicalPpi?.toStringAsFixed(3) ?? 'null',
    config.inlineScale.toStringAsFixed(3),
    config.blockScale.toStringAsFixed(3),
  ].join('|');
}
