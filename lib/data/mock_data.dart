class Lesson {
  final String id;
  final String title;
  final String description;
  final String difficulty;
  final String pronunciationType;
  final int sceneCount;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.pronunciationType,
    required this.sceneCount,
  });
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
}

class PracticeSentence {
  final String id;
  final String sceneId;
  final String text;
  final String targetWord;
  final String videoUrl;

  const PracticeSentence({
    required this.id,
    required this.sceneId,
    required this.text,
    required this.targetWord,
    required this.videoUrl,
  });
}

class Attempt {
  final String id;
  final String sentenceText;
  final String date;
  final int overallScore;
  final int consonantScore;
  final int vowelScore;
  final int intonationScore;

  const Attempt({
    required this.id,
    required this.sentenceText,
    required this.date,
    required this.overallScore,
    required this.consonantScore,
    required this.vowelScore,
    required this.intonationScore,
  });

  factory Attempt.fromJson(Map<String, dynamic> json) {
    return Attempt(
      id: json['id'] as String? ?? '',
      sentenceText: json['sentenceText'] as String? ?? '',
      date: json['date'] as String? ?? '',
      overallScore: json['overallScore'] as int? ?? 0,
      consonantScore: json['consonantScore'] as int? ?? 0,
      vowelScore: json['vowelScore'] as int? ?? 0,
      intonationScore: json['intonationScore'] as int? ?? 0,
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
    };
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
      start: json['start'] as int,
      end: json['end'] as int,
      label: json['label'] as String? ?? '',
      message: json['message'] as String? ?? '',
      severity: json['severity'] as String? ?? 'warning',
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
      referencePitch: _toDoubleList(json['reference_pitch_json']),
      learnerPitch: _toDoubleList(json['learner_pitch_json']),
      expectedPattern: json['expected_pattern'] as String? ?? '',
      learnerPattern: json['ending_pattern'] as String? ?? '',
      endingPatternMatch: json['ending_pattern_match'] as bool? ?? false,
      dtwDistance: _toDouble(json['dtw_distance']),
      speechRate: _toDouble(json['speech_rate']),
      rhythmScore: json['rhythm_score'] as int? ?? 0,
      prosodyScore: json['prosody_score'] as int? ?? 0,
      diagnosisTitle: json['diagnosis_title'] as String? ?? '',
      diagnosisMessage: json['diagnosis_message'] as String? ?? '',
      practiceTips: _toStringList(json['hint_json']),
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
    final pitchJson = json['pitch_analysis'] as Map<String, dynamic>? ?? {};
    final errorsJson = json['error_ranges'] as List<dynamic>? ?? [];

    return AttemptAnalysisResult(
      attemptId: json['attempt_id'] as String? ?? '',
      sentenceId: json['sentence_id'] as String? ?? '',
      targetText: json['target_text'] as String? ?? '',
      predictedText: json['predicted_text'] as String? ?? '',
      overallScore: json['overall_score'] as int? ?? 0,
      consonantScore: json['consonant_score'] as int? ?? 0,
      vowelScore: json['vowel_score'] as int? ?? 0,
      intonationScore: json['intonation_score'] as int? ?? 0,
      summaryTitle: json['summary_title'] as String? ?? '',
      summaryMessage: json['summary_message'] as String? ?? '',
      errorRanges: errorsJson
          .map((e) => PhonemeErrorRange.fromJson(e as Map<String, dynamic>))
          .toList(),
      pitchAnalysis: PitchAnalysisResult.fromJson(pitchJson),
      praiseFeedback: json['praise_feedback'] as String? ?? '',
      correctionFeedback: json['correction_feedback'] as String? ?? '',
      practiceFeedback: json['practice_feedback'] as String? ?? '',
    );
  }
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

List<double> _toDoubleList(dynamic value) {
  if (value is! List) return const [];
  return value.map(_toDouble).toList();
}

List<String> _toStringList(dynamic value) {
  if (value is! List) return const [];
  return value.map((e) => e.toString()).toList();
}

const lessons = [
  Lesson(
    id: '1',
    title: '기본 인사 연습',
    description: '짧은 문장으로 자연스럽게 인사하기',
    difficulty: 'easy',
    pronunciationType: '모음',
    sceneCount: 2,
  ),
  Lesson(
    id: '2',
    title: '학교 생활 표현',
    description: '학교에서 자주 쓰는 표현 연습',
    difficulty: 'medium',
    pronunciationType: '억양',
    sceneCount: 3,
  ),
  Lesson(
    id: '3',
    title: '감정 표현하기',
    description: '상황에 맞는 말투와 억양 연습',
    difficulty: 'hard',
    pronunciationType: '받침',
    sceneCount: 2,
  ),
];

const scenes = [
  SceneItem(
    id: 's1',
    lessonId: '1',
    title: '첫 만남',
    duration: '00:28',
    sentenceCount: 3,
    pronunciationFocus: 'ㅓ/ㅗ 구분',
    completed: false,
  ),
  SceneItem(
    id: 's2',
    lessonId: '1',
    title: '친구에게 인사하기',
    duration: '00:34',
    sentenceCount: 3,
    pronunciationFocus: '받침 연음',
    completed: true,
  ),
  SceneItem(
    id: 's3',
    lessonId: '2',
    title: '수업 전 대화',
    duration: '00:41',
    sentenceCount: 4,
    pronunciationFocus: '질문 억양',
    completed: false,
  ),
  SceneItem(
    id: 's4',
    lessonId: '2',
    title: '발표 준비',
    duration: '00:37',
    sentenceCount: 3,
    pronunciationFocus: '문장 강세',
    completed: false,
  ),
  SceneItem(
    id: 's5',
    lessonId: '3',
    title: '놀람 표현',
    duration: '00:31',
    sentenceCount: 3,
    pronunciationFocus: '감정 억양',
    completed: false,
  ),
];

const sampleVideoUrl =
    'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';

const sentences = [
  PracticeSentence(
    id: 'p1',
    sceneId: 's1',
    text: '안녕하세요, 처음 뵙겠습니다.',
    targetWord: '처음',
    videoUrl: sampleVideoUrl,
  ),
  PracticeSentence(
    id: 'p2',
    sceneId: 's1',
    text: '만나서 정말 반가워요.',
    targetWord: '반가워요',
    videoUrl: sampleVideoUrl,
  ),
  PracticeSentence(
    id: 'p3',
    sceneId: 's1',
    text: '오늘 날씨가 참 좋네요.',
    targetWord: '좋네요',
    videoUrl: sampleVideoUrl,
  ),
  PracticeSentence(
    id: 'p4',
    sceneId: 's2',
    text: '오랜만이야, 잘 지냈어?',
    targetWord: '오랜만',
    videoUrl: sampleVideoUrl,
  ),
  PracticeSentence(
    id: 'p5',
    sceneId: 's3',
    text: '숙제는 다 했어?',
    targetWord: '숙제',
    videoUrl: sampleVideoUrl,
  ),
  PracticeSentence(
    id: 'p6',
    sceneId: 's4',
    text: '발표는 언제 시작해?',
    targetWord: '발표',
    videoUrl: sampleVideoUrl,
  ),
  PracticeSentence(
    id: 'p7',
    sceneId: 's5',
    text: '정말 깜짝 놀랐어!',
    targetWord: '깜짝',
    videoUrl: sampleVideoUrl,
  ),
];

const attemptHistory = [
  Attempt(
    id: 'a1',
    sentenceText: '안녕하세요, 처음 뵙겠습니다.',
    date: '2026-04-21',
    overallScore: 88,
    consonantScore: 86,
    vowelScore: 90,
    intonationScore: 84,
  ),
  Attempt(
    id: 'a2',
    sentenceText: '만나서 정말 반가워요.',
    date: '2026-04-21',
    overallScore: 82,
    consonantScore: 80,
    vowelScore: 85,
    intonationScore: 81,
  ),
  Attempt(
    id: 'a3',
    sentenceText: '숙제는 다 했어?',
    date: '2026-04-19',
    overallScore: 76,
    consonantScore: 78,
    vowelScore: 74,
    intonationScore: 76,
  ),
  Attempt(
    id: 'a4',
    sentenceText: '정말 깜짝 놀랐어!',
    date: '2026-04-18',
    overallScore: 91,
    consonantScore: 92,
    vowelScore: 89,
    intonationScore: 93,
  ),
];

const mockAnalysisResults = [
  AttemptAnalysisResult(
    attemptId: 'mock-a1',
    sentenceId: 'p1',
    targetText: '안녕하세요, 처음 뵙겠습니다.',
    predictedText: '안녕하세요, 처엄 뵙겠습니다.',
    overallScore: 84,
    consonantScore: 88,
    vowelScore: 78,
    intonationScore: 82,
    summaryTitle: '좋아요!',
    summaryMessage: '전체 흐름은 자연스럽지만 일부 모음과 문장 끝 억양을 더 다듬으면 좋습니다.',
    errorRanges: [
      PhonemeErrorRange(
        start: 7,
        end: 9,
        label: '모음 주의',
        message: '처음의 ㅡ/ㅓ 계열 모음이 약간 길게 들렸습니다.',
        severity: 'warning',
      ),
    ],
    pitchAnalysis: PitchAnalysisResult(
      referencePitch: [0.62, 0.58, 0.54, 0.50, 0.45, 0.40, 0.36],
      learnerPitch: [0.60, 0.57, 0.55, 0.54, 0.55, 0.58, 0.61],
      expectedPattern: 'falling',
      learnerPattern: 'rising',
      endingPatternMatch: false,
      dtwDistance: 0.31,
      speechRate: 1.12,
      rhythmScore: 80,
      prosodyScore: 82,
      diagnosisTitle: '문장 끝 억양 주의',
      diagnosisMessage: '문장 마지막 부분의 피치가 기준보다 올라가 질문처럼 들릴 수 있습니다.',
      practiceTips: [
        '마지막 음절을 짧게 끊으며 낮춰 말해보세요.',
        '문장 끝에서 목소리를 올리지 말고 자연스럽게 내려보세요.',
        '천천히 재생을 듣고 끝 억양만 먼저 따라 해보세요.',
      ],
    ),
    praiseFeedback: '문장 전체의 발화 속도와 자음 발음은 안정적입니다.',
    correctionFeedback: '“처음” 부분의 모음 길이와 문장 끝 억양을 더 자연스럽게 조정해보세요.',
    practiceFeedback: '느리게 듣기 후 마지막 단어만 2~3회 반복 녹음해보세요.',
  ),
  AttemptAnalysisResult(
    attemptId: 'mock-a2',
    sentenceId: 'p2',
    targetText: '만나서 정말 반가워요.',
    predictedText: '만나서 정말 반가워요.',
    overallScore: 91,
    consonantScore: 90,
    vowelScore: 93,
    intonationScore: 89,
    summaryTitle: '잘했어요!',
    summaryMessage: '대부분의 발음이 정확하고 문장 흐름도 자연스럽습니다.',
    errorRanges: [],
    pitchAnalysis: PitchAnalysisResult(
      referencePitch: [0.50, 0.53, 0.55, 0.52, 0.48, 0.45, 0.42],
      learnerPitch: [0.49, 0.52, 0.56, 0.53, 0.49, 0.46, 0.43],
      expectedPattern: 'falling',
      learnerPattern: 'falling',
      endingPatternMatch: true,
      dtwDistance: 0.12,
      speechRate: 1.02,
      rhythmScore: 91,
      prosodyScore: 89,
      diagnosisTitle: '억양 흐름이 자연스러움',
      diagnosisMessage: '기준 억양과 매우 유사하게 문장 끝을 안정적으로 마무리했습니다.',
      practiceTips: [
        '현재 억양 흐름을 유지하며 같은 속도로 반복해보세요.',
        '문장 중간 강세를 조금 더 또렷하게 주면 더 좋습니다.',
      ],
    ),
    praiseFeedback: '모음과 문장 끝 억양이 자연스럽습니다.',
    correctionFeedback: '큰 오류는 없지만 중간 강세를 조금 더 분명히 하면 좋습니다.',
    practiceFeedback: '같은 문장을 자연스러운 속도로 한 번 더 녹음해보세요.',
  ),
  AttemptAnalysisResult(
    attemptId: 'mock-a3',
    sentenceId: 'p3',
    targetText: '오늘 날씨가 참 좋네요.',
    predictedText: '오늘 날씨가 참 좋네요.',
    overallScore: 86,
    consonantScore: 89,
    vowelScore: 86,
    intonationScore: 86,
    summaryTitle: '좋아요!',
    summaryMessage: '전체 발음 흐름은 안정적입니다. 끝 억양만 조금 더 부드럽게 낮추면 더 자연스러워요.',
    errorRanges: [],
    pitchAnalysis: PitchAnalysisResult(
      referencePitch: [0.56, 0.55, 0.52, 0.48, 0.44, 0.40],
      learnerPitch: [0.55, 0.54, 0.52, 0.50, 0.47, 0.45],
      expectedPattern: 'falling',
      learnerPattern: 'falling',
      endingPatternMatch: true,
      dtwDistance: 0.18,
      speechRate: 1.05,
      rhythmScore: 86,
      prosodyScore: 86,
      diagnosisTitle: '끝 억양이 안정적임',
      diagnosisMessage: '문장 마지막 피치가 기준과 비슷하게 내려가 자연스럽게 들립니다.',
      practiceTips: [
        '문장 끝을 조금 더 짧게 마무리해보세요.',
        '좋네요 부분을 천천히 한 번 더 따라 읽어보세요.',
      ],
    ),
    praiseFeedback: '문장 전체의 발화 속도와 자음 발음은 안정적입니다.',
    correctionFeedback: '“좋네요” 부분의 끝 억양을 더 부드럽게 낮춰보세요.',
    practiceFeedback: '느리게 듣기 후 마지막 단어만 2~3회 반복 녹음해보세요.',
  ),
];

AttemptAnalysisResult analysisResultForSentence(String sentenceId) {
  return mockAnalysisResults.firstWhere(
        (result) => result.sentenceId == sentenceId,
    orElse: () {
      final sentence = sentences.firstWhere((s) => s.id == sentenceId);

      return AttemptAnalysisResult(
        attemptId: 'local-$sentenceId',
        sentenceId: sentenceId,
        targetText: sentence.text,
        predictedText: sentence.text,
        overallScore: 0,
        consonantScore: 0,
        vowelScore: 0,
        intonationScore: 0,
        summaryTitle: '분석 결과 없음',
        summaryMessage: '아직 이 문장에 대한 분석 결과 데이터가 없습니다.',
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
        praiseFeedback: '분석 결과가 없습니다.',
        correctionFeedback: '분석 결과가 없습니다.',
        practiceFeedback: '분석 결과가 없습니다.',
      );
    },
  );
}