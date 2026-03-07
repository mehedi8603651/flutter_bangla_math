import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'utils.dart';

const String flutterBanglaMathPackageName = 'flutter_bangla_math';
const String notoSansBengaliFamily = 'Noto Sans Bengali';

final Future<void> _fontWarmup = _loadBundledBanglaFonts();

TextStyle defaultBanglaStyle([TextStyle? textStyle]) {
  final baseStyle = textStyle ?? const TextStyle();
  return baseStyle.copyWith(locale: banglaLocale).merge(
        const TextStyle(
          fontFamily: notoSansBengaliFamily,
          package: flutterBanglaMathPackageName,
        ),
      );
}

Future<void> ensureBanglaMathFontsLoaded({
  bool disableRuntimeFetching = false,
}) async {
  // Kept for backward compatibility. Fonts are bundled, so there is no
  // runtime fetching path to disable.
  if (disableRuntimeFetching) {
    // Intentionally left blank.
  }
  await _fontWarmup;
}

Future<void> _loadBundledBanglaFonts() async {
  final fontLoader = FontLoader(notoSansBengaliFamily)
    ..addFont(_loadByteData('assets/fonts/NotoSansBengali-Regular.ttf'))
    ..addFont(_loadByteData('assets/fonts/NotoSansBengali-Bold.ttf'));

  await fontLoader.load();
}

Future<ByteData> _loadByteData(String assetPath) async {
  final candidates = <String>[
    'packages/$flutterBanglaMathPackageName/$assetPath',
    assetPath,
  ];

  FlutterError? lastError;
  for (final candidate in candidates) {
    try {
      return await rootBundle.load(candidate);
    } on FlutterError catch (error) {
      lastError = error;
    }
  }

  throw lastError ??
      FlutterError('Unable to load bundled Bangla font asset: $assetPath');
}
