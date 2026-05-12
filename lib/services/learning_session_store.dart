import 'package:flutter/foundation.dart';

import '../data/mock_data.dart';

class LearningSessionStore {
  LearningSessionStore._();

  static final ValueNotifier<Map<String, AttemptAnalysisResult>> _results =
  ValueNotifier<Map<String, AttemptAnalysisResult>>({});

  static void clear() {
    _results.value = {};
  }

  static void saveResult(AttemptAnalysisResult result) {
    final updated = Map<String, AttemptAnalysisResult>.from(_results.value);
    updated[result.sentenceId] = result;
    _results.value = updated;
  }

  static AttemptAnalysisResult? resultForSentence(String sentenceId) {
    return _results.value[sentenceId];
  }

  static List<AttemptAnalysisResult> resultsForSentences(
      List<PracticeSentence> targetSentences,
      ) {
    return targetSentences.map((sentence) {
      final stored = _results.value[sentence.id];

      if (stored != null) {
        return stored;
      }

      return analysisResultForSentence(sentence.id);
    }).toList();
  }
}