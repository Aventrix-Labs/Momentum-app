import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/shared_prefs_provider.dart';

class SettingsState {
  final bool isDarkMode;
  final bool isNotificationsEnabled;

  const SettingsState({
    required this.isDarkMode,
    required this.isNotificationsEnabled,
  });

  SettingsState copyWith({
    bool? isDarkMode,
    bool? isNotificationsEnabled,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isNotificationsEnabled: isNotificationsEnabled ?? this.isNotificationsEnabled,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref _ref;

  SettingsNotifier(this._ref)
      : super(const SettingsState(isDarkMode: false, isNotificationsEnabled: true)) {
    _loadSettings();
  }

  void _loadSettings() {
    final prefs = _ref.read(sharedPreferencesProvider);
    final isDark = prefs.getBool(AppConstants.keyDarkMode) ?? false;
    final notifications = prefs.getBool(AppConstants.keyNotificationsEnabled) ?? true;
    state = SettingsState(isDarkMode: isDark, isNotificationsEnabled: notifications);
  }

  Future<void> toggleDarkMode() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    final newValue = !state.isDarkMode;
    await prefs.setBool(AppConstants.keyDarkMode, newValue);
    state = state.copyWith(isDarkMode: newValue);
  }

  Future<void> toggleNotifications(bool value) async {
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setBool(AppConstants.keyNotificationsEnabled, value);
    state = state.copyWith(isNotificationsEnabled: value);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref);
});
