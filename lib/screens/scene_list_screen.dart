import 'package:flutter/material.dart';

import '../api/pronunciation_api_client.dart';
import '../models/pronunciation_models.dart';
import '../widgets/common_widgets.dart';
import 'learn_screen.dart';

class SceneListScreen extends StatefulWidget {
  final Lesson lesson;

  const SceneListScreen({super.key, required this.lesson});

  @override
  State<SceneListScreen> createState() => _SceneListScreenState();
}

class _SceneListScreenState extends State<SceneListScreen> {
  final api = PronunciationApiClient();
  late Future<List<Utterance>> utterancesFuture;

  @override
  void initState() {
    super.initState();
    utterancesFuture = api.getSceneUtterances(widget.lesson.sceneId);
  }

  @override
  void dispose() {
    api.close();
    super.dispose();
  }

  void _reload() {
    setState(() {
      utterancesFuture = api.getSceneUtterances(widget.lesson.sceneId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.chevron_left),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white24,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '뒤로가기',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '문장 선택',
                    style: TextStyle(
                      color: Color(0xFFDBEAFE),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.lesson.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.lesson.description,
                    style: const TextStyle(color: Color(0xFFDBEAFE)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Utterance>>(
                future: utterancesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _UtteranceState(
                      icon: Icons.cloud_sync_outlined,
                      title: '문장을 불러오는 중',
                    );
                  }

                  if (snapshot.hasError) {
                    return _UtteranceState(
                      icon: Icons.error_outline,
                      title: '문장을 불러오지 못했어요',
                      body: snapshot.error.toString(),
                      actionLabel: '다시 시도',
                      onAction: _reload,
                    );
                  }

                  final utterances = snapshot.data ?? const [];
                  if (utterances.isEmpty) {
                    return const _UtteranceState(
                      icon: Icons.inbox_outlined,
                      title: '연습할 문장이 없어요',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: utterances.length,
                    itemBuilder: (_, i) {
                      final utterance = utterances[i];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFFDBEAFE),
                                    foregroundColor: appBlue,
                                    child: Text('${i + 1}'),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      utterance.practiceText,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                utterance.subtitleText,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Pill(
                                    text: utterance.difficulty,
                                    background: const Color(0xFFF1F5F9),
                                    foreground: const Color(0xFF475569),
                                  ),
                                  Pill(
                                    text:
                                        '${utterance.pauseSec.toStringAsFixed(1)}초 멈춤',
                                    background: const Color(0xFFDBEAFE),
                                    foreground: const Color(0xFF1D4ED8),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              PrimaryButton(
                                text: '연습 시작',
                                icon: Icons.play_arrow,
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LearnScreen(
                                      lesson: widget.lesson,
                                      utterances: utterances,
                                      initialIndex: i,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UtteranceState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _UtteranceState({
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: appBlue, size: 46),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
