import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'utils.dart';

/// Package name used to resolve bundled assets when the package is consumed
/// from another app.
const String flutterBanglaMathPackageName = 'flutter_bangla_math';

/// Default bundled Bengali font family used by this package.
const String notoSansBengaliFamily = 'Noto Sans Bengali';

final Future<void> _fontWarmup = _loadBundledBanglaFonts();

/// Returns a [TextStyle] configured for Bangla text with the bundled
/// Noto Sans Bengali font.
///
/// The optional [textStyle] is merged into the returned style and the locale
/// is forced to Bangla to improve script shaping consistency.
TextStyle defaultBanglaStyle([TextStyle? textStyle]) {
  final baseStyle = textStyle ?? const TextStyle();
  return baseStyle.copyWith(locale: banglaLocale).merge(
        const TextStyle(
          fontFamily: notoSansBengaliFamily,
          package: flutterBanglaMathPackageName,
        ),
      );
}

/// Preloads the bundled Bangla font assets used by the package.
///
/// Calling this before `runApp` avoids the first-frame font warmup cost.
///
/// The [disableRuntimeFetching] parameter is kept for backward compatibility.
/// Fonts are bundled with the package, so no runtime fetching is performed.
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
