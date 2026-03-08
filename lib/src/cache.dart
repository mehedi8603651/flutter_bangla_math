import 'dart:collection';

import 'package:flutter/widgets.dart';

typedef _MathWidgetFactory = Widget Function();

/// A small LRU cache for reusable math widget factories.
///
/// The cache is keyed by a string that typically includes the TeX source plus
/// the layout parameters used to render it. Each cache hit returns a fresh
/// widget instance so repeated formulas can appear multiple times in the same
/// tree without GlobalKey collisions inside `flutter_math_fork`.
class MathWidgetCache {
  /// Creates a cache with an upper bound on stored entries.
  MathWidgetCache({this.maxEntries = 128})
      : assert(maxEntries > 0, 'maxEntries must be positive.');

  /// Maximum number of cached math builders retained before older entries are
  /// evicted.
  final int maxEntries;

  final LinkedHashMap<String, _MathWidgetFactory> _entries =
      LinkedHashMap<String, _MathWidgetFactory>();

  /// Shared cache instance used by widgets when no custom cache is supplied.
  static final MathWidgetCache shared = MathWidgetCache();

  /// Number of cached entries currently retained.
  int get length => _entries.length;

  /// Returns a fresh widget built from the cached entry for [key] and marks it
  /// as most recently used.
  Widget? get(String key) {
    final factory = _entries.remove(key);
    if (factory == null) {
      return null;
    }
    _entries[key] = factory;
    return factory();
  }

  /// Returns a fresh widget for [key], or stores [builder] for future use.
  Widget putIfAbsent(String key, Widget Function() builder) {
    final cached = get(key);
    if (cached != null) {
      return cached;
    }

    _entries[key] = builder;

    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }

    return builder();
  }

  /// Removes a single cached entry for [key].
  void evict(String key) => _entries.remove(key);

  /// Clears all cached entries.
  void clear() => _entries.clear();
}
