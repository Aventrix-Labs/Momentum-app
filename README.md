# Momentum

Momentum is a modern, minimalist, and premium personal productivity Flutter application. It is designed to help users manage daily schedules, track daily tasks, and monitor their completion progress in real-time.

Built from scratch following production-grade standards, the application utilizes Riverpod for state management, GoRouter for navigation, SharedPreferences for settings persistence, Flutter Local Notifications for timed reminders, and Supabase for backend authentication, database storage, and Row Level Security.

---

## Architecture

Momentum follows **Clean Architecture** principles combined with the **Repository Pattern** to ensure the code is modular, decoupled, and easy to extend.

### Layers:

1. **Presentation Layer**: Widgets, UI screens, and Riverpod providers that manage user input, display the interface, and manage visual states.
2. **Domain Layer**: Core business models (Freezed dataclasses) and Repository Interfaces defining the contracts for data operations.
3. **Data Layer**: Repository implementations that coordinate data sources and talk to third-party clients like the Supabase SDK or SharedPreferences.
4. **Backend/Database**: Supabase Auth, PostgreSQL database, Realtime subscriptions, and Row Level Security (RLS) policies.

---

## Folder Structure

```
momentum/
├── lib/
│   ├── main.dart                      # Application initialization & provider overrides
│   ├── core/                          # Core configurations shared across features
│   │   ├── config/                    # Environment variables loader (dotenv)
│   │   ├── constants/                 # Shared strings, error text, and storage keys
│   │   ├── providers/                 # Core SharedPreferences provider DI
│   │   ├── router/                    # GoRouter configuration & reactive redirects
│   │   ├── services/                  # Zoned local notifications reminders service
│   │   ├── theme/                     # Light & Dark Material 3 theme setups
│   │   └── utils/                     # Input validators
│   └── features/                      # Feature modules
│       ├── auth/                      # Login, Register, profiles, and Session Persistence
│       ├── dashboard/                 # Progress calculations, statistics, and main interface
│       ├── tasks/                     # Task model enums, list views, and swipe actions
│       ├── schedule/                  # Schedule timeline list views & bottom sheets forms
│       └── settings/                  # Dark mode, notifications settings, and account actions
├── test/
│   └── widget_test.dart               # Integrated widget tests
├── .env                               # Local environment variables containing secret keys
├── supabase_schema.sql                # Supabase table DDL, indexes, and RLS policies
└── pubspec.yaml                       # Application manifest and dependencies configuration
```

---

## 🛠️ Installation & Setup

### Prerequisites

Before getting started, make sure you have the following installed on your machine:

- **Flutter SDK** (Latest stable version)
- **Dart SDK**
- **Cocoapods** (For iOS build support)
- **Xcode** (For iOS testing/compiles)
- **Android Studio** (For Android testing/compiles)

### 1. Clone & Fetch Dependencies

Navigate to the project directory and fetch the required dependencies:

```bash
cd momentum
flutter pub get
```

### 2. Generate Boilerplate Code

Run `build_runner` to compile the Freezed data models and JSON serialization code:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3. Connect to Supabase Backend

1. Create a new project in your **Supabase Dashboard**.
2. Open the **SQL Editor** in Supabase.
3. Copy the contents of the `supabase_schema.sql` file in this project's root and run it in the SQL Editor. This will initialize the tables (`profiles`, `tasks`, and `schedule`), indexes, and RLS policies.
4. In your project directory, copy or open the `.env` file and replace the values with your actual project keys (found in your Supabase project under Settings > API):
   ```env
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_ANON_KEY=your-supabase-anon-key
   ```

---

## Running the Application

### Running on a Simulator/Emulator

List the available emulator/simulator devices:

```bash
flutter devices
```

Run the application on your desired device:

```bash
# Run on all connected devices
flutter run

# Run on macOS desktop
flutter run -d macos

# Run on a specific device
flutter run -d <device-id>
```

---

## Building a Release APK (Android)

To compile a production-ready, release build of the Android application:

1. Clean the build directories:

   ```bash
   flutter clean
   flutter pub get
   ```

2. Compile the release APK:
   ```bash
   flutter build apk --release
   ```

This will produce the release APK file in the following output folder:
`build/app/outputs/flutter-apk/app-release.apk`

To build an App Bundle (recommended for publishing to the Google Play Store):

```bash
flutter build appbundle --release
```

Outputs in:
`build/app/outputs/bundle/release/app-release.aab`
