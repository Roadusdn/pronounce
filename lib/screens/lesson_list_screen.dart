import 'package:flutter/material.dart';

import '../models/pronunciation_models.dart';
import '../repositories/pronunciation_repository.dart';
import '../widgets/common_widgets.dart';
import 'scene_list_screen.dart';

class LessonListScreen extends StatefulWidget {
  const LessonListScreen({super.key});

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> {
  late Future<List<Lesson>> _lessonsFuture;
  String selectedDifficulty = 'all';

  @override
  void initState() {
    super.initState();
    _lessonsFuture = PronunciationRepository.instance.getLessons();
  }

  void _reload() {
    setState(() {
      _lessonsFuture = PronunciationRepository.instance.getLessons();
    });
  }

  List<Lesson> _filteredLessons(List<Lesson> lessons) {
    if (selectedDifficulty == 'all') return lessons;
    return lessons
        .where((lesson) => lesson.difficulty == selectedDifficulty)
        .toList();
  }

  String difficultyLabel(String value) {
    switch (value) {
      case 'easy':
        return '쉬움';
      case 'medium':
        return '보통';
      case 'hard':
        return '어려움';
      default:
        return '전체';
    }
  }

  Color difficultyColor(String value) {
    switch (value) {
      case 'easy':
        return const Color(0xFF22C55E);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'hard':
        return const Color(0xFFEF4444);
      default:
        return appCoral;
    }
  }

  String lessonEmoji(int index) {
    const emojis = ['🎧', '🎬', '📚', '🗣️', '✨', '🎯'];
    return emojis[index % emojis.length];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<Lesson>>(
        future: _lessonsFuture,
        builder: (context, snapshot) {
          final lessons = snapshot.data ?? const <Lesson>[];
          final filteredLessons = _filteredLessons(lessons);

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            children: [
              const AppHeader(
                label: '학습',
                title: '레슨 선택',
                showBack: false,
                emoji: '🎙️',
              ),
              const SizedBox(height: 22),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('전체', 'all'),
                    _filterChip('쉬움', 'easy'),
                    _filterChip('보통', 'medium'),
                    _filterChip('어려움', 'hard'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (snapshot.connectionState == ConnectionState.waiting)
                const _CatalogStateCard(
                  icon: Icons.hourglass_empty_rounded,
                  title: '레슨을 불러오는 중입니다',
                  message: '백엔드에서 학습 목록을 가져오고 있어요.',
                )
              else if (snapshot.hasError)
                _CatalogStateCard(
                  icon: Icons.wifi_off_rounded,
                  title: '레슨을 불러오지 못했습니다',
                  message: '${snapshot.error}',
                  actionLabel: '다시 시도',
                  onAction: _reload,
                )
              else if (lessons.isEmpty)
                _CatalogStateCard(
                  icon: Icons.inbox_outlined,
                  title: '등록된 레슨이 없습니다',
                  message: '백엔드 메타데이터를 확인해 주세요.',
                  actionLabel: '새로고침',
                  onAction: _reload,
                )
              else if (filteredLessons.isEmpty)
                const _CatalogStateCard(
                  icon: Icons.filter_alt_off_rounded,
                  title: '조건에 맞는 레슨이 없습니다',
                  message: '다른 난이도를 선택해 보세요.',
                )
              else
                for (var i = 0; i < filteredLessons.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: _lessonCard(
                      context,
                      filteredLessons[i],
                      i,
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final active = selectedDifficulty == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDifficulty = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: active ? null : Colors.white,
          gradient: active ? appWarmGradient : null,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? appCoral : appBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : appText,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _lessonCard(
    BuildContext context,
    Lesson lesson,
    int index,
  ) {
    final color = difficultyColor(lesson.difficulty);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SceneListScreen(lessonId: lesson.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: appBorder, width: .9),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: index.isEven
                      ? const [
                          Color(0xFF315743),
                          Color(0xFF10251C),
                        ]
                      : const [
                          Color(0xFF0C4A35),
                          Color(0xFF06291D),
                        ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 28,
                    top: 28,
                    child: Text(
                      lessonEmoji(index),
                      style: const TextStyle(fontSize: 72),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    bottom: 18,
                    child: Row(
                      children: [
                        Pill(
                          text: difficultyLabel(lesson.difficulty),
                          background: Colors.white.withValues(alpha: .92),
                          foreground: color,
                        ),
                        const SizedBox(width: 8),
                        Pill(
                          text: '${lesson.sceneCount}개 장면',
                          background: Colors.white.withValues(alpha: .92),
                          foreground: appText,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 18,
                    bottom: 54,
                    right: 18,
                    child: Text(
                      lesson.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      lesson.description,
                      style: const TextStyle(
                        color: Color(0xFF5F5A67),
                        fontSize: 15,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: appWarmGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _CatalogStateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(icon, color: appCoral, size: 34),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: appText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: appSubText,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            SoftOutlineButton(
              text: actionLabel!,
              icon: Icons.refresh_rounded,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
