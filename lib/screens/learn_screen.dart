import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../api/pronunciation_api_client.dart';
import '../models/pronunciation_models.dart';
import '../widgets/common_widgets.dart';
import 'result_screen.dart';

enum LearnState { playing, paused, recording, recorded, uploading, error }

class LearnScreen extends StatefulWidget {
  final Lesson lesson;
  final List<Utterance> utterances;
  final int initialIndex;

  const LearnScreen({
    super.key,
    required this.lesson,
    required this.utterances,
    required this.initialIndex,
  });

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final api = PronunciationApiClient();
  final random = Random();
  LearnState state = LearnState.playing;
  Timer? timer;
  double clipProgress = 0;
  double recordingTime = 0;
  String statusMessage = '제출을 준비하고 있어요';
  String? errorMessage;

  late int currentIndex = widget.initialIndex;

  Utterance get utterance => widget.utterances[currentIndex];

  @override
  void initState() {
    super.initState();
    _playClip();
  }

  @override
  void dispose() {
    timer?.cancel();
    api.close();
    super.dispose();
  }

  void _playClip() {
    timer?.cancel();
    setState(() {
      state = LearnState.playing;
      clipProgress = 0;
      errorMessage = null;
    });

    timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      final pauseSec = utterance.pauseSec <= 0 ? 1.5 : utterance.pauseSec;
      setState(() {
        clipProgress =
            (clipProgress + (100 / (pauseSec * 10))).clamp(0, 100).toDouble();
      });

      if (clipProgress >= 100) {
        t.cancel();
        setState(() => state = LearnState.paused);
      }
    });
  }

  void _startRecording() {
    timer?.cancel();
    setState(() {
      state = LearnState.recording;
      recordingTime = 0;
      errorMessage = null;
    });

    timer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => setState(() => recordingTime += .1),
    );
  }

  Future<void> _submit() async {
    timer?.cancel();
    setState(() {
      state = LearnState.uploading;
      statusMessage = '시도를 시작하고 있어요';
      errorMessage = null;
    });

    try {
      final started = await api.startAttempt(
        lessonId: widget.lesson.id,
        sceneId: widget.lesson.sceneId,
        utteranceId: utterance.id,
      );
      if (!mounted) return;

      setState(() => statusMessage = '녹음을 업로드하고 있어요');
      await api.uploadAttemptAudio(
        attemptId: started.attemptId,
        audioBytes: _recordingPlaceholderBytes(),
      );
      if (!mounted) return;

      final completed = await _waitForResult(started.attemptId);
      if (!mounted) return;

      setState(() => statusMessage = '결과를 불러오고 있어요');
      final result = await api.getAttemptResult(completed.attemptId);
      final phonemes = await api.getAttemptPhoneme(completed.attemptId);
      final pitch = await api.getAttemptPitch(completed.attemptId);
      final feedback = await api.getAttemptFeedback(completed.attemptId);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            lesson: widget.lesson,
            utterances: widget.utterances,
            currentIndex: currentIndex,
            result: result,
            phonemes: phonemes,
            pitch: pitch,
            feedback: feedback,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        state = LearnState.error;
        errorMessage = error.toString();
      });
    }
  }

  Future<AttemptStatus> _waitForResult(String attemptId) async {
    for (var i = 0; i < 20; i++) {
      final status = await api.getAttemptStatus(attemptId);
      if (!mounted) return status;

      setState(() {
        statusMessage =
            status.message.isEmpty ? '분석이 진행 중이에요' : status.message;
      });

      if (status.isComplete) return status;
      if (status.isFailed) {
        throw PronunciationApiException(
          status.message.isEmpty ? '분석에 실패했어요' : status.message,
        );
      }

      await Future<void>.delayed(const Duration(seconds: 2));
    }

    throw const PronunciationApiException('분석 결과가 아직 준비되지 않았어요');
  }

  Uint8List _recordingPlaceholderBytes() {
    final payload = {
      'utterance_id': utterance.id,
      'recording_duration_sec': recordingTime,
      'client_note': 'Replace this scaffold with recorder audio bytes.',
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(payload)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${currentIndex + 1} / ${widget.utterances.length}',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              for (int i = 0; i < widget.utterances.length; i++)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == currentIndex
                          ? appBlue
                          : i < currentIndex
                              ? Colors.green
                              : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _clipArea(),
          const SizedBox(height: 18),
          _utteranceCard(),
          const SizedBox(height: 18),
          _stateArea(),
        ],
      ),
    );
  }

  Widget _clipArea() {
    final isPlaying = state == LearnState.playing;

    return Container(
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF020617)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPlaying ? Icons.play_circle_fill : Icons.pause_circle_filled,
                  color: Colors.white.withOpacity(isPlaying ? 1 : .55),
                  size: 72,
                ),
                const SizedBox(height: 8),
                Text(
                  utterance.clipFilename,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LinearProgressIndicator(
              value: clipProgress / 100,
              backgroundColor: Colors.white12,
              color: appBlue,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _utteranceCard() {
    final muted = state == LearnState.playing;

    return AnimatedOpacity(
      opacity: muted ? .55 : 1,
      duration: const Duration(milliseconds: 250),
      child: AppCard(
        child: Column(
          children: [
            Text(
              muted ? utterance.subtitleText : utterance.practiceText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: muted ? 19 : 25,
                fontWeight: FontWeight.w900,
                height: 1.45,
                color: const Color(0xFF0F172A),
              ),
            ),
            if (!muted) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Pill(
                    text: utterance.difficulty,
                    background: const Color(0xFFF1F5F9),
                    foreground: const Color(0xFF475569),
                  ),
                  const SizedBox(width: 8),
                  Pill(
                    text: '${utterance.pauseSec.toStringAsFixed(1)}초 후 따라하기',
                    background: const Color(0xFFDBEAFE),
                    foreground: const Color(0xFF1D4ED8),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stateArea() {
    switch (state) {
      case LearnState.paused:
        return Column(
          children: [
            OutlinedButton.icon(
              onPressed: _playClip,
              icon: const Icon(Icons.play_arrow),
              label: const Text('다시 듣기'),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              text: '녹음 시작하기',
              icon: Icons.mic,
              onPressed: _startRecording,
            ),
          ],
        );

      case LearnState.recording:
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
            ),
          ),
          child: Column(
            children: [
              const Text(
                '녹음 중',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${recordingTime.toStringAsFixed(1)}초',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(
                  12,
                  (i) => Container(
                    width: 6,
                    height: 18 + random.nextInt(45).toDouble(),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => state = LearnState.paused),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        timer?.cancel();
                        setState(() => state = LearnState.recorded);
                      },
                      child: const Text('완료'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      case LearnState.recorded:
        return AppCard(
          child: Column(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 56),
              const SizedBox(height: 8),
              const Text(
                '녹음 완료',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _startRecording,
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('다시 녹음'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('업로드'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      case LearnState.uploading:
        return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
            ),
          ),
          child: Column(
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              Text(
                statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );

      case LearnState.error:
        return AppCard(
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 8),
              const Text(
                '요청을 완료하지 못했어요',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ],
              const SizedBox(height: 14),
              PrimaryButton(
                text: '다시 시도',
                onPressed: () => setState(() => state = LearnState.recorded),
              ),
            ],
          ),
        );

      case LearnState.playing:
        return const SizedBox.shrink();
    }
  }
}
