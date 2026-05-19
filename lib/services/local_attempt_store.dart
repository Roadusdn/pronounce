import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pronunciation_models.dart';

class LocalAttemptStore {
  LocalAttemptStore._();

  static const _key = 'local_attempts';
  static final ValueNotifier<List<Attempt>> attempts =
      ValueNotifier<List<Attempt>>(const []);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    if (raw == null || raw.isEmpty) {
      attempts.value = const [];
      return;
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final local = decoded
          .map((e) => Attempt.fromJson(e as Map<String, dynamic>))
          .toList();

      attempts.value = local;
    } catch (_) {
      attempts.value = const [];
    }
  }

  static Future<void> add(Attempt attempt) async {
    final updatedLocal = [
      attempt,
      ...attempts.value.where((item) => item.id != attempt.id),
    ];
    attempts.value = updatedLocal;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(updatedLocal.map((e) => e.toJson()).toList()),
    );
  }

  static bool hasLocalAttemptForSentence(String sentenceText) {
    return attempts.value.any((item) => item.sentenceText == sentenceText);
  }

  static bool hasLocalAttemptForScene(String sceneId) {
    if (sceneId.isEmpty) return false;
    return attempts.value.any((item) => item.sceneId == sceneId);
  }

  static List<Attempt> latestAttemptsByScene({int? limit}) {
    final seenKeys = <String>{};
    final latest = <Attempt>[];

    for (final attempt in attempts.value) {
      final key = attempt.sceneId.isNotEmpty
          ? attempt.sceneId
          : attempt.sentenceText;
      if (key.isEmpty || seenKeys.contains(key)) continue;

      seenKeys.add(key);
      latest.add(attempt);

      if (limit != null && latest.length >= limit) break;
    }

    return latest;
  }

  static List<Attempt> localOnly() {
    return attempts.value;
  }

  static Future<void> clearLocalOnly() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    attempts.value = const [];
  }
}
