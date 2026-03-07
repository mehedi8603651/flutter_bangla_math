import 'dart:async';

import 'package:flutter_bangla_math/flutter_bangla_math.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await ensureBanglaMathFontsLoaded(disableRuntimeFetching: true);
  await testMain();
}
