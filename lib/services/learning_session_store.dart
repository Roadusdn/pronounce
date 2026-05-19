import 'package:flutter/foundation.dart';

import '../models/pronunciation_models.dart';

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

      return AttemptAnalysisResult(
        attemptId: '',
        sentenceId: sentence.id,
        targetText: sentence.text,
        predictedText: '',
        overallScore: 0,
        consonantScore: 0,
        vowelScore: 0,
        intonationScore: 0,
        summaryTitle: '분석 결과 없음',
        summaryMessage: '아직 이 문장에 대한 분석 결과가 없습니다.',
        errorRanges: const [],
        pitchAnalysis: const PitchAnalysisResult(
          referencePitch: [],
          learnerPitch: [],
          expectedPattern: '',
          learnerPattern: '',
          endingPatternMatch: false,
          dtwDistance: 0,
          speechRate: 0,
          rhythmScore: 0,
          prosodyScore: 0,
          diagnosisTitle: '억양 분석 결과 없음',
          diagnosisMessage: '아직 억양 분석 데이터가 없습니다.',
          practiceTips: [],
        ),
        praiseFeedback: '',
        correctionFeedback: '',
        practiceFeedback: '',
      );
    }).toList();
  }
}
