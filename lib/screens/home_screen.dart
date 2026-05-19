import 'package:flutter/material.dart';

import '../app_tab_controller.dart';
import '../models/pronunciation_models.dart';
import '../repositories/pronunciation_repository.dart';
import '../services/local_attempt_store.dart';
import '../services/local_user_store.dart';
import '../widgets/common_widgets.dart';
import 'scene_list_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onStartLearning;
  final VoidCallback onOpenHistory;

  const HomeScreen({
    super.key,
    required this.onStartLearning,
    required this.onOpenHistory,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Lesson>> _lessonsFuture;

  @override
  void initState() {
    super.initState();
    _lessonsFuture = PronunciationRepository.instance.getLessons();
  }

  int _todayPracticeCount(List<Attempt> attempts) {
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return attempts.where((attempt) => attempt.date == today).length;
  }

  String _vocativeSuffix(String nickname) {
    if (nickname.isEmpty) return '';
    final lastChar = nickname.runes.last;
    if (lastChar < 0xAC00 || lastChar > 0xD7A3) return '';
    return (lastChar - 0xAC00) % 28 == 0 ? '야' : '아';
  }

  String _estimatedLessonDuration(Lesson lesson) {
    final minutes = lesson.sceneCount <= 0 ? 3 : lesson.sceneCount * 3;
    return '약 $minutes분';
  }

  void _reloadLessons() {
    setState(() {
      _lessonsFuture = PronunciationRepository.instance.getLessons();
    });
  }

  void _openLesson(BuildContext context, Lesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SceneListScreen(lessonId: lesson.id),
      ),
    );
  }

  Lesson _firstAvailableLesson(List<Lesson> lessons, List<Attempt> attempts) {
    final completedSceneIds = attempts
        .map((attempt) => attempt.sceneId)
        .where((sceneId) => sceneId.isNotEmpty)
        .toSet();

    for (final lesson in lessons) {
      final sceneIds = lesson.sceneIds;
      if (sceneIds.isEmpty) return lesson;
      final completed = sceneIds.every(completedSceneIds.contains);
      if (!completed) return lesson;
    }

    return lessons.first;
  }

  @override
  Widget build(BuildContext context) {
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
            final recentAttempts = LocalAttemptStore.latestAttemptsByScene(limit: 3);
            final todayCount = _todayPracticeCount(attempts);

            return SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 28, 18, 24),
                children: [
                  _header(nickname, suffix),
                  const SizedBox(height: 4),
                  const Text(
                    '오늘도 또박또박 말해볼까요?',
                    style: TextStyle(
                      color: appSubText,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _todayPracticeCard(todayCount),
                  const SizedBox(height: 22),
                  FutureBuilder<List<Lesson>>(
                    future: _lessonsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const AppCard(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: CircularProgressIndicator(color: appCoral),
                          ),
                        );
                      }

                      if (snapshot.hasError) return _lessonLoadError(snapshot.error);
                      final lessons = snapshot.data ?? const <Lesson>[];
                      if (lessons.isEmpty) return _emptyLessonsCard();

                      final lesson = _firstAvailableLesson(lessons, attempts);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionTitle(title: '오늘의 추천 학습', emoji: '▶'),
                          const SizedBox(height: 10),
                          _recommendedLessonCard(lesson),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  const SectionTitle(title: '최근 학습 기록', emoji: '✓'),
                  const SizedBox(height: 10),
                  _recentAttempts(recentAttempts),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _header(String nickname, String suffix) {
    return Row(
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
                  ),
                ),
                TextSpan(
                  text: '$nickname$suffix!',
                  style: const TextStyle(
                    color: appCoral,
                    fontSize: 23,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
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
              border: Border.all(color: const Color(0xFFFFD79C), width: 1.8),
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
    );
  }

  Widget _todayPracticeCard(int todayCount) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 18,
      backgroundColor: appCoralLight,
      border: Border.all(color: const Color(0xFFFFC8B8), width: .9),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.local_fire_department_rounded, color: appCoral, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '오늘 $todayCount번 연습했어요',
              style: const TextStyle(
                color: appText,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lessonLoadError(Object? error) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '수업 정보를 불러오지 못했습니다',
            style: TextStyle(color: appText, fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            '$error',
            style: const TextStyle(
              color: appSubText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          SoftOutlineButton(
            text: '다시 시도',
            icon: Icons.refresh_rounded,
            onPressed: _reloadLessons,
          ),
        ],
      ),
    );
  }

  Widget _emptyLessonsCard() {
    return const AppCard(
      padding: EdgeInsets.all(18),
      child: Text(
        '사용 가능한 수업이 없습니다.',
        style: TextStyle(color: appSubText, fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _recommendedLessonCard(Lesson lesson) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      radius: 26,
      backgroundColor: Colors.white,
      border: Border.all(color: appBorder, width: .9),
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
                    colors: [Color(0xFFFF8A66), Color(0xFFFF735C)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
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
                          _estimatedLessonDuration(lesson),
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
                      lesson.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: appText,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            lesson.description,
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
            onPressed: () => _openLesson(context, lesson),
          ),
        ],
      ),
    );
  }

  Widget _recentAttempts(List<Attempt> recentAttempts) {
    if (recentAttempts.isEmpty) {
      return const AppCard(
        padding: EdgeInsets.all(16),
        child: Text(
          '아직 학습 기록이 없습니다.',
          style: TextStyle(color: appSubText, fontSize: 14, fontWeight: FontWeight.w700),
        ),
      );
    }

    return Column(
      children: [
        for (final attempt in recentAttempts)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              onTap: widget.onOpenHistory,
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
                    child: const Icon(Icons.history_rounded, color: appCoral, size: 26),
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
    );
  }
}
