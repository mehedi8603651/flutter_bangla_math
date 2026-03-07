import 'dart:collection';

import 'package:flutter/widgets.dart';

class MathWidgetCache {
  MathWidgetCache({this.maxEntries = 128})
    : assert(maxEntries > 0, 'maxEntries must be positive.');

  final int maxEntries;

  final LinkedHashMap<String, Widget> _entries =
      LinkedHashMap<String, Widget>();

  static final MathWidgetCache shared = MathWidgetCache();

  int get length => _entries.length;

  Widget? get(String key) {
    final value = _entries.remove(key);
    if (value == null) {
      return null;
    }
    _entries[key] = value;
    return value;
  }

  Widget putIfAbsent(String key, Widget Function() builder) {
    final cached = get(key);
    if (cached != null) {
      return cached;
    }

    final value = builder();
    _entries[key] = value;

    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }

    return value;
  }

  void evict(String key) => _entries.remove(key);

  void clear() => _entries.clear();
}
