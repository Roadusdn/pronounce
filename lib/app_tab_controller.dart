import 'package:flutter/foundation.dart';

final ValueNotifier<int> appTabIndexNotifier = ValueNotifier<int>(0);

void moveToHomeTab() {
  appTabIndexNotifier.value = 0;
}

void moveToLearningTab() {
  appTabIndexNotifier.value = 1;
}

void moveToHistoryTab() {
  appTabIndexNotifier.value = 2;
}

void moveToSettingsTab() {
  appTabIndexNotifier.value = 3;
}