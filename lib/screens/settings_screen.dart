import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/local_attempt_store.dart';
import '../services/local_user_store.dart';
import '../widgets/common_widgets.dart';
import 'account_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AudioRecorder recorder = AudioRecorder();

  bool isTesting = false;
  String micStatus = '확인 중';
  String selectedLanguage = '한국어';

  @override
  void initState() {
    super.initState();
    loadMicStatus();
    loadLanguage();
  }

  @override
  void dispose() {
    recorder.dispose();
    super.dispose();
  }

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('app_language') ?? 'ko';

    if (!mounted) return;
    setState(() {
      selectedLanguage = saved == 'en' ? 'English' : '한국어';
    });
  }

  Future<void> saveLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', code);

    if (!mounted) return;
    setState(() {
      selectedLanguage = code == 'en' ? 'English' : '한국어';
    });
  }

  Future<void> showLanguageSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: appBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '언어 설정',
                      style: TextStyle(
                        color: appText,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '학습 화면에서 사용할 기본 언어를 선택해요.',
                      style: TextStyle(
                        color: appSubText,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _languageOption(
                    context: sheetContext,
                    code: 'ko',
                    title: '한국어',
                    subtitle: '기본 한국어 학습 화면',
                    icon: Icons.check_rounded,
                  ),
                  const SizedBox(height: 10),
                  _languageOption(
                    context: sheetContext,
                    code: 'en',
                    title: 'English',
                    subtitle: '영문 보조 표기 사용',
                    icon: Icons.translate_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      },
    );
  }

  Widget _languageOption({
    required BuildContext context,
    required String code,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = (code == 'ko' && selectedLanguage == '한국어') ||
        (code == 'en' && selectedLanguage == 'English');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await saveLanguage(code);
          if (context.mounted) Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? appCoralLight : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? const Color(0xFFFFB9A9) : appBorder,
            ),
          ),
          child: Row(
            children: [
              CuteIconBubble(
                icon: selected ? Icons.check_rounded : icon,
                background: selected ? appCoral : appSky,
                foreground: selected ? Colors.white : const Color(0xFF5B8DEF),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: appText,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: appSubText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showPrivacyPolicy() async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: .78,
          minChildSize: .45,
          maxChildSize: .92,
          expand: false,
          builder: (context, controller) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: appBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 34),
                      children: [
                        const Text(
                          '개인정보 처리방침',
                          style: TextStyle(
                            color: appText,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _policyBlock(
                          title: '1. 수집하는 개인정보',
                          body: '저희 앱은 발음 학습을 위해 음성 녹음 데이터, 학습 진행 기록, 계정 정보(이름, 프로필)를 수집합니다.',
                        ),
                        _policyBlock(
                          title: '2. 개인정보의 이용 목적',
                          body: '수집된 정보는 발음 분석, 학습 진도 추적, 개인화된 학습 경험 제공을 위해서만 사용됩니다.',
                        ),
                        _policyBlock(
                          title: '3. 개인정보의 보관',
                          body: '모든 개인정보는 안전하게 저장되며, 서비스 종료 또는 사용자의 삭제 요청 시 즉시 삭제됩니다.',
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: appMint,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.verified_user_outlined, color: Color(0xFF16A34A)),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '개인정보는 학습 기능 제공을 위한 최소 범위에서만 사용됩니다.',
                                  style: TextStyle(
                                    color: Color(0xFF117A3D),
                                    fontWeight: FontWeight.w800,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
          },
        );
      },
    );
  }

  Widget _policyBlock({required String title, required String body}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: appText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF5D6472),
              height: 1.55,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> loadMicStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final asked = prefs.getBool('mic_permission_asked') ?? false;
    final allowed = prefs.getBool('mic_permission_allowed') ?? false;

    if (!mounted) return;
    setState(() {
      if (!asked) {
        micStatus = '미설정';
      } else if (allowed) {
        micStatus = '허용됨';
      } else {
        micStatus = '거부됨';
      }
    });
  }

  Future<void> testMic() async {
    if (isTesting) return;

    setState(() {
      isTesting = true;
    });

    try {
      final allowed = await recorder.hasPermission();
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('mic_permission_asked', true);
      await prefs.setBool('mic_permission_allowed', allowed);

      if (!allowed) {
        setState(() {
          micStatus = '거부됨';
          isTesting = false;
        });
        return;
      }

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/mic_test_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      await Future.delayed(const Duration(seconds: 2));

      final resultPath = await recorder.stop();

      if (resultPath != null) {
        final file = File(resultPath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      setState(() {
        micStatus = '허용됨';
      });
    } catch (_) {
      setState(() {
        micStatus = '오류';
      });
    } finally {
      if (mounted) {
        setState(() {
          isTesting = false;
        });
      }
    }
  }

  Future<void> clearHistory() async {
    final result = await showSoftConfirmDialog(
      context: context,
      title: '기록을 초기화할까요?',
      message: '기기에 저장된 로컬 학습 기록만 삭제됩니다.',
      cancelText: '취소',
      confirmText: '초기화',
      danger: true,
    );

    if (result == true) {
      await LocalAttemptStore.clearLocalOnly();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('학습 기록이 초기화되었습니다.'),
        ),
      );
    }
  }

  Color micStatusColor() {
    switch (micStatus) {
      case '허용됨':
        return const Color(0xFF16A34A);
      case '거부됨':
      case '오류':
        return const Color(0xFFEF4444);
      default:
        return appSubText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LocalUser?>(
      valueListenable: LocalUserStore.currentUser,
      builder: (context, user, _) {
        final nickname = user?.nickname ?? '사용자';
        final initial = nickname.trim().isEmpty ? '?' : nickname.characters.first;

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            children: [
              const Text(
                '설정 ⚙️',
                style: TextStyle(
                  color: appText,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '앱 환경을 관리할 수 있어요',
                style: TextStyle(
                  color: appSubText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 28),
              AppCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AccountScreen(),
                    ),
                  );
                },
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE8C8),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFD79C),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: appCoral,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nickname,
                            style: const TextStyle(
                              color: appText,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '학습자 계정',
                            style: TextStyle(
                              color: appSubText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      '수정',
                      style: TextStyle(
                        color: appCoral,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                '기기 설정',
                style: TextStyle(
                  color: appText,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _settingRow(
                      icon: Icons.language_rounded,
                      iconBg: const Color(0xFFEAF1FF),
                      iconColor: const Color(0xFF2563EB),
                      title: '언어',
                      onTap: showLanguageSheet,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            selectedLanguage,
                            style: const TextStyle(
                              color: appSubText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: appSubText,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF2EAE5)),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const CuteIconBubble(
                            icon: Icons.mic_rounded,
                            background: appCoralLight,
                            foreground: appCoral,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '마이크 권한',
                                  style: TextStyle(
                                    color: appText,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  micStatus == '허용됨'
                                      ? '✓ 허용됨'
                                      : micStatus == '거부됨'
                                          ? '권한 허용이 필요해요'
                                          : micStatus,
                                  style: TextStyle(
                                    color: micStatusColor(),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: isTesting ? null : testMic,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appCream,
                                foregroundColor: appCoral,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: Text(
                                isTesting ? '테스트 중' : '마이크 테스트',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                '정보',
                style: TextStyle(
                  color: appText,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _settingRow(
                      icon: Icons.shield_outlined,
                      iconBg: appMint,
                      iconColor: const Color(0xFF16A34A),
                      title: '개인정보 처리방침',
                      onTap: showPrivacyPolicy,
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: appSubText,
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF2EAE5)),
                    _settingRow(
                      icon: Icons.delete_outline_rounded,
                      iconBg: const Color(0xFFFFE4E6),
                      iconColor: const Color(0xFFE11D48),
                      title: '학습 기록 초기화',
                      titleColor: const Color(0xFFE11D48),
                      onTap: clearHistory,
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: appSubText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _settingRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    Color? titleColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CuteIconBubble(
                icon: icon,
                background: iconBg,
                foreground: iconColor,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: titleColor ?? appText,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }
}
