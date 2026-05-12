import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_tab_controller.dart';
import '../data/mock_data.dart';
import '../services/local_attempt_store.dart';
import '../services/local_user_store.dart';
import '../widgets/common_widgets.dart';
import 'scene_list_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onStartLearning;
  final VoidCallback onOpenHistory;

  const HomeScreen({
    super.key,
    required this.onStartLearning,
    required this.onOpenHistory,
  });

  int _todayPracticeCount(List<Attempt> attempts) {
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return attempts.where((a) => a.date == today).length;
  }

  String _vocativeSuffix(String nickname) {
    if (nickname.isEmpty) return '야';

    final lastChar = nickname.runes.last;

    if (lastChar < 0xAC00 || lastChar > 0xD7A3) {
      return '야';
    }

    final finalConsonantIndex = (lastChar - 0xAC00) % 28;
    return finalConsonantIndex == 0 ? '야' : '아';
  }

  int _parseDurationToSeconds(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return 0;

    final minutes = int.tryParse(parts[0]) ?? 0;
    final seconds = int.tryParse(parts[1]) ?? 0;
    return (minutes * 60) + seconds;
  }

  String _estimatedLessonDuration(String lessonId) {
    final lessonScenes = scenes.where((scene) => scene.lessonId == lessonId);
    final totalSeconds = lessonScenes.fold<int>(
      0,
      (sum, scene) => sum + _parseDurationToSeconds(scene.duration),
    );

    final estimatedPracticeSeconds = totalSeconds * 3;
    final minutes = math.max(1, (estimatedPracticeSeconds / 60).ceil());
    return '약 ${minutes}분 소요';
  }

  void _openRecommendedLesson(BuildContext context, Lesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SceneListScreen(
          lessonId: lesson.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recommendedLesson = lessons.first;
    final focusLesson = lessons.first;

    return ValueListenableBuilder<LocalUser?>(
      valueListenable: LocalUserStore.currentUser,
      builder: (context, user, _) {
        final nickname = user?.nickname.trim().isNotEmpty == true
            ? user!.nickname.trim()
            : '친구';

        final suffix = _vocativeSuffix(nickname);

        return ValueListenableBuilder<List<Attempt>>(
          valueListenable: LocalAttemptStore.attempts,
          builder: (context, attempts, _) {
            final recentAttempts = attempts.take(3).toList();
            final todayCount = _todayPracticeCount(attempts);

            return SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 28, 18, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: '안녕, ',
                                style: TextStyle(
                                  color: appText,
                                  fontSize: 23,
                                  height: 1.1,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              TextSpan(
                                text: '$nickname$suffix!',
                                style: const TextStyle(
                                  color: appCoral,
                                  fontSize: 23,
                                  height: 1.1,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const TextSpan(
                                text: ' 👋',
                                style: TextStyle(fontSize: 21),
                              ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: moveToSettingsTab,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFFE8C8),
                            border: Border.all(
                              color: const Color(0xFFFFD79C),
                              width: 1.8,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              nickname.characters.first,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: appCoral,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '오늘도 신나게 말해볼까?',
                    style: TextStyle(
                      color: appSubText,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    radius: 18,
                    backgroundColor: appCoralLight,
                    border: Border.all(
                      color: const Color(0xFFFFC8B8),
                      width: .9,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            color: appCoral,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '오늘 $todayCount회 연습했어요',
                            style: const TextStyle(
                              color: appText,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const SectionTitle(
                    title: '오늘의 추천 학습',
                    emoji: '✨',
                  ),
                  const SizedBox(height: 10),
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    radius: 26,
                    backgroundColor: Colors.white,
                    border: Border.all(
                      color: appBorder,
                      width: .9,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF8A66),
                                    Color(0xFFFF735C),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 34,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Pill(
                                        text: '추천',
                                        background: Color(0xFFFFF1D8),
                                        foreground: Color(0xFFFF735C),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _estimatedLessonDuration(recommendedLesson.id),
                                        style: const TextStyle(
                                          color: appSubText,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    recommendedLesson.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: appText,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          recommendedLesson.description,
                          style: const TextStyle(
                            color: Color(0xFF665F68),
                            fontSize: 14,
                            height: 1.4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 18),
                        PrimaryButton(
                          text: '지금 시작하기',
                          onPressed: () => _openRecommendedLesson(
                            context,
                            recommendedLesson,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const SectionTitle(
                    title: '집중 발음 교정',
                    emoji: '◎',
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => _openRecommendedLesson(context, focusLesson),
                      child: Ink(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF2FF),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFC9DAFF),
                            width: .9,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "'ㅓ / ㅡ / ㅜ' 모음",
                                    style: TextStyle(
                                      color: Color(0xFF174EA6),
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    '다시 한번 연습해볼까요?',
                                    style: TextStyle(
                                      color: Color(0xFF4B72CC),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 42,
                              height: 42,
                              decoration: const BoxDecoration(
                                color: Color(0xFFDCEBFF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Color(0xFF2563EB),
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const SectionTitle(
                    title: '최근 학습 기록',
                    emoji: '⭐',
                  ),
                  const SizedBox(height: 10),
                  if (recentAttempts.isEmpty)
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: const Text(
                        '아직 학습 기록이 없습니다.',
                        style: TextStyle(
                          color: appSubText,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    for (final attempt in recentAttempts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          onTap: onOpenHistory,
                          padding: const EdgeInsets.all(16),
                          radius: 24,
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: appCream,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(
                                  child: Text(
                                    '🚌',
                                    style: TextStyle(fontSize: 24),
                                  ),
                                ),
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
                                        fontSize: 15,
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
                              Pill(
                                text: '${attempt.overallScore}점',
                                background: appMint,
                                foreground: const Color(0xFF16A34A),
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
      },
    );
  }
}
