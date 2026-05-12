import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalUser {
  final String id;
  final String nickname;
  final String createdAt;

  const LocalUser({
    required this.id,
    required this.nickname,
    required this.createdAt,
  });

  LocalUser copyWith({
    String? nickname,
  }) {
    return LocalUser(
      id: id,
      nickname: nickname ?? this.nickname,
      createdAt: createdAt,
    );
  }
}

class LocalUserStore {
  LocalUserStore._();

  static const String userIdKey = 'local_user_id';
  static const String nicknameKey = 'local_nickname';
  static const String createdAtKey = 'local_user_created_at';

  static final ValueNotifier<LocalUser?> currentUser =
  ValueNotifier<LocalUser?>(null);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final id = prefs.getString(userIdKey);
    final nickname = prefs.getString(nicknameKey);
    final createdAt = prefs.getString(createdAtKey);

    if (id == null || id.isEmpty || nickname == null || nickname.isEmpty) {
      currentUser.value = null;
      return;
    }

    currentUser.value = LocalUser(
      id: id,
      nickname: nickname,
      createdAt: createdAt ?? DateTime.now().toIso8601String(),
    );
  }

  static Future<void> createUser({
    required String nickname,
  }) async {
    final cleanedNickname = nickname.trim();

    if (cleanedNickname.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    final now = DateTime.now();
    final id = 'local_${now.millisecondsSinceEpoch}';
    final createdAt = now.toIso8601String();

    await prefs.setString(userIdKey, id);
    await prefs.setString(nicknameKey, cleanedNickname);
    await prefs.setString(createdAtKey, createdAt);

    currentUser.value = LocalUser(
      id: id,
      nickname: cleanedNickname,
      createdAt: createdAt,
    );
  }

  static Future<void> updateProfile({
    required String nickname,
  }) async {
    final user = currentUser.value;
    final cleanedNickname = nickname.trim();

    if (user == null || cleanedNickname.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(nicknameKey, cleanedNickname);

    currentUser.value = user.copyWith(
      nickname: cleanedNickname,
    );
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(userIdKey);
    await prefs.remove(nicknameKey);
    await prefs.remove(createdAtKey);

    currentUser.value = null;
  }
}