import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'utils.dart';

const String flutterBanglaMathPackageName = 'flutter_bangla_math';
const String notoSansBengaliFamily = 'Noto Sans Bengali';
const String notoSerifBengaliFamily = 'Noto Serif Bengali';

final Future<void> _fontWarmup = _loadBundledBanglaFonts();

TextStyle defaultBanglaStyle([TextStyle? textStyle]) {
  final baseStyle = textStyle ?? const TextStyle();
  return GoogleFonts.notoSansBengali(
    textStyle: baseStyle.copyWith(locale: banglaLocale),
  );
}

TextStyle defaultBanglaSerifStyle([TextStyle? textStyle]) {
  final baseStyle = textStyle ?? const TextStyle();
  return GoogleFonts.notoSerifBengali(
    textStyle: baseStyle.copyWith(locale: banglaLocale),
  );
}

Future<void> ensureBanglaMathFontsLoaded({
  bool disableRuntimeFetching = false,
}) async {
  if (disableRuntimeFetching) {
    GoogleFonts.config.allowRuntimeFetching = false;
  }
  await _fontWarmup;
}

Future<void> _loadBundledBanglaFonts() async {
  await Future.wait([
    _loadFontVariant(
      'NotoSansBengali_400_regular',
      'assets/fonts/NotoSansBengali-Regular.ttf',
    ),
    _loadFontVariant(
      'NotoSansBengali_700_regular',
      'assets/fonts/NotoSansBengali-Bold.ttf',
    ),
    _loadFontVariant(
      'NotoSerifBengali_400_regular',
      'assets/fonts/NotoSerifBengali-Regular.ttf',
    ),
    _loadFontVariant(
      'NotoSerifBengali_700_regular',
      'assets/fonts/NotoSerifBengali-Bold.ttf',
    ),
  ]);
}

Future<void> _loadFontVariant(String family, String assetPath) async {
  final fontLoader = FontLoader(family)..addFont(_loadByteData(assetPath));
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
