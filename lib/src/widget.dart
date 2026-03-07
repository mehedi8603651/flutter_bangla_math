import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import 'cache.dart';
import 'font_loader.dart';
import 'parser.dart';
import 'utils.dart';

@immutable

/// Configuration for math sizing, spacing, and parser behavior.
class MathConfig {
  /// Creates rendering settings shared by inline and block math widgets.
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

  /// Multiplier applied to the surrounding text size for inline math.
  final double inlineScale;

  /// Multiplier applied to the surrounding text size for block math.
  final double blockScale;

  /// Baseline factor used to align inline math with surrounding text.
  final double inlineBaselineFactor;

  /// Total vertical margin applied around rendered block math.
  final double blockVerticalMargin;

  /// Alignment used for block math widgets.
  final AlignmentGeometry blockAlignment;

  /// Optional logical PPI forwarded to `flutter_math_fork`.
  final double? logicalPpi;

  /// Optional style used when math rendering falls back to error text.
  final TextStyle? errorStyle;

  /// TeX parser settings forwarded to `flutter_math_fork`.
  final TexParserSettings parserSettings;

  /// Returns a copy of this config with the provided fields replaced.
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

/// Renders mixed Bangla text and LaTeX math from a single input string.
///
/// The widget supports plain text, inline math with `$...$`, block math with
/// `$$...$$`, and inline fractions with `\bnfrac{...}{...}`.
class BanglaMathText extends StatelessWidget {
  /// Creates a widget that renders mixed Bangla text and math from [data].
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

  /// Source string containing Bangla text and supported math syntax.
  final String data;

  /// Optional text style merged with the ambient default text style.
  final TextStyle? style;

  /// Rendering configuration for inline and block math segments.
  final MathConfig? mathConfig;

  /// Optional font family override for the Bangla text portions.
  final String? fontFamily;

  /// Locale used for Bangla text shaping.
  final Locale locale;

  /// Alignment applied to inline text segments and paragraph output.
  final TextAlign textAlign;

  /// Whether text segments may soft-wrap.
  final bool softWrap;

  /// Optional text scaling override.
  final TextScaler? textScaler;

  /// Optional cache used for rendered math widgets.
  final MathWidgetCache? cache;

  @override
  Widget build(BuildContext context) {
    final effectiveConfig = mathConfig ?? const MathConfig();
    final effectiveTextScaler = textScaler ?? MediaQuery.textScalerOf(context);
    final defaultStyle = DefaultTextStyle.of(context).style;
    final baseStyle = defaultStyle.merge(style);
    final effectiveStyle = _resolveBanglaTextStyle(
      baseStyle: baseStyle,
      style: style,
      fontFamily: fontFamily,
      locale: locale,
    );
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

        case BanglaFractionToken():
          inlineSpans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: BanglaMathFraction(
                  numerator: token.numerator,
                  denominator: token.denominator,
                  style: effectiveStyle,
                  mathConfig: effectiveConfig,
                  fontFamily: fontFamily,
                  locale: locale,
                  textAlign: TextAlign.center,
                  softWrap: softWrap,
                  textScaler: effectiveTextScaler,
                  cache: effectiveCache,
                  gap: 3,
                  padding: EdgeInsets.zero,
                ),
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
      children: segments.map((segment) {
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
      }).toList(growable: false),
    );
  }
}

/// Renders a Bangla-aware stacked fraction from numerator and denominator text.
///
/// Both [numerator] and [denominator] are rendered with [BanglaMathText], so
/// they can themselves contain Bangla text and inline math.
class BanglaMathFraction extends StatefulWidget {
  /// Creates a fraction widget from Bangla-aware numerator and denominator
  /// strings.
  const BanglaMathFraction({
    super.key,
    required this.numerator,
    required this.denominator,
    this.style,
    this.mathConfig,
    this.fontFamily,
    this.locale = banglaLocale,
    this.textAlign = TextAlign.center,
    this.softWrap = true,
    this.textScaler,
    this.cache,
    this.barColor,
    this.barThickness = 1,
    this.gap = 4,
    this.padding = const EdgeInsets.symmetric(horizontal: 4),
  })  : assert(barThickness > 0, 'barThickness must be positive.'),
        assert(gap >= 0, 'gap must be non-negative.');

  /// Numerator content rendered above the fraction bar.
  final String numerator;

  /// Denominator content rendered below the fraction bar.
  final String denominator;

  /// Optional text style merged into both numerator and denominator text.
  final TextStyle? style;

  /// Rendering configuration forwarded to nested [BanglaMathText] widgets.
  final MathConfig? mathConfig;

  /// Optional font family override for Bangla text inside the fraction.
  final String? fontFamily;

  /// Locale used for numerator and denominator Bangla text.
  final Locale locale;

  /// Text alignment applied to numerator and denominator lines.
  final TextAlign textAlign;

  /// Whether numerator and denominator text may soft-wrap.
  final bool softWrap;

  /// Optional text scaling override for the fraction content.
  final TextScaler? textScaler;

  /// Optional cache used by nested math segments.
  final MathWidgetCache? cache;

  /// Color used for the fraction bar. Defaults to the resolved text color.
  final Color? barColor;

  /// Thickness of the fraction bar.
  final double barThickness;

  /// Vertical gap between the fraction bar and each text line.
  final double gap;

  /// Outer padding applied around the fraction widget.
  final EdgeInsetsGeometry padding;

  @override
  State<BanglaMathFraction> createState() => _BanglaMathFractionState();
}

class _BanglaMathFractionState extends State<BanglaMathFraction> {
  double _numeratorWidth = 0;
  double _denominatorWidth = 0;

  void _updateNumeratorWidth(Size size) {
    if (!mounted || _numeratorWidth == size.width) {
      return;
    }
    setState(() {
      _numeratorWidth = size.width;
    });
  }

  void _updateDenominatorWidth(Size size) {
    if (!mounted || _denominatorWidth == size.width) {
      return;
    }
    setState(() {
      _denominatorWidth = size.width;
    });
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final baseStyle = defaultStyle.merge(widget.style);
    final effectiveStyle = _resolveBanglaTextStyle(
      baseStyle: baseStyle,
      style: widget.style,
      fontFamily: widget.fontFamily,
      locale: widget.locale,
    );
    final effectiveBarColor =
        widget.barColor ?? effectiveStyle.color ?? Colors.black;
    final barWidth = math.max(_numeratorWidth, _denominatorWidth);

    return Align(
      alignment: Alignment.center,
      widthFactor: 1,
      child: Padding(
        padding: widget.padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _MeasureSize(
              onChange: _updateNumeratorWidth,
              child: BanglaMathText(
                data: widget.numerator,
                style: widget.style,
                mathConfig: widget.mathConfig,
                fontFamily: widget.fontFamily,
                locale: widget.locale,
                textAlign: widget.textAlign,
                softWrap: widget.softWrap,
                textScaler: widget.textScaler,
                cache: widget.cache,
              ),
            ),
            SizedBox(height: widget.gap),
            SizedBox(
              width: barWidth,
              height: widget.barThickness,
              child: ColoredBox(color: effectiveBarColor),
            ),
            SizedBox(height: widget.gap),
            _MeasureSize(
              onChange: _updateDenominatorWidth,
              child: BanglaMathText(
                data: widget.denominator,
                style: widget.style,
                mathConfig: widget.mathConfig,
                fontFamily: widget.fontFamily,
                locale: widget.locale,
                textAlign: widget.textAlign,
                softWrap: widget.softWrap,
                textScaler: widget.textScaler,
                cache: widget.cache,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.onChange, required super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMeasureSize(onChange);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderMeasureSize renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize(this.onChange);

  ValueChanged<Size> onChange;
  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();

    final newSize = child?.size;
    if (newSize == null || newSize == _oldSize) {
      return;
    }

    _oldSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onChange(newSize);
    });
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
    color?.toString() ?? 'null',
    fontWeight?.value.toString() ?? 'null',
    fontStyle?.name ?? 'null',
    config.logicalPpi?.toStringAsFixed(3) ?? 'null',
    config.inlineScale.toStringAsFixed(3),
    config.blockScale.toStringAsFixed(3),
  ].join('|');
}

TextStyle _resolveBanglaTextStyle({
  required TextStyle baseStyle,
  required TextStyle? style,
  required String? fontFamily,
  required Locale locale,
}) {
  final localizedStyle = baseStyle.copyWith(locale: locale);

  if (fontFamily != null && fontFamily.isNotEmpty) {
    return localizedStyle.copyWith(fontFamily: fontFamily);
  }

  if ((style?.fontFamily ?? baseStyle.fontFamily) != null) {
    return localizedStyle;
  }

  return defaultBanglaStyle(localizedStyle);
}
