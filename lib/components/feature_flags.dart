import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:go_feature_flag/go_feature_flag.dart';
import 'package:material_helper/material_helper.dart';
import 'package:openfeature_dart_server_sdk/client.dart';
import 'package:openfeature_dart_server_sdk/evaluation_context.dart';
import 'package:openfeature_dart_server_sdk/open_feature_api.dart';

import '../main.dart';

class FeatureFlags {
  static late final FeatureClient? client;
  static String get _targetingKey {
    final existingKey = prefs?.getString("targetingKey");
    if (existingKey != null) return existingKey;

    final randomChars =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

    final rng = Random.secure();
    final newKey = StringBuffer();
    for (var i = 0; i < 32; i++) {
      newKey.write(randomChars[rng.nextInt(randomChars.length)]);
    }
    prefs?.setString("targetingKey", newKey.toString());
    return newKey.toString();
  }

  static Future<void> setup() async {
    if (Env.flagsBase == null) {
      client = null;
      return;
    }
    final api = OpenFeatureAPI();
    await api.setProviderAndWait(
      GoFeatureFlagProvider(
        GoFeatureFlagOptions(
          endpoint: Env.flagsBase!,
          disableCache: kDebugMode,
        ),
      ),
    );
    client = api.getClient("PGPtouch");
  }

  // MARK: Flags

  static EvaluationContext get _context => EvaluationContext.immutable(
    targetingKey: _targetingKey,
    attributes: {"beta": prefs?.getBool("beta") ?? false},
  );

  static Future<bool> isGeneralBeta() =>
      client?.getBooleanValue("beta", defaultValue: false, context: _context) ??
      Future.value(false);

  static Future<Map<String, Object>> get values async =>
      Map.unmodifiableOf({"generalBeta": await isGeneralBeta()});
}

class FeatureFlagsFixedCache {
  final bool generalBeta;

  final Map<String, Object?> values;

  FeatureFlagsFixedCache._({required this.generalBeta, required this.values});
  static Future<void> createInstance() async {
    final values = await FeatureFlags.values;
    _instance = FeatureFlagsFixedCache._(
      generalBeta: values["generalBeta"]! as bool,
      values: values,
    );
  }

  static FeatureFlagsFixedCache? _instance;
  static FeatureFlagsFixedCache get instance => _instance!;
}
