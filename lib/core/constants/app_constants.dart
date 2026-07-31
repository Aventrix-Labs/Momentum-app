class AppConstants {
  static const String appName = 'ProgressOS';

  // Shared Preferences Keys
  static const String keyDarkMode = 'theme_dark_mode';
  static const String keyNotificationsEnabled = 'notifications_enabled';

  // Supabase Table Names
  static const String tableProfiles = 'profiles';
  static const String tableTasks = 'tasks';
  static const String tableSchedule = 'schedule';

  // Error Messages
  static const String errNetwork = 'Network connection issue. Please check your internet connection.';
  static const String errSupabase = 'A database error occurred. Please try again.';
  static const String errUnexpected = 'An unexpected error occurred. Please try again later.';
}
