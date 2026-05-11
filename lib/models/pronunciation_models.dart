class Lesson {
  final String id;
  final String title;
  final String description;
  final String difficulty;
  final String sceneId;
  final int utteranceCount;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.sceneId,
    required this.utteranceCount,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: _string(json['id'] ?? json['lesson_id']),
      title: _string(json['title'] ?? json['name']),
      description: _string(json['description']),
      difficulty: _string(json['difficulty'], fallback: 'unknown'),
      sceneId: _string(
        json['scene_id'] ?? json['default_scene_id'] ?? json['id'],
      ),
      utteranceCount: _int(json['utterance_count'] ?? json['sentence_count']),
    );
  }
}

class Utterance {
  final String id;
  final String sceneId;
  final String clipFilename;
  final double pauseSec;
  final String subtitleText;
  final String practiceText;
  final String difficulty;

  const Utterance({
    required this.id,
    required this.sceneId,
    required this.clipFilename,
    required this.pauseSec,
    required this.subtitleText,
    required this.practiceText,
    required this.difficulty,
  });

  factory Utterance.fromJson(Map<String, dynamic> json) {
    return Utterance(
      id: _string(json['id'] ?? json['utterance_id']),
      sceneId: _string(json['scene_id']),
      clipFilename: _string(json['clip_filename']),
      pauseSec: _double(json['pause_sec']),
      subtitleText: _string(json['subtitle_text']),
      practiceText: _string(json['practice_text']),
      difficulty: _string(json['difficulty'], fallback: 'unknown'),
    );
  }
}

class AttemptStartResponse {
  final String attemptId;
  final String status;

  const AttemptStartResponse({
    required this.attemptId,
    required this.status,
  });

  factory AttemptStartResponse.fromJson(Map<String, dynamic> json) {
    return AttemptStartResponse(
      attemptId: _string(json['attempt_id'] ?? json['id']),
      status: _string(json['status'], fallback: 'started'),
    );
  }
}

class AttemptStatus {
  final String attemptId;
  final String status;
  final String message;

  const AttemptStatus({
    required this.attemptId,
    required this.status,
    required this.message,
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
      status: _string(json['status']).toLowerCase(),
      message: _string(json['message']),
    );
  }
}

class AttemptResult {
  final String attemptId;
  final int overallScore;
  final int pronunciationScore;
  final int pitchScore;
  final String transcript;

  const AttemptResult({
    required this.attemptId,
    required this.overallScore,
    required this.pronunciationScore,
    required this.pitchScore,
    required this.transcript,
  });

  factory AttemptResult.fromJson(Map<String, dynamic> json) {
    return AttemptResult(
      attemptId: _string(json['attempt_id'] ?? json['id']),
      overallScore: _int(json['overall_score'] ?? json['score']),
      pronunciationScore: _int(
        json['pronunciation_score'] ?? json['phoneme_score'],
      ),
      pitchScore: _int(json['pitch_score'] ?? json['intonation_score']),
      transcript: _string(json['transcript']),
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
      symbol: _string(json['symbol'] ?? json['phoneme']),
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

  const PitchDetail({
    required this.score,
    required this.summary,
    required this.referenceContour,
    required this.userContour,
  });

  factory PitchDetail.fromJson(Map<String, dynamic> json) {
    return PitchDetail(
      score: _int(json['score']),
      summary: _string(json['summary']),
      referenceContour: _doubleList(
        json['reference_contour'] ?? json['reference'],
      ),
      userContour: _doubleList(json['user_contour'] ?? json['user']),
    );
  }
}

class AttemptFeedback {
  final String praise;
  final String improvement;
  final String tip;

  const AttemptFeedback({
    required this.praise,
    required this.improvement,
    required this.tip,
  });

  factory AttemptFeedback.fromJson(Map<String, dynamic> json) {
    return AttemptFeedback(
      praise: _string(json['praise']),
      improvement: _string(json['improvement'] ?? json['improvement_point']),
      tip: _string(json['tip'] ?? json['practice_tip']),
    );
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

List<double> _doubleList(Object? value) {
  if (value is! List) return const [];
  return value.map(_double).toList();
}
