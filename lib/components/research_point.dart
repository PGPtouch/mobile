import 'package:aptabase_flutter/aptabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:material_helper/material_helper.dart';

import '../main.dart';

/// Anonymous, opt-in usage statistics.
///
/// Rules for every event tracked through this class:
/// * Only coarse outcomes, enum names, counts and durations. Never key
///   material, fingerprints, user IDs, e-mail addresses, search queries, file
///   names or raw exception messages.
/// * One event per user-visible action (not per internal state change).
/// * Property values are strings or numbers; booleans are sent as 0/1.
class ResearchPoint {
  static bool get enabled => prefs?.getBool("researchEnabled") ?? kDebugMode;

  static Future<void> trackEvent(
    String eventName, [
    Map<String, Object?>? props,
  ]) async {
    if (prefs == null || Env.trackKey == null || Env.trackBase == null) return;
    if (enabled) {
      Aptabase.instance.trackEvent(eventName, _sanitize(props));
    }
  }

  static Map<String, dynamic>? _sanitize(Map<String, Object?>? props) {
    if (props == null) return null;
    return {
      for (final entry in props.entries)
        if (entry.value case final bool flag)
          entry.key: flag ? 1 : 0
        else if (entry.value is String || entry.value is num)
          entry.key: entry.value,
    };
  }
}
