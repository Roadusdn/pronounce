import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../services/local_attempt_store.dart';
import '../widgets/common_widgets.dart';

class RecordHistoryScreen extends StatelessWidget {
  const RecordHistoryScreen({super.key});

  int _averageScore(List<Attempt> attempts) {
    if (attempts.isEmpty) return 0;
    final sum = attempts.fold<int>(0, (acc, a) => acc + a.overallScore);
    return (sum / attempts.length).round();
  }

  String _mostPracticedSound(List<Attempt> attempts) {
    if (attempts.isEmpty) return "'ㅅ' 발음";
    return "'ㅅ' 발음";
  }

  String _evaluationFor(Attempt attempt) {
    if (attempt.overallScore >= 90) {
      return '전반적으로 안정적이고 자연스러운 발음이에요. 지금처럼 속도와 억양을 유지하면 좋아요.';
    }
    if (attempt.overallScore >= 80) {
      return '전체 흐름은 좋고 전달력도 좋아요. 일부 발음만 더 또렷하게 다듬으면 훨씬 자연스러워져요.';
    }
    if (attempt.overallScore >= 70) {
      return '기본 전달은 잘 되지만 모음이나 억양을 조금 더 신경 쓰면 점수가 더 올라갈 수 있어요.';
    }
    return '천천히 또박또박 말하는 연습을 반복하면 발음이 더 안정적으로 좋아질 수 있어요.';
  }

  String _focusTitleFor(Attempt attempt) {
    final scoreMap = <String, int>{
      '자음': attempt.consonantScore,
      '모음': attempt.vowelScore,
      '억양': attempt.intonationScore,
    };

    final sorted = scoreMap.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return sorted.first.key;
  }

  String _focusDescriptionFor(Attempt attempt) {
    switch (_focusTitleFor(attempt)) {
      case '자음':
        return '자음 끝소리를 조금 더 또렷하게 발음해보세요. 특히 단어 시작과 끝을 분명히 구분해 말하면 좋아요.';
      case '모음':
        return '모음 길이와 입 모양을 조금 더 신경 써보세요. 비슷한 소리를 비교하며 천천히 따라 읽는 연습이 효과적이에요.';
      case '억양':
      default:
        return '문장 끝 억양과 전체 리듬을 조금 더 자연스럽게 조절해보세요. 예문을 듣고 억양만 먼저 따라 하는 연습이 좋아요.';
    }
  }

  Future<void> _showAttemptDetail(BuildContext context, Attempt attempt) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: .74,
          minChildSize: .45,
          maxChildSize: .92,
          expand: false,
          builder: (context, controller) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: appBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                      children: [
                        const Text(
                          '연습 기록 상세',
                          style: TextStyle(
                            color: appText,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Pill(
                              text: '${attempt.overallScore}점',
                              background: const Color(0xFFFFF1E8),
                              foreground: appCoral,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              attempt.date,
                              style: const TextStyle(
                                color: appSubText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          attempt.sentenceText,
                          style: const TextStyle(
                            color: appText,
                            fontSize: 21,
                            height: 1.35,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          '세부 점수',
                          style: TextStyle(
                            color: appText,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _detailScoreBox(
                                label: '자음',
                                score: attempt.consonantScore,
                                background: const Color(0xFFF4F7FF),
                                scoreColor: const Color(0xFF4D89F7),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _detailScoreBox(
                                label: '모음',
                                score: attempt.vowelScore,
                                background: const Color(0xFFEFFAF5),
                                scoreColor: const Color(0xFF34A27B),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _detailScoreBox(
                                label: '억양',
                                score: attempt.intonationScore,
                                background: const Color(0xFFF6F1FF),
                                scoreColor: const Color(0xFF7C67D9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _detailSectionCard(
                          icon: Icons.forum_outlined,
                          iconBg: const Color(0xFFFFF3EC),
                          iconColor: appCoral,
                          title: '받은 평가',
                          body: _evaluationFor(attempt),
                        ),
                        const SizedBox(height: 12),
                        _detailSectionCard(
                          icon: Icons.star_outline_rounded,
                          iconBg: const Color(0xFFEFF5FF),
                          iconColor: const Color(0xFF4D89F7),
                          title: '중점 연습',
                          body: '${_focusTitleFor(attempt)} 중심으로 다시 연습해보세요. ${_focusDescriptionFor(attempt)}',
                        ),
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Attempt>>(
      valueListenable: LocalAttemptStore.attempts,
      builder: (context, attempts, _) {
        final avg = _averageScore(attempts);

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            children: [
              const Text(
                '학습 기록 📈',
                style: TextStyle(
                  color: appText,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '얼마나 잘했는지 볼까요?',
                style: TextStyle(
                  color: appSubText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      icon: Icons.calendar_month_rounded,
                      iconBg: const Color(0xFFFFEDD5),
                      iconColor: appCoral,
                      label: '이번 주 학습',
                      value: '${attempts.length}일',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _summaryCard(
                      icon: Icons.trending_up_rounded,
                      iconBg: const Color(0xFFDBEAFE),
                      iconColor: const Color(0xFF2563EB),
                      label: '평균 점수',
                      value: avg == 0 ? '-' : '$avg점',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              AppCard(
                backgroundColor: const Color(0xFFFFF1E4),
                border: Border.all(color: const Color(0xFFFFD6A6), width: .9),
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '가장 많이 연습한 발음',
                            style: TextStyle(
                              color: appText,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _mostPracticedSound(attempts),
                            style: const TextStyle(
                              color: appCoral,
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '🏆',
                          style: TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                '최근 연습',
                style: TextStyle(
                  color: appText,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              if (attempts.isEmpty)
                AppCard(
                  child: const Text(
                    '아직 연습 기록이 없습니다.',
                    style: TextStyle(
                      color: appSubText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                for (final attempt in attempts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: AppCard(
                      onTap: () => _showAttemptDetail(context, attempt),
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Pill(
                            text: '${attempt.overallScore}점',
                            background: attempt.overallScore >= 90
                                ? appMint
                                : appCream,
                            foreground: attempt.overallScore >= 90
                                ? const Color(0xFF16A34A)
                                : appCoral,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  attempt.sentenceText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: appText,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  attempt.date,
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
                          GestureDetector(
                            onTap: () => _showAttemptDetail(context, attempt),
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: const BoxDecoration(
                                color: appCoralLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chevron_right_rounded,
                                color: appCoral,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return AppCard(
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 26,
      ),
      child: Column(
        children: [
          CuteIconBubble(
            icon: icon,
            background: iconBg,
            foreground: iconColor,
            size: 58,
            iconSize: 28,
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              color: appSubText,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: appText,
              fontSize: 29,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailScoreBox({
    required String label,
    required int score,
    required Color background,
    required Color scoreColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: appSubText,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$score',
            style: TextStyle(
              color: scoreColor,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailSectionCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6D8D0), width: .8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CuteIconBubble(
            icon: icon,
            background: iconBg,
            foreground: iconColor,
            size: 44,
            iconSize: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: appText,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFF596071),
                    height: 1.5,
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
}
