import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';

import '../app_tab_controller.dart';
import '../models/pronunciation_models.dart';
import '../repositories/pronunciation_repository.dart';
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
  final GlobalKey<_SentenceVideoPanelState> _videoKey =
      GlobalKey<_SentenceVideoPanelState>();

  late final AnimationController _waveController;
  late Future<List<PracticeSentence>> _sentencesFuture;

  bool _isRecording = false;
  bool _isAnalyzing = false;
  bool _isTranscribing = false;
  bool _hasRecorded = false;

  String? _recordPath;
  String _recognizedText = '';
  String _transcriptionError = '';

  @override
  void initState() {
    super.initState();
    _sentencesFuture = PronunciationRepository.instance.getSentencesForScene(
      widget.sceneId,
    );
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

  PracticeSentence? _currentSentence(List<PracticeSentence> sentences) {
    for (final sentence in sentences) {
      if (sentence.id == widget.sentenceId) return sentence;
    }
    return sentences.isEmpty ? null : sentences.first;
  }

  Future<void> _confirmExitLearning() async {
    final shouldExit = await showSoftConfirmDialog(
      context: context,
      title: '학습을 종료할까요?',
      message: '현재 학습을 중단하고 홈으로 돌아갑니다.',
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
          const SnackBar(content: Text('마이크 권한이 필요합니다.')),
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
        _isTranscribing = false;
        _hasRecorded = false;
        _recordPath = path;
        _recognizedText = '';
        _transcriptionError = '';
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('녹음을 시작하지 못했습니다. 다시 시도해 주세요.')),
      );
    }
  }

  Future<void> _stopRecording(PracticeSentence sentence) async {
    try {
      final resultPath = await _recorder.stop();

      setState(() {
        _isRecording = false;
        _isTranscribing = true;
        _hasRecorded = true;
        _recordPath = resultPath ?? _recordPath;
        _recognizedText = '';
        _transcriptionError = '';
      });

      await _transcribeRecordedAudio();
    } catch (_) {
      setState(() {
        _isRecording = false;
        _isTranscribing = false;
      });
    }
  }

  Future<void> _transcribeRecordedAudio() async {
    final recordPath = _recordPath;
    if (recordPath == null) {
      setState(() {
        _isTranscribing = false;
        _transcriptionError = '녹음 파일을 찾을 수 없습니다.';
      });
      return;
    }

    final audioFile = File(recordPath);
    if (!await audioFile.exists() || await audioFile.length() == 0) {
      setState(() {
        _isTranscribing = false;
        _transcriptionError = '녹음 파일이 비어 있습니다.';
      });
      return;
    }

    try {
      final transcript = await PronunciationRepository.instance
          .transcribeRecording(audioFile);
      if (!mounted) return;
      setState(() {
        _isTranscribing = false;
        _recognizedText = transcript;
        _transcriptionError = transcript.isEmpty ? '음성을 인식하지 못했습니다.' : '';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isTranscribing = false;
        _recognizedText = '';
        _transcriptionError = '음성 인식에 실패했습니다: $error';
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
      _isTranscribing = false;
      _hasRecorded = false;
      _recordPath = null;
      _recognizedText = '';
      _transcriptionError = '';
    });
  }

  Future<void> _finishAndAnalyze(
    PracticeSentence sentence,
    List<PracticeSentence> sceneSentences,
  ) async {
    final recordPath = _recordPath;
    if (recordPath == null) return;

    final audioFile = File(recordPath);
    if (!await audioFile.exists() || await audioFile.length() == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('녹음 파일이 비어 있습니다. 다시 녹음해 주세요.')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await PronunciationRepository.instance.analyzeRecording(
        lessonId: widget.lessonId,
        sceneId: widget.sceneId,
        sentence: sentence,
        audioFile: audioFile,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            lessonId: widget.lessonId,
            sceneId: widget.sceneId,
            sentenceId: sentence.id,
            sentence: sentence,
            sceneSentences: sceneSentences,
            result: result,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('분석에 실패했습니다: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PracticeSentence>>(
      future: _sentencesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: bgColor,
            body: Center(child: CircularProgressIndicator(color: appCoral)),
          );
        }

        if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
          return Scaffold(
            backgroundColor: bgColor,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AppCard(
                  child: Text(
                    snapshot.hasError
                        ? '문장을 불러오지 못했습니다. ${snapshot.error}'
                        : '학습할 문장이 없습니다.',
                    style: const TextStyle(
                      color: appText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final sceneSentences = snapshot.data!;
        final sentence = _currentSentence(sceneSentences);
        if (sentence == null) return const SizedBox.shrink();

        return _learningScaffold(sentence, sceneSentences);
      },
    );
  }

  Widget _learningScaffold(
    PracticeSentence sentence,
    List<PracticeSentence> sceneSentences,
  ) {
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
              final hasVideo = sentence.videoUrl.trim().isNotEmpty;

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 16 : 18,
                  compact ? 16 : 24,
                  compact ? 16 : 18,
                  compact ? 12 : 18,
                ),
                child: Column(
                  children: [
                    _topBar(sceneSentences),
                    SizedBox(height: compact ? 16 : 22),
                    _mediaPanel(sentence, compact),
                    SizedBox(height: compact ? 12 : 14),
                    _sentenceCard(sentence, compact),
                    SizedBox(height: compact ? 10 : 12),
                    Row(
                      children: [
                        Expanded(
                          child: SoftOutlineButton(
                            text: '다시 듣기',
                            icon: Icons.replay_rounded,
                            onPressed: hasVideo
                                ? () => _videoKey.currentState?.replay()
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SoftOutlineButton(
                            text: '느리게 듣기',
                            icon: Icons.play_arrow_rounded,
                            onPressed: hasVideo
                                ? () => _videoKey.currentState?.replay(
                                      speed: 0.75,
                                    )
                                : null,
                            color: const Color(0xFF5B8DEF),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 12 : 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: _buildBottomState(
                              sentence,
                              sceneSentences,
                              compact,
                            ),
                          ),
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

  Widget _buildBottomState(
    PracticeSentence sentence,
    List<PracticeSentence> sceneSentences,
    bool compact,
  ) {
    if (_isAnalyzing) return _analyzingView(compact);
    if (_isRecording) return _recordingView(sentence, compact);
    if (_hasRecorded) {
      return _recordCompleteView(sentence, sceneSentences, compact);
    }
    return _readyToRecordView(compact);
  }

  Widget _topBar(List<PracticeSentence> sceneSentences) {
    final currentIndex = sceneSentences.indexWhere(
      (sentence) => sentence.id == widget.sentenceId,
    );

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

  Widget _mediaPanel(PracticeSentence sentence, bool compact) {
    return _SentenceVideoPanel(
      key: _videoKey,
      videoUrl: sentence.videoUrl,
      compact: compact,
    );
  }

  Widget _sentenceCard(PracticeSentence sentence, bool compact) {
    return AppCard(
      radius: 28,
      padding: EdgeInsets.fromLTRB(22, compact ? 14 : 18, 22, compact ? 14 : 18),
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
            '천천히 따라 말해볼까요?',
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
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF8F72), Color(0xFFFF735C)],
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

  Widget _recordingView(PracticeSentence sentence, bool compact) {
    final buttonSize = compact ? 88.0 : 102.0;

    return Column(
      key: const ValueKey('recording'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '듣고 있어요...',
          style: TextStyle(
            color: Color(0xFF777782),
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: compact ? 20 : 26),
        AnimatedBuilder(
          animation: _waveController,
          builder: (context, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(8, (index) {
                final phase = (_waveController.value + index * 0.11) % 1.0;
                final barHeight =
                    16 + (math.sin(phase * math.pi * 2) + 1) * (compact ? 7 : 8);

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
          onTap: () => _stopRecording(sentence),
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF967A), Color(0xFFFF735C)],
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

  Widget _recordCompleteView(
    PracticeSentence sentence,
    List<PracticeSentence> sceneSentences,
    bool compact,
  ) {
    return Column(
      key: const ValueKey('complete'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '녹음이 완료되었습니다',
          style: TextStyle(
            color: Color(0xFF16A34A),
            fontSize: 14,
            fontWeight: FontWeight.w900,
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
                '인식한 문장',
                style: TextStyle(
                  color: Color(0xFF7E8290),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _recordedTextForDisplay(),
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
                  onPressed: _isTranscribing
                      || _transcriptionError.isNotEmpty
                      || _recognizedText.isEmpty
                      ? null
                      : () => _finishAndAnalyze(sentence, sceneSentences),
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
                      '분석하기',
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

  String _recordedTextForDisplay() {
    if (_isTranscribing) return '음성을 인식하고 있습니다...';
    if (_transcriptionError.isNotEmpty) return _transcriptionError;
    if (_recognizedText.isNotEmpty) return _recognizedText;
    return '인식된 문장이 없습니다.';
  }

  Widget _analyzingView(bool compact) {
    return Column(
      key: const ValueKey('analyzing'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '발음을 분석하고 있어요...',
          style: TextStyle(
            color: appCoral,
            fontSize: 16,
            fontWeight: FontWeight.w900,
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

class _SentenceVideoPanel extends StatefulWidget {
  final String videoUrl;
  final bool compact;

  const _SentenceVideoPanel({
    super.key,
    required this.videoUrl,
    required this.compact,
  });

  @override
  State<_SentenceVideoPanel> createState() => _SentenceVideoPanelState();
}

class _SentenceVideoPanelState extends State<_SentenceVideoPanel> {
  VideoPlayerController? _controller;
  Future<void>? _initializeFuture;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _configureController();
  }

  @override
  void didUpdateWidget(covariant _SentenceVideoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _configureController();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> replay({double speed = 1.0}) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    await controller.setPlaybackSpeed(speed);
    await controller.seekTo(Duration.zero);
    await controller.play();
    if (mounted) setState(() {});
  }

  void _configureController() {
    _controller?.dispose();
    _controller = null;
    _initializeFuture = null;
    _hasError = false;

    final url = widget.videoUrl.trim();
    if (url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) {
      _hasError = true;
      return;
    }

    final controller = VideoPlayerController.networkUrl(uri);
    _controller = controller;
    _initializeFuture = controller.initialize().then((_) {
      controller.setLooping(false);
      if (mounted) setState(() {});
    }).catchError((_) {
      _hasError = true;
      if (mounted) setState(() {});
    });
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.setPlaybackSpeed(1.0);
      await controller.play();
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.compact ? 164.0 : 184.0;
    final controller = _controller;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: height,
        color: const Color(0xFF10231E),
        child: _buildContent(controller),
      ),
    );
  }

  Widget _buildContent(VideoPlayerController? controller) {
    if (widget.videoUrl.trim().isEmpty) {
      return _message('연습 영상이 아직 준비되지 않았습니다.', Icons.videocam_off_rounded);
    }

    if (_hasError) {
      return _message('영상 파일을 찾을 수 없습니다.', Icons.videocam_off_rounded);
    }

    return FutureBuilder<void>(
      future: _initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            controller == null ||
            !controller.value.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white70),
          );
        }

        return GestureDetector(
          onTap: _togglePlayback,
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
              AnimatedOpacity(
                opacity: controller.value.isPlaying ? 0 : 1,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  color: Colors.black26,
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.white.withValues(alpha: .82),
                    size: widget.compact ? 62 : 68,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _message(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: widget.compact ? 42 : 48),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
