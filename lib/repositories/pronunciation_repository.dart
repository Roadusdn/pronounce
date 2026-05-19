import 'dart:io';

import '../api/pronunciation_api_client.dart';
import '../models/pronunciation_models.dart';

class LessonSceneBundle {
  final Lesson lesson;
  final List<SceneItem> scenes;
  final Map<String, List<PracticeSentence>> sentencesBySceneId;

  const LessonSceneBundle({
    required this.lesson,
    required this.scenes,
    required this.sentencesBySceneId,
  });

  int get totalSentenceCount {
    return scenes.fold<int>(0, (sum, scene) => sum + scene.sentenceCount);
  }
}

class PronunciationRepository {
  PronunciationRepository({PronunciationApiClient? apiClient})
    : _apiClient = apiClient ?? PronunciationApiClient();

  static final PronunciationRepository instance = PronunciationRepository();

  final PronunciationApiClient _apiClient;

  Future<List<Lesson>> getLessons() async {
    final lessons = await _apiClient.getLessons();
    return lessons
        .map((lesson) {
          final sceneCount = lesson.sceneCount > 0
              ? lesson.sceneCount
              : lesson.sceneIds.length;

          return Lesson(
            id: lesson.id,
            title: lesson.title,
            description: lesson.description,
            difficulty: lesson.difficulty,
            pronunciationType: lesson.pronunciationType,
            sceneCount: sceneCount,
            sceneIds: lesson.sceneIds,
          );
        })
        .where((lesson) => lesson.id.isNotEmpty)
        .toList();
  }

  Future<Lesson> getLesson(String lessonId) {
    return _apiClient.getLesson(lessonId);
  }

  Future<List<PracticeSentence>> getSentencesForScene(String sceneId) async {
    final utterances = await _apiClient.getSceneUtterances(sceneId);
    return utterances
        .map(
          (utterance) => PracticeSentence(
            id: utterance.id,
            sceneId: utterance.sceneId,
            text: utterance.practiceText.isNotEmpty
                ? utterance.practiceText
                : utterance.text,
            targetWord: utterance.targetWord,
            videoUrl: _absoluteClipUrl(_clipUrlFromUtterance(utterance)),
            clipFilename: utterance.clipFilename,
          ),
        )
        .where((sentence) => sentence.id.isNotEmpty)
        .toList();
  }

  Future<LessonSceneBundle> getLessonSceneBundle(String lessonId) async {
    final lesson = await _apiClient.getLesson(lessonId);
    final apiScenes = await _apiClient.getLessonScenes(lessonId);
    final sceneIds = apiScenes.isNotEmpty
        ? apiScenes.map((scene) => scene.id).toList()
        : lesson.sceneIds;

    final sceneEntries = <_SceneEntry>[];

    for (var index = 0; index < sceneIds.length; index++) {
      final sceneId = sceneIds[index];
      final scene = apiScenes.isNotEmpty
          ? apiScenes[index]
          : await _apiClient.getScene(sceneId);
      final sentences = await getSentencesForScene(sceneId);
      sceneEntries.add(
        _SceneEntry(
          scene: _withDerivedSceneFields(scene, sentences),
          sentences: sentences,
        ),
      );
    }

    return LessonSceneBundle(
      lesson: Lesson(
        id: lesson.id,
        title: lesson.title,
        description: lesson.description,
        difficulty: lesson.difficulty,
        pronunciationType: lesson.pronunciationType,
        sceneCount: sceneEntries.length,
        sceneIds: sceneIds,
      ),
      scenes: sceneEntries.map((entry) => entry.scene).toList(),
      sentencesBySceneId: {
        for (final entry in sceneEntries) entry.scene.id: entry.sentences,
      },
    );
  }

  Future<AttemptAnalysisResult> analyzeRecording({
    required String lessonId,
    required String sceneId,
    required PracticeSentence sentence,
    required File audioFile,
  }) async {
    final attempt = await _apiClient.startAttempt(
      utteranceId: sentence.id,
      lessonId: lessonId,
      sceneId: sceneId,
    );
    final uploadJson = await _apiClient.uploadAttemptAudio(
      attemptId: attempt.attemptId,
      audioBytes: await audioFile.readAsBytes(),
      filename: audioFile.uri.pathSegments.isEmpty
          ? 'recording.m4a'
          : audioFile.uri.pathSegments.last,
    );

    final result = AttemptResult.fromJson(uploadJson);
    final phonemeDetails = await _tryLoadPhonemes(attempt.attemptId);
    final pitch = await _tryLoadPitch(attempt.attemptId);
    final feedback = await _tryLoadFeedback(attempt.attemptId);

    return _analysisFromBackendParts(
      sentence: sentence,
      result: result,
      phonemeDetails: phonemeDetails,
      pitch: pitch,
      feedback: feedback,
    );
  }

  Future<String> transcribeRecording(File audioFile) async {
    return _apiClient.transcribeAudio(
      audioBytes: await audioFile.readAsBytes(),
      filename: audioFile.uri.pathSegments.isEmpty
          ? 'recording.m4a'
          : audioFile.uri.pathSegments.last,
    );
  }

  Future<void> clearBackendAttempts({String userId = 'local_user'}) {
    return _apiClient.deleteAttempts(userId: userId);
  }

  Future<List<PhonemeDetail>> _tryLoadPhonemes(String attemptId) async {
    try {
      return await _apiClient.getAttemptPhoneme(attemptId);
    } catch (_) {
      return const [];
    }
  }

  Future<PitchDetail> _tryLoadPitch(String attemptId) async {
    try {
      return await _apiClient.getAttemptPitch(attemptId);
    } catch (_) {
      return const PitchDetail(
        score: 0,
        summary: '',
        referenceContour: [],
        userContour: [],
      );
    }
  }

  Future<AttemptFeedback> _tryLoadFeedback(String attemptId) async {
    try {
      return await _apiClient.getAttemptFeedback(attemptId);
    } catch (_) {
      return const AttemptFeedback(praise: '', improvement: '', tip: '');
    }
  }

  AttemptAnalysisResult _analysisFromBackendParts({
    required PracticeSentence sentence,
    required AttemptResult result,
    required List<PhonemeDetail> phonemeDetails,
    required PitchDetail pitch,
    required AttemptFeedback feedback,
  }) {
    final pronunciationScore = result.pronunciationScore;

    return AttemptAnalysisResult(
      attemptId: result.attemptId,
      sentenceId: result.utteranceId.isEmpty ? sentence.id : result.utteranceId,
      targetText: result.practiceText.isNotEmpty
          ? result.practiceText
          : sentence.text,
      predictedText: result.transcript,
      overallScore: result.overallScore,
      consonantScore: pronunciationScore,
      vowelScore: pronunciationScore,
      intonationScore: result.pitchScore,
      summaryTitle: feedback.feedbackType.isNotEmpty
          ? _feedbackTitle(feedback.feedbackType)
          : _scoreTitle(result.overallScore),
      summaryMessage: feedback.feedbackMessage.isNotEmpty
          ? feedback.feedbackMessage
          : feedback.improvement,
      errorRanges: _errorRangesFromPhonemes(phonemeDetails),
      pitchAnalysis: PitchAnalysisResult(
        referencePitch: pitch.referenceContour,
        learnerPitch: pitch.userContour,
        expectedPattern: pitch.expectedPattern,
        learnerPattern: pitch.endingPattern,
        endingPatternMatch: pitch.endingPatternMatch,
        dtwDistance: pitch.dtwDistance,
        speechRate: pitch.speechRate,
        rhythmScore: pitch.rhythmScore,
        prosodyScore: pitch.prosodyScore > 0 ? pitch.prosodyScore : pitch.score,
        diagnosisTitle: _pitchDiagnosisTitle(pitch),
        diagnosisMessage: _pitchDiagnosisMessage(pitch),
        practiceTips: [
          for (final tip in pitch.practiceTips)
            if (_cleanPitchText(tip).isNotEmpty) _cleanPitchText(tip),
          if (feedback.tip.isNotEmpty) feedback.tip,
        ],
      ),
      praiseFeedback: _usefulFeedback(feedback.praise)
          ? feedback.praise
          : _praiseForResult(result),
      correctionFeedback: feedback.improvement.isNotEmpty
          ? feedback.improvement
          : feedback.feedbackMessage,
      practiceFeedback: feedback.tip.isNotEmpty
          ? feedback.tip
          : _practiceTipForResult(result),
    );
  }

  List<PhonemeErrorRange> _errorRangesFromPhonemes(
    List<PhonemeDetail> phonemeDetails,
  ) {
    return [
      for (var i = 0; i < phonemeDetails.length; i++)
        PhonemeErrorRange(
          start: 0,
          end: 0,
          label: phonemeDetails[i].symbol,
          message: phonemeDetails[i].note,
          severity: 'warning',
        ),
    ];
  }

  String _scoreTitle(int score) {
    if (score >= 90) return '아주 좋아요';
    if (score >= 80) return '좋아요';
    if (score >= 70) return '조금 더 연습해요';
    return '다시 연습해요';
  }

  String _feedbackTitle(String value) {
    switch (value) {
      case 'excellent':
        return '아주 좋아요';
      case 'good':
        return '좋아요';
      case 'needs_practice':
        return '다시 연습해요';
      case 'vowel_group':
        return '모음 연습';
      case 'siot_group':
        return '시옷 발음 연습';
      case 'ae_e_group':
        return '애/에 발음 연습';
      default:
        return '발음 분석';
    }
  }

  String _pitchDiagnosisTitle(PitchDetail pitch) {
    final title = _cleanPitchText(pitch.diagnosisTitle);
    if (title.isNotEmpty) return title;
    if (pitch.score >= 90) return '억양이 안정적이에요';
    if (pitch.score >= 75) return '억양 흐름이 괜찮아요';
    if (pitch.summary.isNotEmpty) return '억양을 다시 확인해보세요';
    return '억양 분석';
  }

  String _pitchDiagnosisMessage(PitchDetail pitch) {
    final message = _cleanPitchText(pitch.diagnosisMessage);
    if (message.isNotEmpty) return message;
    final summary = _cleanPitchText(pitch.summary);
    if (summary.isNotEmpty) return summary;
    if (pitch.score >= 90) {
      return '기준 발음과 비슷한 높낮이로 자연스럽게 말했어요.';
    }
    if (pitch.score >= 75) {
      return '문장 끝 억양과 전체 리듬을 조금 더 맞춰보세요.';
    }
    return '예문을 들으며 문장 끝을 같은 방향으로 따라 말해보세요.';
  }

  String _cleanPitchText(String value) {
    final text = value.trim();
    if (text.isEmpty) return '';
    return text;
  }

  String _praiseForResult(AttemptResult result) {
    if (result.overallScore >= 90) {
      if (result.pitchScore >= 90) {
        return '발음과 억양이 모두 안정적이에요. 문장 흐름을 자연스럽게 잘 살렸습니다.';
      }
      return '발음 정확도가 아주 좋아요. 소리 하나하나가 또렷하게 전달됐습니다.';
    }
    if (result.overallScore >= 80) {
      if (result.pronunciationScore >= result.pitchScore) {
        return '발음은 전반적으로 잘 맞았어요. 문장 끝 억양만 조금 더 다듬어보면 좋아요.';
      }
      return '억양 흐름이 좋아요. 몇몇 발음만 더 또렷하게 말하면 더 자연스러워집니다.';
    }
    if (result.overallScore >= 70) {
      return '핵심 문장은 잘 따라왔어요. 헷갈린 소리만 천천히 다시 짚어보면 좋아요.';
    }
    return '끝까지 녹음한 점이 좋아요. 이번에는 속도를 조금 늦추고 한 음절씩 또박또박 연습해봐요.';
  }

  String _practiceTipForResult(AttemptResult result) {
    if (result.pitchScore > 0 &&
        result.pitchScore < result.pronunciationScore) {
      return '예문을 들으며 문장 끝 높낮이를 먼저 따라 한 뒤 전체 문장을 다시 말해보세요.';
    }
    return '예문과 같은 속도로 한 번, 조금 느린 속도로 한 번 더 반복해보세요.';
  }

  bool _usefulFeedback(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return normalized != 'analysis completed.' && normalized != '분석이 완료되었습니다.';
  }

  SceneItem _withDerivedSceneFields(
    SceneItem scene,
    List<PracticeSentence> sentences,
  ) {
    return SceneItem(
      id: scene.id,
      lessonId: scene.lessonId,
      title: scene.title,
      duration: scene.duration,
      sentenceCount: sentences.isEmpty ? scene.sentenceCount : sentences.length,
      pronunciationFocus: scene.pronunciationFocus,
      completed: scene.completed,
    );
  }

  String _absoluteClipUrl(String clipUrl) {
    if (clipUrl.isEmpty || clipUrl.startsWith('http')) {
      return clipUrl;
    }

    return _apiClient.baseUri.replace(path: clipUrl).toString();
  }

  String _clipUrlFromUtterance(Utterance utterance) {
    if (utterance.videoUrl.trim().isNotEmpty) {
      return utterance.videoUrl.trim();
    }

    final filename = utterance.clipFilename.trim();
    if (filename.isEmpty) return '';

    return '/api/clips/${Uri.encodeComponent(filename)}';
  }
}

class _SceneEntry {
  final SceneItem scene;
  final List<PracticeSentence> sentences;

  const _SceneEntry({required this.scene, required this.sentences});
}
