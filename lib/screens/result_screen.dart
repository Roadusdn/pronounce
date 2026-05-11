import 'package:flutter/material.dart';

import '../models/pronunciation_models.dart';
import '../widgets/common_widgets.dart';
import 'learn_screen.dart';

class ResultScreen extends StatelessWidget {
  final Lesson lesson;
  final List<Utterance> utterances;
  final int currentIndex;
  final AttemptResult result;
  final List<PhonemeDetail> phonemes;
  final PitchDetail pitch;
  final AttemptFeedback feedback;

  const ResultScreen({
    super.key,
    required this.lesson,
    required this.utterances,
    required this.currentIndex,
    required this.result,
    required this.phonemes,
    required this.pitch,
    required this.feedback,
  });

  Utterance get utterance => utterances[currentIndex];

  Color scoreColor(int s) {
    if (s >= 90) return Colors.green;
    if (s >= 80) return appBlue;
    if (s >= 70) return Colors.orange;
    return Colors.red;
  }

  String headerText() {
    if (result.overallScore >= 90) return '완료';
    if (result.overallScore >= 80) return '좋아요';
    if (result.overallScore >= 70) return '다듬어볼까요';
    return '다시 연습해요';
  }

  void next(BuildContext context) {
    if (currentIndex + 1 < utterances.length) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LearnScreen(
            lesson: lesson,
            utterances: utterances,
            initialIndex: currentIndex + 1,
          ),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + 16,
              16,
              110,
            ),
            children: [
              const AppHeader(
                label: '학습 결과',
                title: '백엔드 분석 결과',
              ),
              const SizedBox(height: 18),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: scoreColor(result.overallScore),
                      size: 74,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      headerText(),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  children: [
                    const Text(
                      '종합 점수',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${result.overallScore}',
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                        color: scoreColor(result.overallScore),
                      ),
                    ),
                    const Text(
                      '100점 만점',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _scoreCard('발음', result.pronunciationScore)),
                  const SizedBox(width: 10),
                  Expanded(child: _scoreCard('피치', result.pitchScore)),
                  const SizedBox(width: 10),
                  Expanded(child: _scoreCard('억양', pitch.score)),
                ],
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.volume_up, color: appBlue),
                        SizedBox(width: 8),
                        Text(
                          '연습 문장',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      utterance.practiceText,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 20,
                        height: 1.45,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (result.transcript.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        result.transcript,
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '음소 상세',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    if (phonemes.isEmpty)
                      const Text(
                        '음소 상세가 없습니다.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      )
                    else
                      for (final detail in phonemes.take(5))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Pill(
                                text: detail.symbol,
                                background: const Color(0xFFF1F5F9),
                                foreground: const Color(0xFF475569),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  detail.note.isEmpty
                                      ? '${detail.expected} → ${detail.actual}'
                                      : detail.note,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                '${detail.score}',
                                style: TextStyle(
                                  color: scoreColor(detail.score),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '피치 상세',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pitch.summary.isEmpty ? '피치 요약이 없습니다.' : pitch.summary,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: (pitch.score / 100).clamp(0, 1).toDouble(),
                      color: scoreColor(pitch.score),
                      backgroundColor: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _feedback('칭찬', feedback.praise, Icons.auto_awesome),
                    const Divider(color: Colors.white24, height: 26),
                    _feedback(
                      '개선 포인트',
                      feedback.improvement,
                      Icons.trending_up,
                    ),
                    const Divider(color: Colors.white24, height: 26),
                    _feedback('실천 팁', feedback.tip, Icons.lightbulb_outline),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 12,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LearnScreen(
                              lesson: lesson,
                              utterances: utterances,
                              initialIndex: currentIndex,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('다시 해보기'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => next(context),
                        icon: const Icon(Icons.arrow_forward),
                        label: Text(
                          currentIndex + 1 < utterances.length ? '다음 문장' : '완료',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreCard(String label, int score) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: scoreColor(score),
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (score / 100).clamp(0, 1).toDouble(),
            color: scoreColor(score),
            backgroundColor: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(99),
          ),
        ],
      ),
    );
  }

  Widget _feedback(String title, String body, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: Colors.white24,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFDBEAFE),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body.isEmpty ? '-' : body,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
