class Lesson {
  final String id;
  final String title;
  final String description;
  final String difficulty;
  final String pronunciationType;
  final int sceneCount;
  final List<String> sceneIds;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.pronunciationType,
    required this.sceneCount,
    this.sceneIds = const [],
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    final sceneIds = _stringList(json['scene_ids']);

    return Lesson(
      id: _string(json['id'] ?? json['lesson_id']),
      title: _string(
        json['title'] ?? json['lesson_name'] ?? json['name'],
      ),
      description: _string(
        json['description'] ?? json['scene_name'] ?? json['lesson_name'],
      ),
      difficulty: _string(json['difficulty'], fallback: 'unknown'),
      pronunciationType: _string(
        json['pronunciation_type'] ??
            json['target_phoneme_group'] ??
            json['target_prosody_type'],
      ),
      sceneCount: _int(
        json['scene_count'] ??
            json['sceneCount'] ??
            (sceneIds.isEmpty ? null : sceneIds.length),
      ),
      sceneIds: sceneIds,
    );
  }
}

class SceneItem {
  final String id;
  final String lessonId;
  final String title;
  final String duration;
  final int sentenceCount;
  final String pronunciationFocus;
  final bool completed;

  const SceneItem({
    required this.id,
    required this.lessonId,
    required this.title,
    required this.duration,
    required this.sentenceCount,
    required this.pronunciationFocus,
    required this.completed,
  });

  factory SceneItem.fromJson(Map<String, dynamic> json) {
    return SceneItem(
      id: _string(json['id'] ?? json['scene_id']),
      lessonId: _string(json['lesson_id']),
      title: _string(json['title'] ?? json['scene_name']),
      duration: _durationLabel(json['duration'] ?? json['duration_sec']),
      sentenceCount: _int(
        json['sentence_count'] ?? json['utterance_count'],
      ),
      pronunciationFocus: _string(
        json['pronunciation_focus'] ??
            json['target_phoneme_group'] ??
            json['target_prosody_type'],
        fallback: 'Practice',
      ),
      completed: _bool(json['completed']),
    );
  }
}

class PracticeSentence {
  final String id;
  final String sceneId;
  final String text;
  final String targetWord;
  final String videoUrl;
  final String clipFilename;

  const PracticeSentence({
    required this.id,
    required this.sceneId,
    required this.text,
    required this.targetWord,
    required this.videoUrl,
    this.clipFilename = '',
  });

  factory PracticeSentence.fromJson(Map<String, dynamic> json) {
    final clipFilename = _string(json['clip_filename']);

    return PracticeSentence(
      id: _string(json['id'] ?? json['utterance_id']),
      sceneId: _string(json['scene_id']),
      text: _string(
        json['text'] ??
            json['practice_text'] ??
            json['subtitle_text'] ??
            json['normalized_text'],
      ),
      targetWord: _string(
        json['target_word'] ??
            json['target_phoneme_group'] ??
            json['target_phoneme_group_raw'] ??
            json['target_prosody_type'],
      ),
      videoUrl: _string(json['video_url'] ?? json['clip_url']),
      clipFilename: clipFilename,
    );
  }
}

class Utterance extends PracticeSentence {
  final String lessonId;
  final String lessonName;
  final String sceneName;
  final double clipStartSec;
  final double clipEndSec;
  final double pauseSec;
  final String subtitleText;
  final String practiceText;
  final String normalizedText;
  final String difficulty;
  final String targetProsodyType;

  const Utterance({
    required super.id,
    required super.sceneId,
    required super.text,
    required super.targetWord,
    required super.videoUrl,
    super.clipFilename,
    required this.lessonId,
    required this.lessonName,
    required this.sceneName,
    required this.clipStartSec,
    required this.clipEndSec,
    required this.pauseSec,
    required this.subtitleText,
    required this.practiceText,
    required this.normalizedText,
    required this.difficulty,
    required this.targetProsodyType,
  });

  factory Utterance.fromJson(Map<String, dynamic> json) {
    final sentence = PracticeSentence.fromJson(json);

    return Utterance(
      id: sentence.id,
      sceneId: sentence.sceneId,
      text: sentence.text,
      targetWord: sentence.targetWord,
      videoUrl: sentence.videoUrl,
      clipFilename: sentence.clipFilename,
      lessonId: _string(json['lesson_id']),
      lessonName: _string(json['lesson_name']),
      sceneName: _string(json['scene_name']),
      clipStartSec: _double(json['clip_start_sec']),
      clipEndSec: _double(json['clip_end_sec']),
      pauseSec: _double(json['pause_sec']),
      subtitleText: _string(json['subtitle_text']),
      practiceText: _string(json['practice_text']),
      normalizedText: _string(json['normalized_text']),
      difficulty: _string(json['difficulty'], fallback: 'unknown'),
      targetProsodyType: _string(json['target_prosody_type']),
    );
  }
}

class Attempt {
  final String id;
  final String sentenceText;
  final String date;
  final int overallScore;
  final int consonantScore;
  final int vowelScore;
  final int intonationScore;
  final String status;
  final String utteranceId;
  final String lessonId;
  final String sceneId;
  final String pronunciationFocus;

  const Attempt({
    required this.id,
    required this.sentenceText,
    required this.date,
    required this.overallScore,
    required this.consonantScore,
    required this.vowelScore,
    required this.intonationScore,
    this.status = '',
    this.utteranceId = '',
    this.lessonId = '',
    this.sceneId = '',
    this.pronunciationFocus = '',
  });

  factory Attempt.fromJson(Map<String, dynamic> json) {
    final pronunciationScore = _int(
      json['pronunciation_score'] ?? json['phoneme_score'] ?? json['score'],
    );

    return Attempt(
      id: _string(json['id'] ?? json['attempt_id']),
      sentenceText: _string(
        json['sentenceText'] ??
            json['sentence_text'] ??
            json['practice_text'] ??
            json['subtitle_text'] ??
            json['normalized_text'],
      ),
      date: _dateOnly(json['date'] ?? json['created_at'] ?? json['updated_at']),
      overallScore: _int(json['overallScore'] ?? json['overall_score'] ?? json['score']),
      consonantScore: _int(
        json['consonantScore'] ?? json['consonant_score'] ?? pronunciationScore,
      ),
      vowelScore: _int(json['vowelScore'] ?? json['vowel_score'] ?? pronunciationScore),
      intonationScore: _int(
        json['intonationScore'] ?? json['intonation_score'] ?? json['pitch_score'],
      ),
      status: _string(json['status']),
      utteranceId: _string(json['utterance_id']),
      lessonId: _string(json['lessonId'] ?? json['lesson_id']),
      sceneId: _string(json['sceneId'] ?? json['scene_id']),
      pronunciationFocus: _string(
        json['pronunciationFocus'] ??
            json['pronunciation_focus'] ??
            json['target_phoneme_group_raw'] ??
            json['target_phoneme_group'] ??
            json['target_prosody_type'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sentenceText': sentenceText,
      'date': date,
      'overallScore': overallScore,
      'consonantScore': consonantScore,
      'vowelScore': vowelScore,
      'intonationScore': intonationScore,
      'status': status,
      'utteranceId': utteranceId,
      'lessonId': lessonId,
      'sceneId': sceneId,
      'pronunciationFocus': pronunciationFocus,
    };
  }
}

class AttemptStartResponse {
  final String attemptId;
  final String userId;
  final String utteranceId;
  final String status;

  const AttemptStartResponse({
    required this.attemptId,
    required this.userId,
    required this.utteranceId,
    required this.status,
  });

  factory AttemptStartResponse.fromJson(Map<String, dynamic> json) {
    return AttemptStartResponse(
      attemptId: _string(json['attempt_id'] ?? json['id']),
      userId: _string(json['user_id']),
      utteranceId: _string(json['utterance_id']),
      status: _string(json['status'], fallback: 'started'),
    );
  }
}

class AttemptStatus {
  final String attemptId;
  final String userId;
  final String utteranceId;
  final String status;
  final String message;
  final String? error;

  const AttemptStatus({
    required this.attemptId,
    required this.userId,
    required this.utteranceId,
    required this.status,
    required this.message,
    this.error,
  });

  bool get isComplete => const {
        'complete',
        'completed',
        'done',
        'ready',
        'success',
      }.contains(status);

  bool get isFailed => const {'failed', 'error'}.contains(status);

  factory AttemptStatus.fromJson(Map<String, dynamic> json) {
    return AttemptStatus(
      attemptId: _string(json['attempt_id'] ?? json['id']),
      userId: _string(json['user_id']),
      utteranceId: _string(json['utterance_id']),
      status: _string(json['status']).toLowerCase(),
      message: _string(json['message']),
      error: json['error']?.toString(),
    );
  }
}

class AttemptResult {
  final String attemptId;
  final String userId;
  final String utteranceId;
  final String status;
  final int overallScore;
  final int pronunciationScore;
  final int pitchScore;
  final String transcript;
  final String practiceText;
  final String normalizedText;
  final String lessonId;
  final String sceneId;
  final String error;

  const AttemptResult({
    required this.attemptId,
    required this.userId,
    required this.utteranceId,
    required this.status,
    required this.overallScore,
    required this.pronunciationScore,
    required this.pitchScore,
    required this.transcript,
    required this.practiceText,
    required this.normalizedText,
    required this.lessonId,
    required this.sceneId,
    required this.error,
  });

  factory AttemptResult.fromJson(Map<String, dynamic> json) {
    return AttemptResult(
      attemptId: _string(json['attempt_id'] ?? json['id']),
      userId: _string(json['user_id']),
      utteranceId: _string(json['utterance_id']),
      status: _string(json['status']),
      overallScore: _int(json['overall_score'] ?? json['score']),
      pronunciationScore: _int(
        json['pronunciation_score'] ?? json['phoneme_score'] ?? json['score'],
      ),
      pitchScore: _int(json['pitch_score'] ?? json['intonation_score']),
      transcript: _string(json['transcript']),
      practiceText: _string(json['practice_text'] ?? json['subtitle_text']),
      normalizedText: _string(json['normalized_text']),
      lessonId: _string(json['lesson_id']),
      sceneId: _string(json['scene_id']),
      error: _string(json['error']),
    );
  }
}

class PhonemeDetail {
  final String symbol;
  final int score;
  final String expected;
  final String actual;
  final String note;

  const PhonemeDetail({
    required this.symbol,
    required this.score,
    required this.expected,
    required this.actual,
    required this.note,
  });

  factory PhonemeDetail.fromJson(Map<String, dynamic> json) {
    return PhonemeDetail(
      symbol: _string(json['symbol'] ?? json['phoneme'] ?? json['expected']),
      score: _int(json['score']),
      expected: _string(json['expected']),
      actual: _string(json['actual']),
      note: _string(json['note'] ?? json['message']),
    );
  }
}

class PitchDetail {
  final int score;
  final String summary;
  final List<double> referenceContour;
  final List<double> userContour;
  final String expectedPattern;
  final String endingPattern;
  final bool endingPatternMatch;
  final double dtwDistance;
  final double speechRate;
  final int rhythmScore;
  final int prosodyScore;
  final String diagnosisTitle;
  final String diagnosisMessage;
  final List<String> practiceTips;
  final Map<String, dynamic> rawJson;

  const PitchDetail({
    required this.score,
    required this.summary,
    required this.referenceContour,
    required this.userContour,
    this.expectedPattern = '',
    this.endingPattern = '',
    this.endingPatternMatch = false,
    this.dtwDistance = 0,
    this.speechRate = 0,
    this.rhythmScore = 0,
    this.prosodyScore = 0,
    this.diagnosisTitle = '',
    this.diagnosisMessage = '',
    this.practiceTips = const [],
    this.rawJson = const {},
  });

  factory PitchDetail.fromJson(Map<String, dynamic> json) {
    final prosody = _map(json['prosody']);

    return PitchDetail(
      score: _int(
        json['score'] ?? prosody['pitch_similarity'] ?? json['pitch_score'],
      ),
      summary: _string(
        json['summary'] ?? prosody['reason'] ?? json['reason'],
      ),
      referenceContour: _doubleList(
        json['reference_contour'] ??
            json['reference_pitch_json'] ??
            json['reference'],
      ),
      userContour: _doubleList(
        json['user_contour'] ?? json['learner_pitch_json'] ?? json['user'],
      ),
      expectedPattern: _string(json['expected_pattern']),
      endingPattern: _string(json['ending_pattern']),
      endingPatternMatch: _bool(json['ending_pattern_match']),
      dtwDistance: _double(json['dtw_distance']),
      speechRate: _double(json['speech_rate']),
      rhythmScore: _int(json['rhythm_score']),
      prosodyScore: _int(json['prosody_score'] ?? json['score']),
      diagnosisTitle: _string(json['diagnosis_title'] ?? json['summary']),
      diagnosisMessage: _string(json['diagnosis_message'] ?? json['summary']),
      practiceTips: _stringList(json['practice_tips'] ?? json['hint_json']),
      rawJson: json,
    );
  }
}

class AttemptFeedback {
  final String praise;
  final String improvement;
  final String tip;
  final String feedbackType;
  final String feedbackMessage;

  const AttemptFeedback({
    required this.praise,
    required this.improvement,
    required this.tip,
    this.feedbackType = '',
    this.feedbackMessage = '',
  });

  factory AttemptFeedback.fromJson(Map<String, dynamic> json) {
    return AttemptFeedback(
      praise: _string(json['praise']),
      improvement: _string(json['improvement'] ?? json['improvement_point']),
      tip: _string(json['tip'] ?? json['practice_tip']),
      feedbackType: _string(json['feedback_type']),
      feedbackMessage: _string(json['feedback_message']),
    );
  }
}

class PhonemeErrorRange {
  final int start;
  final int end;
  final String label;
  final String message;
  final String severity;

  const PhonemeErrorRange({
    required this.start,
    required this.end,
    required this.label,
    required this.message,
    required this.severity,
  });

  factory PhonemeErrorRange.fromJson(Map<String, dynamic> json) {
    return PhonemeErrorRange(
      start: _int(json['start']),
      end: _int(json['end']),
      label: _string(json['label']),
      message: _string(json['message']),
      severity: _string(json['severity'], fallback: 'warning'),
    );
  }
}

class PitchAnalysisResult {
  final List<double> referencePitch;
  final List<double> learnerPitch;
  final String expectedPattern;
  final String learnerPattern;
  final bool endingPatternMatch;
  final double dtwDistance;
  final double speechRate;
  final int rhythmScore;
  final int prosodyScore;
  final String diagnosisTitle;
  final String diagnosisMessage;
  final List<String> practiceTips;

  const PitchAnalysisResult({
    required this.referencePitch,
    required this.learnerPitch,
    required this.expectedPattern,
    required this.learnerPattern,
    required this.endingPatternMatch,
    required this.dtwDistance,
    required this.speechRate,
    required this.rhythmScore,
    required this.prosodyScore,
    required this.diagnosisTitle,
    required this.diagnosisMessage,
    required this.practiceTips,
  });

  factory PitchAnalysisResult.fromJson(Map<String, dynamic> json) {
    return PitchAnalysisResult(
      referencePitch: _doubleList(
        json['reference_pitch_json'] ?? json['reference_contour'],
      ),
      learnerPitch: _doubleList(
        json['learner_pitch_json'] ?? json['user_contour'],
      ),
      expectedPattern: _string(json['expected_pattern']),
      learnerPattern: _string(json['ending_pattern'] ?? json['learner_pattern']),
      endingPatternMatch: _bool(json['ending_pattern_match']),
      dtwDistance: _double(json['dtw_distance']),
      speechRate: _double(json['speech_rate']),
      rhythmScore: _int(json['rhythm_score']),
      prosodyScore: _int(json['prosody_score'] ?? json['score']),
      diagnosisTitle: _string(json['diagnosis_title'] ?? json['summary']),
      diagnosisMessage: _string(json['diagnosis_message'] ?? json['reason']),
      practiceTips: _stringList(json['hint_json'] ?? json['practice_tips']),
    );
  }
}

class AttemptAnalysisResult {
  final String attemptId;
  final String sentenceId;
  final String targetText;
  final String predictedText;
  final int overallScore;
  final int consonantScore;
  final int vowelScore;
  final int intonationScore;
  final String summaryTitle;
  final String summaryMessage;
  final List<PhonemeErrorRange> errorRanges;
  final PitchAnalysisResult pitchAnalysis;
  final String praiseFeedback;
  final String correctionFeedback;
  final String practiceFeedback;

  const AttemptAnalysisResult({
    required this.attemptId,
    required this.sentenceId,
    required this.targetText,
    required this.predictedText,
    required this.overallScore,
    required this.consonantScore,
    required this.vowelScore,
    required this.intonationScore,
    required this.summaryTitle,
    required this.summaryMessage,
    required this.errorRanges,
    required this.pitchAnalysis,
    required this.praiseFeedback,
    required this.correctionFeedback,
    required this.practiceFeedback,
  });

  factory AttemptAnalysisResult.fromJson(Map<String, dynamic> json) {
    final pitchJson = _map(json['pitch_analysis'] ?? json['pitch']);
    final pronunciationScore = _int(
      json['pronunciation_score'] ?? json['phoneme_score'] ?? json['score'],
    );

    return AttemptAnalysisResult(
      attemptId: _string(json['attempt_id'] ?? json['id']),
      sentenceId: _string(json['sentence_id'] ?? json['utterance_id']),
      targetText: _string(
        json['target_text'] ?? json['practice_text'] ?? json['subtitle_text'],
      ),
      predictedText: _string(json['predicted_text'] ?? json['transcript']),
      overallScore: _int(json['overall_score'] ?? json['score']),
      consonantScore: _int(
        json['consonant_score'] ?? json['consonantScore'] ?? pronunciationScore,
      ),
      vowelScore: _int(json['vowel_score'] ?? json['vowelScore'] ?? pronunciationScore),
      intonationScore: _int(
        json['intonation_score'] ?? json['pitch_score'] ?? json['intonationScore'],
      ),
      summaryTitle: _string(json['summary_title'] ?? json['feedback_type']),
      summaryMessage: _string(json['summary_message'] ?? json['feedback_message']),
      errorRanges: _mapList(json['error_ranges'])
          .map(PhonemeErrorRange.fromJson)
          .toList(),
      pitchAnalysis: PitchAnalysisResult.fromJson(pitchJson),
      praiseFeedback: _string(json['praise_feedback'] ?? json['praise']),
      correctionFeedback: _string(
        json['correction_feedback'] ?? json['improvement'],
      ),
      practiceFeedback: _string(json['practice_feedback'] ?? json['tip']),
    );
  }
}

class UserProfile {
  final String userId;
  final String nickname;

  const UserProfile({
    required this.userId,
    required this.nickname,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final profile = _map(json['profile']);

    return UserProfile(
      userId: _string(json['user_id'] ?? profile['user_id']),
      nickname: _string(json['nickname'] ?? profile['nickname']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'nickname': nickname,
    };
  }
}

String _string(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _double(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

bool _bool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase();
  return text == 'true' || text == '1' || text == 'yes';
}

String _durationLabel(Object? value) {
  if (value is String && value.contains(':')) return value;
  final seconds = _int(value);
  if (seconds <= 0) return '00:00';
  final minutesPart = (seconds ~/ 60).toString().padLeft(2, '0');
  final secondsPart = (seconds % 60).toString().padLeft(2, '0');
  return '$minutesPart:$secondsPart';
}

String _dateOnly(Object? value) {
  final text = _string(value);
  if (text.length >= 10) return text.substring(0, 10);
  return text;
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, item) => MapEntry(key.toString(), item));
  return const {};
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List) return const [];
  return value.map(_map).where((item) => item.isNotEmpty).toList();
}

List<double> _doubleList(Object? value) {
  if (value is! List) return const [];
  return value.map(_double).toList();
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value.map((item) => item.toString()).toList();
}
