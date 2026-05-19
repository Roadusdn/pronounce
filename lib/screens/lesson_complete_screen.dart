import 'package:flutter/material.dart';

import '../app_tab_controller.dart';
import '../models/pronunciation_models.dart';
import '../repositories/pronunciation_repository.dart';
import '../services/learning_session_store.dart';
import '../widgets/common_widgets.dart';

class LessonCompleteScreen extends StatefulWidget {
  final String lessonId;
  final String sceneId;

  const LessonCompleteScreen({
    super.key,
    required this.lessonId,
    required this.sceneId,
  });

  @override
  State<LessonCompleteScreen> createState() => _LessonCompleteScreenState();
}

class _LessonCompleteScreenState extends State<LessonCompleteScreen> {
  late Future<_CompletionData> _completionFuture;

  @override
  void initState() {
    super.initState();
    _completionFuture = _loadCompletion();
  }

  Future<_CompletionData> _loadCompletion() async {
    final bundle = await PronunciationRepository.instance.getLessonSceneBundle(
      widget.lessonId,
    );
    final sentences = [
      for (final scene in bundle.scenes)
        ...(bundle.sentencesBySceneId[scene.id] ?? const <PracticeSentence>[]),
    ];

    return _CompletionData(
      lesson: bundle.lesson,
      sentences: sentences,
      results: LearningSessionStore.resultsForSentences(sentences),
    );
  }

  int _average(List<int> values) {
    final valid = values.where((value) => value > 0).toList();
    if (valid.isEmpty) return 0;
    final sum = valid.fold<int>(0, (acc, value) => acc + value);
    return (sum / valid.length).round();
  }

  String _gradeLabel(int score) {
    if (score >= 90) return '훌륭해요!';
    if (score >= 80) return '잘했어요!';
    if (score >= 70) return '조금만 더!';
    return '다시 연습해볼까요?';
  }

  Color _scoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 80) return appBlue;
    if (score >= 70) return Colors.orange;
    if (score <= 0) return appCoral;
    return const Color(0xFFE85D4D);
  }

  void _goHome() {
    moveToHomeTab();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _goLearning() {
    moveToLearningTab();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, value) {
        if (didPop) return;
        _goHome();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: FutureBuilder<_CompletionData>(
            future: _completionFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: appCoral),
                );
              }

              if (snapshot.hasError || snapshot.data == null) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: AppCard(
                    child: Text(
                      snapshot.hasError
                          ? '완료 정보를 불러오지 못했습니다: ${snapshot.error}'
                          : '완료 정보가 없습니다.',
                      style: const TextStyle(
                        color: appText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              }

              return _content(snapshot.data!);
            },
          ),
        ),
      ),
    );
  }

  Widget _content(_CompletionData data) {
    final overall = _average(data.results.map((e) => e.overallScore).toList());
    final consonant = _average(data.results.map((e) => e.consonantScore).toList());
    final vowel = _average(data.results.map((e) => e.vowelScore).toList());
    final intonation = _average(data.results.map((e) => e.intonationScore).toList());
    final color = _scoreColor(overall);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        const AppHeader(
          label: '최종 결과',
          title: '학습이 완료되었어요',
          showBack: false,
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(colors: [color.withValues(alpha: .85), color]),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: Colors.white,
                size: 54,
              ),
              const SizedBox(height: 10),
              Text(
                _gradeLabel(overall),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                data.lesson.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                overall == 0 ? '-' : '$overall',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 72,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '평균 점수',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _miniScore('자음', consonant)),
            const SizedBox(width: 8),
            Expanded(child: _miniScore('모음', vowel)),
            const SizedBox(width: 8),
            Expanded(child: _miniScore('억양', intonation)),
          ],
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '완료한 문장',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < data.sentences.length; i++)
                _sentenceRow(
                  sentence: data.sentences[i],
                  result: data.results[i],
                  index: i + 1,
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 58,
                child: OutlinedButton.icon(
                  onPressed: _goLearning,
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('다른 학습'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: appCoral,
                    side: const BorderSide(color: appBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryButton(
                text: '홈으로',
                icon: Icons.home,
                onPressed: _goHome,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _miniScore(String label, int score) {
    final color = _scoreColor(score);

    return AppCard(
      backgroundColor: label == '자음'
          ? appSoftBlue
          : label == '모음'
              ? appSoftGreen
              : appSoftPurple,
      border: Border.all(color: Colors.transparent),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            score == 0 ? '-' : '$score',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sentenceRow({
    required PracticeSentence sentence,
    required AttemptAnalysisResult result,
    required int index,
  }) {
    final color = _scoreColor(result.overallScore);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: index.isOdd ? const Color(0xFFF7FAFF) : const Color(0xFFF2FBF5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .18), width: .8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: .13),
            child: Text(
              '$index',
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              sentence.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 8),
          Pill(
            text: result.overallScore <= 0 ? '-' : '${result.overallScore}점',
            background: color.withValues(alpha: .12),
            foreground: color,
          ),
        ],
      ),
    );
  }
}

class _CompletionData {
  final Lesson lesson;
  final List<PracticeSentence> sentences;
  final List<AttemptAnalysisResult> results;

  const _CompletionData({
    required this.lesson,
    required this.sentences,
    required this.results,
  });
}
