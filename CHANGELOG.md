# Changelog

## 0.4.0

- Added inline `\bnfrac{...}{...}` parsing in `BanglaMathText` so a Bangla
  fraction can appear in the same line as surrounding text and math.
- Added parser and widget test coverage for inline `\bnfrac` rendering.
- Added example and README documentation for the new inline fraction syntax.
- Lowered the package compatibility target to Dart `>=3.2.0 <4.0.0` and
  Flutter `>=3.16.0`.
- Removed the runtime `google_fonts` dependency and kept bundled Noto Sans
  Bengali as the default font source.

## 0.3.0

- Added `BanglaMathFraction` for stacked numerator/denominator layouts using
  the same Bangla text and inline LaTeX rendering pipeline as
  `BanglaMathText`.
- Added example and widget test coverage for `BanglaMathFraction`.

## 0.2.0

- Removed bundled Noto Serif Bengali to reduce package size.
- Removed license text files from Flutter runtime assets.
- Kept Noto Sans Bengali as the only bundled Bengali font.

## 0.1.0

- Initial release of `flutter_bangla_math`.
- Added Bangla-aware text and LaTeX parsing for inline and block math.
- Added bundled Noto Sans Bengali and Noto Serif Bengali fonts for stable
  rendering and tests.
- Added example app, tests, and GitHub Actions CI.
