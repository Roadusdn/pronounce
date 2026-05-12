import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../app_tab_controller.dart';
import '../data/mock_data.dart';
import '../widgets/common_widgets.dart';
import 'result_screen.dart';

class LearnScreen extends StatefulWidget {
  final String lessonId;
  final String sceneId;
  final String sentenceId;

  const LearnScreen({
    super.key,
    required this.lessonId,
    required this.sceneId,
    required this.sentenceId,
  });

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();

  late final AnimationController _waveController;

  bool _isRecording = false;
  bool _isAnalyzing = false;
  bool _hasRecorded = false;

  String? _recordPath;
  String _recognizedText = '';

  PracticeSentence get sentence =>
      sentences.firstWhere((s) => s.id == widget.sentenceId);

  List<PracticeSentence> get sceneSentences =>
      sentences.where((s) => s.sceneId == widget.sceneId).toList();

  int get currentIndex =>
      sceneSentences.indexWhere((s) => s.id == widget.sentenceId);

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _confirmExitLearning() async {
    final shouldExit = await showSoftConfirmDialog(
      context: context,
      title: '학습을 종료할까요?',
      message: '지금 학습을 중단하고 홈 화면으로 돌아갈 수 있어요.',
      cancelText: '계속하기',
      confirmText: '홈으로 가기',
    );

    if (shouldExit == true) {
      if (!mounted) return;
      moveToHomeTab();
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _startRecording() async {
    try {
      final allowed = await _recorder.hasPermission();

      if (!allowed) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('마이크 권한이 필요합니다. 설정에서 허용해주세요.'),
          ),
        );
        return;
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/practice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          bitRate: 128000,
        ),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _isAnalyzing = false;
        _hasRecorded = false;
        _recordPath = path;
      });
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('녹음을 시작하지 못했습니다. 다시 시도해주세요.'),
        ),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      final resultPath = await _recorder.stop();

      setState(() {
        _isRecording = false;
        _hasRecorded = true;
        _recordPath = resultPath ?? _recordPath;
        _recognizedText = sentence.text;
      });
    } catch (_) {
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _retryRecording() async {
    if (_recordPath != null) {
      final file = File(_recordPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }

    setState(() {
      _isRecording = false;
      _isAnalyzing = false;
      _hasRecorded = false;
      _recordPath = null;
      _recognizedText = '';
    });
  }

  Future<void> _finishAndAnalyze() async {
    setState(() {
      _isAnalyzing = true;
    });

    await Future.delayed(const Duration(milliseconds: 850));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          lessonId: widget.lessonId,
          sceneId: widget.sceneId,
          sentenceId: widget.sentenceId,
          result: analysisResultForSentence(widget.sentenceId),
        ),
      ),
    );
  }

  void _playNormal() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('기본 속도로 예문을 재생합니다.')),
    );
  }

  void _playSlow() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('느린 속도로 예문을 재생합니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, value) {
        if (didPop) return;
        _confirmExitLearning();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 720;
              final topGap = compact ? 16.0 : 22.0;
              final horizontalPadding = compact ? 16.0 : 18.0;
              final verticalPadding = compact ? 16.0 : 24.0;

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  verticalPadding,
                  horizontalPadding,
                  compact ? 12 : 18,
                ),
                child: Column(
                  children: [
                    _topBar(),
                    SizedBox(height: topGap),
                    _mediaPanel(compact),
                    SizedBox(height: compact ? 12 : 14),
                    _sentenceCard(compact),
                    SizedBox(height: compact ? 10 : 12),
                    Row(
                      children: [
                        Expanded(
                          child: SoftOutlineButton(
                            text: '다시 듣기',
                            icon: Icons.replay_rounded,
                            onPressed: _playNormal,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SoftOutlineButton(
                            text: '느리게 듣기',
                            icon: Icons.play_arrow_rounded,
                            onPressed: _playSlow,
                            color: const Color(0xFF5B8DEF),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 12 : 16),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: _buildBottomState(compact),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBottomState(bool compact) {
    if (_isAnalyzing) return _analyzingView(compact);
    if (_isRecording) return _recordingView(compact);
    if (_hasRecorded) return _recordCompleteView(compact);
    return _readyToRecordView(compact);
  }

  Widget _topBar() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: appBorder),
          ),
          child: IconButton(
            onPressed: _confirmExitLearning,
            icon: const Icon(Icons.close_rounded, color: appText),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: appBorder),
          ),
          child: Text(
            '${currentIndex + 1} / ${sceneSentences.length}',
            style: const TextStyle(
              color: appText,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const Spacer(),
        const SizedBox(width: 46),
      ],
    );
  }

  Widget _mediaPanel(bool compact) {
    return Container(
      height: compact ? 164 : 184,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF243A33),
            Color(0xFF081412),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.13),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                '예문 듣기',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.play_circle_fill_rounded,
              color: Colors.white70,
              size: compact ? 62 : 68,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sentenceCard(bool compact) {
    return AppCard(
      radius: 28,
      padding: EdgeInsets.fromLTRB(22, compact ? 16 : 20, 22, compact ? 14 : 18),
      child: Column(
        children: [
          Text(
            sentence.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: appText,
              fontSize: compact ? 19 : 21,
              height: 1.32,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          Text(
            sentence.targetWord,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF9AA0AE),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _readyToRecordView(bool compact) {
    final size = compact ? 94.0 : 108.0;

    return Column(
      key: const ValueKey('ready'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 20 : 22,
            vertical: compact ? 12 : 14,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEEE8),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            '천천히 따라 말해볼까?',
            style: TextStyle(
              color: appCoral,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(height: compact ? 18 : 22),
        GestureDetector(
          onTap: _startRecording,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF8F72),
                  Color(0xFFFF735C),
                ],
              ),
            ),
            child: Icon(
              Icons.mic_none_rounded,
              color: Colors.white,
              size: compact ? 44 : 50,
            ),
          ),
        ),
      ],
    );
  }

  Widget _recordingView(bool compact) {
    final buttonSize = compact ? 88.0 : 102.0;

    return Column(
      key: const ValueKey('recording'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 20 : 24,
            vertical: compact ? 11 : 13,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: appBorder),
          ),
          child: const Text(
            '듣고 있어요...',
            style: TextStyle(
              color: Color(0xFF777782),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(height: compact ? 20 : 26),
        AnimatedBuilder(
          animation: _waveController,
          builder: (context, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(8, (index) {
                final t = _waveController.value;
                final phase = (t + index * 0.11) % 1.0;
                final barHeight = 16 + (math.sin(phase * math.pi * 2) + 1) * (compact ? 7 : 8);

                return Container(
                  width: compact ? 12 : 14,
                  height: barHeight,
                  margin: EdgeInsets.symmetric(horizontal: compact ? 3 : 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8A6B),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            );
          },
        ),
        SizedBox(height: compact ? 22 : 28),
        GestureDetector(
          onTap: _stopRecording,
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF967A),
                  Color(0xFFFF735C),
                ],
              ),
            ),
            child: Icon(
              Icons.stop_rounded,
              color: Colors.white,
              size: compact ? 40 : 48,
            ),
          ),
        ),
      ],
    );
  }

  Widget _recordCompleteView(bool compact) {
    return Column(
      key: const ValueKey('complete'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFEAFBF0),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            '녹음이 완료됐어요',
            style: TextStyle(
              color: Color(0xFF16A34A),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          radius: 24,
          padding: const EdgeInsets.all(18),
          backgroundColor: const Color(0xFFFDFDFC),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '인식된 문장',
                style: TextStyle(
                  color: Color(0xFF7E8290),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _recognizedText.isEmpty ? sentence.text : _recognizedText,
                style: TextStyle(
                  color: appText,
                  fontSize: compact ? 18 : 19,
                  height: 1.32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: SoftOutlineButton(
                text: '다시 녹음',
                icon: Icons.replay_rounded,
                onPressed: _retryRecording,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _finishAndAnalyze,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF0EA),
                    foregroundColor: appCoral,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '완료하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _analyzingView(bool compact) {
    return Column(
      key: const ValueKey('analyzing'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 20 : 22,
            vertical: compact ? 12 : 14,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFF5F0),
                Color(0xFFFFFBF9),
              ],
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFFFE2D7)),
          ),
          child: const Text(
            '발음을 분석하고 있어요...',
            style: TextStyle(
              color: appCoral,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(height: compact ? 18 : 22),
        const SizedBox(
          width: 34,
          height: 34,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: appCoral,
          ),
        ),
      ],
    );
  }
}
