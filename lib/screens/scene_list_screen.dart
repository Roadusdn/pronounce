import 'package:flutter/material.dart';

import '../models/pronunciation_models.dart';
import '../repositories/pronunciation_repository.dart';
import '../services/local_attempt_store.dart';
import '../widgets/common_widgets.dart';
import 'learn_screen.dart';

class SceneListScreen extends StatefulWidget {
  final String lessonId;

  const SceneListScreen({
    super.key,
    required this.lessonId,
  });

  @override
  State<SceneListScreen> createState() => _SceneListScreenState();
}

class _SceneListScreenState extends State<SceneListScreen> {
  late Future<LessonSceneBundle> _bundleFuture;

  @override
  void initState() {
    super.initState();
    _bundleFuture = PronunciationRepository.instance.getLessonSceneBundle(
      widget.lessonId,
    );
  }

  void _reload() {
    setState(() {
      _bundleFuture = PronunciationRepository.instance.getLessonSceneBundle(
        widget.lessonId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: FutureBuilder<LessonSceneBundle>(
          future: _bundleFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _stateView(
                title: '장면을 불러오는 중입니다',
                message: '백엔드에서 레슨 구성을 가져오고 있어요.',
                icon: Icons.hourglass_empty_rounded,
              );
            }

            if (snapshot.hasError) {
              return _stateView(
                title: '장면을 불러오지 못했습니다',
                message: '${snapshot.error}',
                icon: Icons.wifi_off_rounded,
                actionLabel: '다시 시도',
                onAction: _reload,
              );
            }

            final bundle = snapshot.data;
            if (bundle == null || bundle.scenes.isEmpty) {
              return _stateView(
                title: '등록된 장면이 없습니다',
                message: '백엔드 메타데이터의 scene_ids를 확인해 주세요.',
                icon: Icons.inbox_outlined,
                actionLabel: '새로고침',
                onAction: _reload,
              );
            }

            return _sceneList(bundle);
          },
        ),
      ),
    );
  }

  Widget _sceneList(LessonSceneBundle bundle) {
    final completedCount = bundle.scenes.where((scene) {
      return _isSceneCompleted(
        bundle.sentencesBySceneId[scene.id] ?? const [],
      );
    }).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      children: [
        AppHeader(
          label: '레슨',
          title: bundle.lesson.title,
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
                bundle.lesson.title,
                style: const TextStyle(
                  color: appText,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                bundle.lesson.description,
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
                      label: '진행률',
                      value: '$completedCount / ${bundle.scenes.length}',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _summaryBox(
                      label: '총 문장',
                      value: '${bundle.totalSentenceCount}문장',
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
        for (final scene in bundle.scenes)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _sceneCard(
              scene,
              bundle.sentencesBySceneId[scene.id] ?? const [],
            ),
          ),
      ],
    );
  }

  Widget _stateView({
    required String title,
    required String message,
    required IconData icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      children: [
        AppHeader(
          label: '레슨',
          title: '장면 목록',
          onBack: () => Navigator.pop(context),
        ),
        const SizedBox(height: 20),
        AppCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Icon(icon, color: appCoral, size: 36),
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
                  text: actionLabel,
                  icon: Icons.refresh_rounded,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      ],
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

  bool _isSceneCompleted(List<PracticeSentence> sceneSentences) {
    if (sceneSentences.isEmpty) return false;

    return sceneSentences.every(
      (sentence) => LocalAttemptStore.hasLocalAttemptForSentence(sentence.text),
    );
  }

  void _startScene(
    SceneItem scene,
    PracticeSentence firstSentence,
  ) {
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

  Widget _sceneCard(
    SceneItem scene,
    List<PracticeSentence> sceneSentences,
  ) {
    final firstSentence = sceneSentences.isNotEmpty ? sceneSentences.first : null;
    final completed = _isSceneCompleted(sceneSentences);

    return AppCard(
      onTap: firstSentence == null ? null : () => _startScene(scene, firstSentence),
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
                          background: completed
                              ? const Color(0xFFE0F6E7)
                              : const Color(0xFFEAF2FF),
                          foreground: completed
                              ? const Color(0xFF168044)
                              : const Color(0xFF315CBA),
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
                  completed
                      ? Icons.check_circle_rounded
                      : Icons.play_arrow_rounded,
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
              onPressed: firstSentence == null
                  ? null
                  : () => _startScene(scene, firstSentence),
            ),
          ),
        ],
      ),
    );
  }
}
