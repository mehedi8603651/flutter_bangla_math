# flutter_bangla_math

`flutter_bangla_math` renders mixed Bangla text and LaTeX math in Flutter
without breaking Bengali glyph shaping. It uses `flutter_math_fork` for TeX
rendering and bundles Noto Sans Bengali so it works offline on Android, iOS,
web, Linux, macOS, and Windows.

## Features

- Inline math with `$...$`
- Block math with `$$...$$`
- Fraction layout with `BanglaMathFraction`
- Inline `\bnfrac{...}{...}` syntax inside `BanglaMathText`
- Escaped dollar handling with `\$`
- Bangla text rendered with bundled Noto Sans Bengali by default
- Inline math baseline alignment tuned for mixed Bangla and math on the same
  line
- Offline-safe bundled font loading with no runtime font fetching dependency

## Installation

```yaml
dependencies:
  flutter_bangla_math: ^0.4.1
```

The current package targets Flutter `>=3.16.0` and Dart `>=3.2.0 <4.0.0`.

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bangla_math/flutter_bangla_math.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ensureBanglaMathFontsLoaded();
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: EdgeInsets.all(24),
          child: BanglaMathText(
            data: r'যদি $a^2+b^2=c^2$ হয়, তবে এটি সমকোণী ত্রিভুজ।',
          ),
        ),
      ),
    );
  }
}
```

## String Literals

Use a raw string when the text contains LaTeX delimiters or backslashes.

```dart
const BanglaMathText(
  data: r'ধরি $f(x)=x^2+1$',
);
```

If you also need new lines, use a normal string with `\n`, or use a
triple-quoted string with real line breaks.

```dart
const BanglaMathText(
  data: 'সমীকরণটি হল:\n\n$$\\int_0^1 x^2\\,dx=\\frac{1}{3}$$',
);
```

```dart
const BanglaMathText(
  data: r'''সমীকরণটি হল:

$$\int_0^1 x^2\,dx=\frac{1}{3}$$''',
);
```

Do not write this if you expect a real line break:

```dart
const BanglaMathText(
  data: r'সমীকরণটি হল:\n\n$$\int_0^1 x^2\,dx=\frac{1}{3}$$',
);
```

That raw string keeps `\n` as two visible characters because this is normal
Dart string behavior.

## Examples

### Block Math

```dart
const BanglaMathText(
  data: r'''সমীকরণটি হল:

$$\int_0^1 x^2\,dx=\frac{1}{3}$$''',
);
```

### Bangla Fraction

```dart
const BanglaMathFraction(
  numerator: r'লব $x+1$',
  denominator: r'হর $y+2$',
  style: TextStyle(fontSize: 20),
);
```

### Inline Fraction Syntax

```dart
const BanglaMathText(
  data: r'যদি $a^2+b^2=c^2$ হয়, তবে \bnfrac{লব $x+1$}{হর $y+2$} হবে।',
);
```

### Multiple BanglaMathText Widgets

```dart
ListView(
  padding: const EdgeInsets.all(24),
  children: const [
    BanglaMathText(
      data: r'প্রথম লাইনে \bnfrac{লব $x+1$}{হর $y+2$} আছে।',
    ),
    SizedBox(height: 12),
    BanglaMathText(
      data: r'দ্বিতীয় লাইনে আবার \bnfrac{লব $x+1$}{হর $y+2$} আছে।',
    ),
  ],
)
```

If you place many `BanglaMathText` widgets in a `Column`, wrap it with
`SingleChildScrollView` or use `ListView` when the content can exceed the
screen height.

### Custom Text Style

```dart
const BanglaMathText(
  data: r'ধরি $f(x)=x^2+1$',
  style: TextStyle(fontSize: 20, color: Colors.black87),
);
```

## API

```dart
BanglaMathText({
  required String data,
  TextStyle? style,
  MathConfig? mathConfig,
  String? fontFamily,
  Locale locale = const Locale('bn'),
  TextAlign textAlign = TextAlign.start,
  bool softWrap = true,
  TextScaler? textScaler,
  MathWidgetCache? cache,
})
```

```dart
BanglaMathFraction({
  required String numerator,
  required String denominator,
  TextStyle? style,
  MathConfig? mathConfig,
  String? fontFamily,
  Locale locale = const Locale('bn'),
  TextAlign textAlign = TextAlign.center,
  bool softWrap = true,
  TextScaler? textScaler,
  MathWidgetCache? cache,
  Color? barColor,
  double barThickness = 1,
  double gap = 4,
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 4),
})
```

`MathConfig` controls inline scaling, block spacing, parser settings, and error
fallback styling. `BanglaMathFraction` reuses the same text and math pipeline,
so numerator and denominator strings can contain Bangla text with inline math.
`BanglaMathText` also supports inline `\bnfrac{...}{...}` tokens in normal
paragraph text.

## Notes

- Unmatched `$` or `$$` delimiters fall back to plain text instead of crashing.
- The package bundles only Noto Sans Bengali to keep size lower.
- `ensureBanglaMathFontsLoaded()` is still available and preloads the bundled
  font.
- The Noto Sans Bengali OFL text remains in the repository for reference, but
  it is not bundled into runtime Flutter assets.

## Development

```bash
flutter pub get
flutter analyze
flutter test
```
