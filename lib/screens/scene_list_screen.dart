import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../services/local_attempt_store.dart';
import '../widgets/common_widgets.dart';
import 'learn_screen.dart';

class SceneListScreen extends StatelessWidget {
  final String lessonId;

  const SceneListScreen({
    super.key,
    required this.lessonId,
  });

  @override
  Widget build(BuildContext context) {
    final lesson = lessons.firstWhere((l) => l.id == lessonId);
    final lessonScenes = scenes.where((s) => s.lessonId == lessonId).toList();
    final totalSentences = lessonScenes.fold<int>(
      0,
      (sum, scene) => sum + scene.sentenceCount,
    );
    final completedCount = lessonScenes.where(_isSceneCompleted).length;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          children: [
            AppHeader(
              label: '레슨',
              title: lesson.title,
              onBack: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
            AppCard(
              padding: const EdgeInsets.all(24),
              backgroundColor: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: const TextStyle(
                      color: appText,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lesson.description,
                    style: const TextStyle(
                      color: appSubText,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _summaryBox(
                          label: '진행도',
                          value: '$completedCount / ${lessonScenes.length}',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _summaryBox(
                          label: '총 문장',
                          value: '$totalSentences문장',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              '장면 선택',
              style: TextStyle(
                color: appText,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            for (final scene in lessonScenes)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _sceneCard(context, scene),
              ),
          ],
        ),
      ),
    );
  }

  Widget _summaryBox({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appBorder, width: .8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: appSubText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: appCoral,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }


  bool _isSceneCompleted(SceneItem scene) {
    final sceneSentences = sentences.where((s) => s.sceneId == scene.id).toList();
    if (sceneSentences.isEmpty) return false;

    return sceneSentences.every(
      (sentence) => LocalAttemptStore.hasLocalAttemptForSentence(sentence.text),
    );
  }

  void _startScene(BuildContext context, SceneItem scene, PracticeSentence firstSentence) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LearnScreen(
          lessonId: scene.lessonId,
          sceneId: scene.id,
          sentenceId: firstSentence.id,
        ),
      ),
    );
  }

  Widget _sceneCard(BuildContext context, SceneItem scene) {
    final sceneSentences = sentences.where((s) => s.sceneId == scene.id).toList();
    final firstSentence = sceneSentences.isNotEmpty ? sceneSentences.first : null;
    final completed = _isSceneCompleted(scene);

    return AppCard(
      onTap: firstSentence == null ? null : () => _startScene(context, scene, firstSentence),
      backgroundColor: completed ? const Color(0xFFF3FCF6) : Colors.white,
      border: Border.all(
        color: completed ? const Color(0xFFB9E8C8) : appBorder,
        width: completed ? 1.2 : .9,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Pill(
                          text: scene.pronunciationFocus,
                          background: completed ? const Color(0xFFE0F6E7) : const Color(0xFFEAF2FF),
                          foreground: completed ? const Color(0xFF168044) : const Color(0xFF315CBA),
                        ),
                        Text(
                          '${scene.duration} · ${scene.sentenceCount}문장',
                          style: const TextStyle(
                            color: appSubText,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      scene.title,
                      style: const TextStyle(
                        color: appText,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFFFF4EF),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: completed ? const Color(0xFF22C55E) : appBorder,
                    width: 2,
                  ),
                ),
                child: Icon(
                  completed ? Icons.check_circle_rounded : Icons.play_arrow_rounded,
                  color: completed ? const Color(0xFF22C55E) : appCoral,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: completed ? '다시 학습하기' : '시작하기',
              onPressed: firstSentence == null ? null : () => _startScene(context, scene, firstSentence),
            ),
          ),
        ],
      ),
    );
  }
}
