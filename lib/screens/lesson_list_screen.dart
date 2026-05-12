import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../widgets/common_widgets.dart';
import 'scene_list_screen.dart';

class LessonListScreen extends StatefulWidget {
  const LessonListScreen({super.key});

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> {
  String selectedDifficulty = 'all';

  List<Lesson> get filteredLessons {
    if (selectedDifficulty == 'all') {
      return lessons;
    }

    return lessons.where((lesson) {
      return lesson.difficulty == selectedDifficulty;
    }).toList();
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
    const emojis = ['🛒', '🎡', '🎒', '🍜', '🏫', '☕'];
    return emojis[index % emojis.length];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        children: [
          const AppHeader(
            label: '학습',
            title: '레슨 선택',
            showBack: false,
            emoji: '📚',
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
                          background: Colors.white.withOpacity(.92),
                          foreground: color,
                        ),
                        const SizedBox(width: 8),
                        Pill(
                          text: '${lesson.sceneCount}개 장면',
                          background: Colors.white.withOpacity(.92),
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
                        letterSpacing: -0.7,
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