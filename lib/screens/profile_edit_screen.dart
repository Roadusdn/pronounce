import 'package:flutter/material.dart';

import '../services/local_user_store.dart';
import '../widgets/common_widgets.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController nicknameController = TextEditingController();

  bool isSaving = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    final user = LocalUserStore.currentUser.value;

    if (user != null) {
      nicknameController.text = user.nickname;
    }
  }

  @override
  void dispose() {
    nicknameController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final nickname = nicknameController.text.trim();

    if (nickname.isEmpty) {
      setState(() {
        errorMessage = '닉네임을 입력해주세요.';
      });
      return;
    }

    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    await LocalUserStore.updateProfile(
      nickname: nickname,
    );

    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            AppHeader(
              label: '계정',
              title: '프로필 수정',
              onBack: () => Navigator.pop(context),
            ),
            const SizedBox(height: 18),
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '닉네임',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nicknameController,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: '닉네임 입력',
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
                    onSubmitted: (_) => save(),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  PrimaryButton(
                    text: isSaving ? '저장 중...' : '저장하기',
                    icon: Icons.check,
                    onPressed: isSaving ? null : save,
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