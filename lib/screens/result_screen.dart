import 'package:flutter/material.dart';

import '../app_tab_controller.dart';
import '../data/mock_data.dart';
import '../services/learning_session_store.dart';
import '../services/local_attempt_store.dart';
import '../widgets/common_widgets.dart';
import 'learn_screen.dart';
import 'lesson_complete_screen.dart';

class ResultScreen extends StatefulWidget {
  final String lessonId;
  final String sceneId;
  final String sentenceId;
  final AttemptAnalysisResult? result;

  const ResultScreen({
    super.key,
    required this.lessonId,
    required this.sceneId,
    required this.sentenceId,
    this.result,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  PracticeSentence get sentence =>
      sentences.firstWhere((s) => s.id == widget.sentenceId);

  List<PracticeSentence> get sceneSentences =>
      sentences.where((s) => s.sceneId == widget.sceneId).toList();

  AttemptAnalysisResult get result =>
      widget.result ?? analysisResultForSentence(widget.sentenceId);

  bool get isLastSentence {
    final current = sceneSentences.indexWhere((s) => s.id == widget.sentenceId);
    return current + 1 >= sceneSentences.length;
  }

  @override
  void initState() {
    super.initState();
    LearningSessionStore.saveResult(result);
    _saveAttemptHistory();
  }

  Future<void> _saveAttemptHistory() async {
    final analysis = result;
    if (analysis.overallScore <= 0) return;

    final now = DateTime.now();
    final date = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    await LocalAttemptStore.add(
      Attempt(
        id: 'local-${analysis.sentenceId}-${now.microsecondsSinceEpoch}',
        sentenceText: analysis.targetText,
        date: date,
        overallScore: analysis.overallScore,
        consonantScore: analysis.consonantScore,
        vowelScore: analysis.vowelScore,
        intonationScore: analysis.intonationScore,
      ),
    );
  }

  Future<void> _confirmExitLearning() async {
    final shouldExit = await showSoftConfirmDialog(
      context: context,
      title: '학습을 종료할까요?',
      message: '현재 결과 확인을 중단하고 홈 화면으로 돌아갈 수 있어요.',
      cancelText: '계속하기',
      confirmText: '홈으로 가기',
    );

    if (shouldExit == true) {
      if (!mounted) return;
      moveToHomeTab();
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void next() {
    LearningSessionStore.saveResult(result);

    final current = sceneSentences.indexWhere((s) => s.id == widget.sentenceId);

    if (current + 1 < sceneSentences.length) {
      final nextSentence = sceneSentences[current + 1];

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LearnScreen(
            lessonId: widget.lessonId,
            sceneId: widget.sceneId,
            sentenceId: nextSentence.id,
          ),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LessonCompleteScreen(
          lessonId: widget.lessonId,
          sceneId: widget.sceneId,
        ),
      ),
    );
  }

  void retry() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LearnScreen(
          lessonId: widget.lessonId,
          sceneId: widget.sceneId,
          sentenceId: widget.sentenceId,
        ),
      ),
    );
  }

  Color scoreColor(int score) {
    if (score >= 90) return const Color(0xFF3F72E8);
    if (score >= 80) return const Color(0xFF4D89F7);
    if (score >= 70) return const Color(0xFF5F9F8B);
    return const Color(0xFF8A88C9);
  }

  String scoreLabel(int score) {
    if (score >= 90) return '아주 좋아요';
    if (score >= 80) return '좋아요';
    if (score >= 70) return '조금 더 연습해요';
    return '연습이 더 필요해요';
  }

  String shortSummary(AttemptAnalysisResult analysis) {
    if (analysis.summaryMessage.isNotEmpty) {
      return analysis.summaryMessage;
    }
    if (analysis.overallScore >= 90) {
      return '자연스럽고 안정적인 발음이에요.';
    }
    if (analysis.overallScore >= 80) {
      return '전체 흐름은 좋고, 몇 부분만 다듬으면 더 자연스러워져요.';
    }
    if (analysis.overallScore >= 70) {
      return '발음은 전달되지만, 모음과 억양을 조금 더 다듬어보면 좋아요.';
    }
    return '천천히 또박또박 연습하면 훨씬 좋아질 수 있어요.';
  }

  @override
  Widget build(BuildContext context) {
    final analysis = result;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, value) {
        if (didPop) return;
        _confirmExitLearning();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    MediaQuery.of(context).padding.top + 16,
                    18,
                    110,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        AppHeader(
                          label: '학습 결과',
                          title: '발음 분석 결과',
                          onBack: _confirmExitLearning,
                          emoji: '🌷',
                        ),
                        const SizedBox(height: 16),
                        _statusHeader(analysis),
                        const SizedBox(height: 14),
                        _scoreSummaryCard(analysis),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _scoreBox(
                                '자음',
                                analysis.consonantScore,
                                appSoftBlue,
                                const Color(0xFF4D89F7),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _scoreBox(
                                '모음',
                                analysis.vowelScore,
                                appSoftGreen,
                                const Color(0xFF36A27C),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _scoreBox(
                                '억양',
                                analysis.intonationScore,
                                appSoftPurple,
                                const Color(0xFF7A6EDB),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _sentenceCard(analysis),
                        const SizedBox(height: 12),
                        _recognizedCard(analysis),
                        const SizedBox(height: 12),
                        _intonationEntryCard(analysis),
                        const SizedBox(height: 18),
                        const Text(
                          '맞춤 피드백',
                          style: TextStyle(
                            color: appText,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _softFeedbackCard(
                          emoji: '😊',
                          title: '잘한 점',
                          body: analysis.praiseFeedback,
                          bg: const Color(0xFFE6F7EC),
                          titleColor: const Color(0xFF2F8E59),
                          bodyColor: const Color(0xFF1D5F3A),
                        ),
                        const SizedBox(height: 10),
                        _softFeedbackCard(
                          emoji: '💡',
                          title: '고쳐볼 점',
                          body: analysis.correctionFeedback,
                          bg: const Color(0xFFFFEEDC),
                          titleColor: const Color(0xFFE28A52),
                          bodyColor: const Color(0xFF8A5A30),
                        ),
                        const SizedBox(height: 10),
                        _softFeedbackCard(
                          emoji: '🪄',
                          title: '실천 팁',
                          body: analysis.practiceFeedback,
                          bg: const Color(0xFFEEE8FF),
                          titleColor: const Color(0xFF7E66D8),
                          bodyColor: const Color(0xFF5645A1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            _bottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _statusHeader(AttemptAnalysisResult analysis) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: appBorder,
          width: .9,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFEEE8),
            ),
            child: const Center(
              child: Text(
                '⭐',
                style: TextStyle(fontSize: 30),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  analysis.summaryTitle.isNotEmpty
                      ? analysis.summaryTitle
                      : scoreLabel(analysis.overallScore),
                  style: const TextStyle(
                    color: appText,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  shortSummary(analysis),
                  style: const TextStyle(
                    color: appSubText,
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreSummaryCard(AttemptAnalysisResult analysis) {
    final color = scoreColor(analysis.overallScore);

    return AppCard(
      radius: 30,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      backgroundColor: Colors.white,
      child: Column(
        children: [
          const Text(
            '종합 점수',
            style: TextStyle(
              color: appSubText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${analysis.overallScore}',
            style: TextStyle(
              color: color,
              fontSize: 68,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              scoreLabel(analysis.overallScore),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreBox(
    String label,
    int score,
    Color bg,
    Color color,
  ) {
    return AppCard(
      radius: 22,
      backgroundColor: bg,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: appSubText,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$score',
            style: TextStyle(
              color: color,
              fontSize: 25,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sentenceCard(AttemptAnalysisResult analysis) {
    return AppCard(
      radius: 28,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '연습한 문장',
            style: TextStyle(
              color: appSubText,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: appText,
                fontSize: 21,
                height: 1.45,
                fontWeight: FontWeight.w900,
              ),
              children: _highlightByRanges(
                analysis.targetText,
                analysis.errorRanges,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recognizedCard(AttemptAnalysisResult analysis) {
    return AppCard(
      radius: 26,
      padding: const EdgeInsets.all(18),
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '인식된 문장',
            style: TextStyle(
              color: appSubText,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            analysis.predictedText.isEmpty
                ? analysis.targetText
                : analysis.predictedText,
            style: const TextStyle(
              color: appText,
              fontSize: 18,
              height: 1.38,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _intonationEntryCard(AttemptAnalysisResult analysis) {
    return GestureDetector(
      onTap: () => _showIntonationHintSheet(context, analysis),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F1FF),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: const Color(0xFFE7DFFF),
            width: 0.9,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.trending_up_rounded,
                color: Color(0xFF7B6AD9),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '억양 힌트 보기',
                    style: TextStyle(
                      color: appText,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    analysis.pitchAnalysis.diagnosisTitle.isEmpty
                        ? '내 억양 흐름을 기준 발음과 비교해볼 수 있어요'
                        : analysis.pitchAnalysis.diagnosisTitle,
                    style: const TextStyle(
                      color: appSubText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_up_rounded,
              color: Color(0xFF9C96B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _softFeedbackCard({
    required String emoji,
    required String title,
    required String body,
    required Color bg,
    required Color titleColor,
    required Color bodyColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: titleColor.withOpacity(.18), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.72),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: TextStyle(
                    color: bodyColor,
                    fontSize: 16,
                    height: 1.55,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _highlightByRanges(
    String text,
    List<PhonemeErrorRange> ranges,
  ) {
    if (ranges.isEmpty) {
      return [TextSpan(text: text)];
    }

    final sorted = [...ranges]..sort((a, b) => a.start.compareTo(b.start));
    final spans = <TextSpan>[];
    var cursor = 0;

    for (final range in sorted) {
      final start = range.start.clamp(0, text.length);
      final end = range.end.clamp(start, text.length);

      if (cursor < start) {
        spans.add(TextSpan(text: text.substring(cursor, start)));
      }

      spans.add(
        TextSpan(
          text: text.substring(start, end),
          style: const TextStyle(
            color: appText,
            backgroundColor: Color(0xFFFFEEE7),
            decoration: TextDecoration.underline,
            decorationColor: appCoral,
            decorationThickness: 3,
          ),
        ),
      );

      cursor = end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return spans;
  }

  Widget _bottomButtons() {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 10,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: appBorder,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: retry,
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('다시 해보기'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: appCoral,
                      side: const BorderSide(color: Color(0xFFFFD8CC)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: next,
                      borderRadius: BorderRadius.circular(18),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: appWarmGradient,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                isLastSentence ? '최종 결과 보기' : '다음 문장',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showIntonationHintSheet(
    BuildContext context,
    AttemptAnalysisResult analysis,
  ) async {
    final pitch = analysis.pitchAnalysis;

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.76,
          minChildSize: 0.42,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, controller) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8DCD7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: controller,
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F0FF),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.trending_up_rounded,
                                  color: Color(0xFF7B6AD9),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '억양 힌트',
                                      style: TextStyle(
                                        color: appText,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      pitch.diagnosisTitle.isEmpty
                                          ? '문장 억양 흐름을 확인해볼 수 있어요'
                                          : pitch.diagnosisTitle,
                                      style: const TextStyle(
                                        color: appSubText,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _diagnosisCard(pitch),
                          const SizedBox(height: 12),
                          _curveCompareCard(pitch),
                          const SizedBox(height: 12),
                          _tipCard(pitch.practiceTips),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _diagnosisCard(PitchAnalysisResult pitch) {
    final matched = pitch.endingPatternMatch;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: matched ? const Color(0xFFEFF9F1) : const Color(0xFFFFF8EE),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        pitch.diagnosisMessage.isEmpty
            ? '억양 흐름을 기준 발음과 비교해 연습해보세요.'
            : pitch.diagnosisMessage,
        style: TextStyle(
          color: matched ? const Color(0xFF2A7E52) : const Color(0xFF9A6A3B),
          height: 1.45,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _curveCompareCard(PitchAnalysisResult pitch) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0E8E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '억양 비교',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: appText,
            ),
          ),
          const SizedBox(height: 12),
          _curveBox(
            title: '기준 억양',
            color: const Color(0xFF5BAE78),
            points: pitch.referencePitch,
          ),
          const SizedBox(height: 10),
          _curveBox(
            title: '내 억양',
            color: pitch.endingPatternMatch
                ? const Color(0xFF5BAE78)
                : const Color(0xFFEF9A62),
            points: pitch.learnerPitch,
          ),
        ],
      ),
    );
  }

  Widget _curveBox({
    required String title,
    required Color color,
    required List<double> points,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: appText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 56,
            width: double.infinity,
            child: CustomPaint(
              painter: _PitchCurvePainter(
                color: color,
                points: points,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipCard(List<String> tips) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3FF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '연습 방법',
            style: TextStyle(
              color: Color(0xFF7B6AD9),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (tips.isEmpty)
            const Text(
              '제공된 연습 팁이 없습니다.',
              style: TextStyle(
                color: appSubText,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            for (var i = 0; i < tips.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE7DEFF),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Color(0xFF6A55C4),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tips[i],
                      style: const TextStyle(
                        color: Color(0xFF5D4FA9),
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (i != tips.length - 1) const SizedBox(height: 9),
            ],
        ],
      ),
    );
  }
}

class _PitchCurvePainter extends CustomPainter {
  final Color color;
  final List<double> points;

  _PitchCurvePainter({
    required this.color,
    required this.points,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..color = const Color(0xFFE3E8EF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final line = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(8, size.height * .5),
      Offset(size.width - 8, size.height * .5),
      base,
    );

    if (points.length < 2) return;

    final minValue = points.reduce((a, b) => a < b ? a : b);
    final maxValue = points.reduce((a, b) => a > b ? a : b);
    final range = (maxValue - minValue).abs() < 0.0001
        ? 1.0
        : maxValue - minValue;

    final path = Path();

    for (var i = 0; i < points.length; i++) {
      final x = 8 + ((size.width - 16) * i / (points.length - 1));
      final normalized = (points[i] - minValue) / range;
      final y = size.height - 8 - normalized * (size.height - 16);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _PitchCurvePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.points != points;
  }
}
