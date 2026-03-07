import 'dart:collection';

import 'package:flutter/widgets.dart';

/// A small LRU cache for rendered math widgets.
///
/// The cache is keyed by a string that typically includes the TeX source plus
/// the layout parameters used to render it.
class MathWidgetCache {
  /// Creates a cache with an upper bound on stored entries.
  MathWidgetCache({this.maxEntries = 128})
      : assert(maxEntries > 0, 'maxEntries must be positive.');

  /// Maximum number of widgets retained before older entries are evicted.
  final int maxEntries;

  final LinkedHashMap<String, Widget> _entries =
      LinkedHashMap<String, Widget>();

  /// Shared cache instance used by widgets when no custom cache is supplied.
  static final MathWidgetCache shared = MathWidgetCache();

  /// Number of cached entries currently retained.
  int get length => _entries.length;

  /// Returns a cached widget for [key] and marks it as most recently used.
  Widget? get(String key) {
    final value = _entries.remove(key);
    if (value == null) {
      return null;
    }
    _entries[key] = value;
    return value;
  }

  /// Returns the cached widget for [key], or stores the result of [builder].
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

  /// Removes a single cached entry for [key].
  void evict(String key) => _entries.remove(key);

  /// Clears all cached entries.
  void clear() => _entries.clear();
}
