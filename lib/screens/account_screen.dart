import 'package:flutter/material.dart';

import '../models/pronunciation_models.dart';
import '../screens/profile_edit_screen.dart';
import '../services/local_attempt_store.dart';
import '../services/local_user_store.dart';
import '../widgets/common_widgets.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  int _averageScore(List<Attempt> attempts) {
    if (attempts.isEmpty) return 0;

    final sum = attempts.fold<int>(
      0,
      (acc, item) => acc + item.overallScore,
    );

    return (sum / attempts.length).round();
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final result = await showSoftConfirmDialog(
      context: context,
      title: '로그아웃할까요?',
      message: '현재 로컬 계정에서 나갑니다. 학습 기록은 별도로 초기화하지 않는 한 유지됩니다.',
      cancelText: '취소',
      confirmText: '로그아웃',
      danger: true,
    );

    if (result == true) {
      await LocalUserStore.logout();

      if (!context.mounted) return;

      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LocalUser?>(
      valueListenable: LocalUserStore.currentUser,
      builder: (context, user, _) {
        if (user == null) {
          return Scaffold(
            backgroundColor: bgColor,
            body: SafeArea(
              child: Center(
                child: PrimaryButton(
                  text: '로그인 화면으로 돌아가기',
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: ValueListenableBuilder<List<Attempt>>(
              valueListenable: LocalAttemptStore.attempts,
              builder: (context, attempts, _) {
                final average = _averageScore(attempts);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  children: [
                    AppHeader(
                      label: '계정',
                      title: '내 계정',
                      onBack: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 18),
                    AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            width: 86,
                            height: 86,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFFEEE8),
                            ),
                            child: Center(
                              child: Text(
                                user.nickname.isEmpty
                                    ? '?'
                                    : user.nickname.characters.first,
                                style: const TextStyle(
                                  color: appCoral,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '${user.nickname}님',
                            style: const TextStyle(
                              fontSize: 24,
                              color: appText,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '고려인 한국어 발음 학습자',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _statBox(
                                  label: '학습 횟수',
                                  value: '${attempts.length}',
                                  background: const Color(0xFFFFF5EF),
                                  accent: appCoral,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _statBox(
                                  label: '평균 점수',
                                  value: average == 0 ? '-' : '$average',
                                  background: const Color(0xFFF4F8FF),
                                  accent: const Color(0xFF4D89F7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _menuTile(
                            icon: Icons.edit_outlined,
                            title: '프로필 수정',
                            subtitle: '닉네임 변경',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProfileEditScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 24),
                          _menuTile(
                            icon: Icons.logout,
                            title: '로그아웃',
                            subtitle: '현재 로컬 계정에서 나가기',
                            danger: true,
                            onTap: () => _confirmLogout(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _statBox({
    required String label,
    required String value,
    required Color background,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final color = danger ? const Color(0xFFE85D4D) : appCoral;
    final bubbleBg = danger ? const Color(0xFFFFECE9) : appCoralLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: bubbleBg,
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: danger ? const Color(0xFFE85D4D) : appText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
