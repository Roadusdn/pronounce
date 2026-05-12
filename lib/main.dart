import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_tab_controller.dart';
import 'screens/home_screen.dart';
import 'screens/lesson_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/record_history_screen.dart';
import 'screens/settings_screen.dart';
import 'services/local_attempt_store.dart';
import 'services/local_user_store.dart';
import 'widgets/common_widgets.dart';

const String micPermissionAskedKey = 'mic_permission_asked';
const String micPermissionAllowedKey = 'mic_permission_allowed';

void main() {
  debugPaintSizeEnabled = false;
  debugPaintBaselinesEnabled = false;
  debugPaintPointersEnabled = false;

  runApp(const PronunciationApp());
}

class PronunciationApp extends StatelessWidget {
  const PronunciationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '발음 배우기',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bgColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: appCoral,
          primary: appCoral,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bgColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: appText),
          titleTextStyle: TextStyle(
            color: appText,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: appText),
          bodyMedium: TextStyle(color: appText),
          titleLarge: TextStyle(
            color: appText,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      scrollBehavior: const _NoScrollbarBehavior(),
      builder: (context, child) {
        final fixedTextScale = MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child ?? const SizedBox(),
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 500) {
              return Container(
                color: const Color(0xFFE9E2DD),
                alignment: Alignment.center,
                child: Container(
                  width: 390,
                  height: 844,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(34),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: fixedTextScale,
                ),
              );
            }

            return fixedTextScale;
          },
        );
      },
      home: const AuthGate(),
    );
  }
}

class _NoScrollbarBehavior extends MaterialScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return StretchingOverscrollIndicator(
      axisDirection: details.direction,
      child: child,
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool initialized = false;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    await LocalUserStore.load();
    await LocalAttemptStore.load();

    if (!mounted) return;

    setState(() {
      initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: CircularProgressIndicator(color: appCoral),
        ),
      );
    }

    return ValueListenableBuilder<LocalUser?>(
      valueListenable: LocalUserStore.currentUser,
      builder: (context, user, _) {
        if (user == null) {
          return LoginScreen(
            onLoginComplete: () {
              setState(() {});
            },
          );
        }

        return const AppShell();
      },
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int currentIndex = appTabIndexNotifier.value;

  @override
  void initState() {
    super.initState();

    appTabIndexNotifier.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestMicPermissionOnlyOnce();
    });
  }

  @override
  void dispose() {
    appTabIndexNotifier.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (!mounted) return;

    setState(() {
      currentIndex = appTabIndexNotifier.value;
    });
  }

  Future<void> _requestMicPermissionOnlyOnce() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyAsked = prefs.getBool(micPermissionAskedKey) ?? false;

    if (alreadyAsked) {
      return;
    }

    final recorder = AudioRecorder();

    try {
      final allowed = await recorder.hasPermission();
      await prefs.setBool(micPermissionAskedKey, true);
      await prefs.setBool(micPermissionAllowedKey, allowed);
    } catch (_) {
      await prefs.setBool(micPermissionAskedKey, true);
      await prefs.setBool(micPermissionAllowedKey, false);
    } finally {
      await recorder.dispose();
    }
  }

  void _changeTab(int index) {
    appTabIndexNotifier.value = index;
  }

  Widget _currentScreen() {
    switch (currentIndex) {
      case 0:
        return HomeScreen(
          onStartLearning: () => _changeTab(1),
          onOpenHistory: () => _changeTab(2),
        );
      case 1:
        return const LessonListScreen();
      case 2:
        return const RecordHistoryScreen();
      case 3:
        return const SettingsScreen();
      default:
        return HomeScreen(
          onStartLearning: () => _changeTab(1),
          onOpenHistory: () => _changeTab(2),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: _currentScreen(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
          border: Border(
            top: BorderSide(
              color: Color(0xFFF2E4DD),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: _changeTab,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 0,
              selectedItemColor: appCoral,
              unselectedItemColor: const Color(0xFFAAA6B2),
              selectedFontSize: 13,
              unselectedFontSize: 13,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined, size: 27),
                  activeIcon: Icon(Icons.home_outlined, size: 27),
                  label: '홈',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.format_list_bulleted_rounded, size: 27),
                  activeIcon:
                  Icon(Icons.format_list_bulleted_rounded, size: 27),
                  label: '학습',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history_rounded, size: 27),
                  activeIcon: Icon(Icons.history_rounded, size: 27),
                  label: '기록',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined, size: 27),
                  activeIcon: Icon(Icons.settings_outlined, size: 27),
                  label: '설정',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}