# flutter_bangla_math

`flutter_bangla_math` renders mixed Bangla text and LaTeX math in Flutter
without breaking Bengali glyph shaping. It uses `flutter_math_fork` for TeX
rendering and `google_fonts` with bundled Noto Bengali assets so it works on
Android, iOS, web, Linux, macOS, and Windows without depending on runtime font
fetching.

## Features

- Inline math with `$...$`
- Block math with `$$...$$`
- Escaped dollar handling with `\$`
- Bangla text rendered with Noto Sans Bengali by default
- Inline math baseline alignment tuned for mixed Bangla and math on the same
  line
- Offline-safe Google Fonts asset bundling
- Simple LRU cache for repeated math fragments

## Installation

```yaml
dependencies:
  flutter_bangla_math: ^0.1.0
```

The current package version targets Flutter `>=3.35.0` and Dart `^3.9.0`
because it uses the current `google_fonts` and `flutter_lints` releases that
fit the package requirements cleanly on current Flutter stable.

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bangla_math/flutter_bangla_math.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ensureBanglaMathFontsLoaded(disableRuntimeFetching: true);
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
            data: 'যদি $a^2+b^2=c^2$ হয়, তবে এটি সমকোণী ত্রিভুজ।',
          ),
        ),
      ),
    );
  }
}
```

### Block Math

```dart
const BanglaMathText(
  data: 'সমীকরণটি হল:\n\n$$\\int_0^1 x^2\\,dx=\\frac{1}{3}$$',
);
```

### Custom Text Style

```dart
BanglaMathText(
  data: 'ধরি $f(x)=x^2+1$',
  style: const TextStyle(fontSize: 20, color: Colors.black87),
  fontFamily: notoSerifBengaliFamily,
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

`MathConfig` controls inline scaling, block spacing, parser settings, and error
fallback styling.

## Notes

- Unmatched `$` or `$$` delimiters fall back to plain text instead of crashing.
- The package bundles Noto Sans Bengali and Noto Serif Bengali font files.
  Their OFL license texts are included in `assets/licenses/`.
- On web, `flutter_math_fork` works for normal cases. If your app needs a
  KaTeX-based HTML fallback for highly specialized equations, keep that as an
  app-level escape hatch rather than part of this package API.

## Development

```bash
flutter pub get
flutter analyze
flutter test
```
