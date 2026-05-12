import 'package:flutter/material.dart';

import '../services/local_user_store.dart';
import '../widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginComplete;

  const LoginScreen({
    super.key,
    required this.onLoginComplete,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController nicknameController = TextEditingController();

  bool isSubmitting = false;
  String? errorMessage;

  @override
  void dispose() {
    nicknameController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final nickname = nicknameController.text.trim();

    if (nickname.isEmpty) {
      setState(() {
        errorMessage = '닉네임을 입력해주세요.';
      });
      return;
    }

    setState(() {
      isSubmitting = true;
      errorMessage = null;
    });

    await LocalUserStore.createUser(
      nickname: nickname,
    );

    if (!mounted) return;

    widget.onLoginComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 34, 24, 28),
          children: [
            const SizedBox(height: 24),
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: appBlue.withOpacity(.12),
              ),
              child: const Icon(
                Icons.record_voice_over,
                color: appBlue,
                size: 40,
              ),
            ),
            const SizedBox(height: 26),
            const Text(
              '발음 연습을\n시작해볼까요?',
              style: TextStyle(
                fontSize: 34,
                height: 1.15,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '닉네임을 입력하면 학습 기록을 이 기기에 저장하고 이어서 연습할 수 있습니다.',
              style: TextStyle(
                color: Color(0xFF64748B),
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 28),
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '닉네임',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nicknameController,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: '예: 지우',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: Color(0xFFE2E8F0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: Color(0xFFE2E8F0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: appBlue,
                          width: 2,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => submit(),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  PrimaryButton(
                    text: isSubmitting ? '시작 준비 중...' : '시작하기',
                    icon: Icons.arrow_forward,
                    onPressed: isSubmitting ? null : submit,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '현재 계정 정보는 기기 내부에만 저장됩니다. 추후 로그인 API가 연결되면 서버 계정으로 전환할 수 있습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}