import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/schedule/presentation/screens/schedule_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/tasks/presentation/screens/add_task_screen.dart';
import '../../features/tasks/presentation/screens/edit_task_screen.dart';
import '../../features/tasks/presentation/screens/task_list_screen.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  static const String routeSplash = '/';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeDashboard = '/dashboard';
  static const String routeTasks = '/tasks';
  static const String routeAddTask = '/tasks/add';
  static const String routeEditTask = '/tasks/edit';
  static const String routeSchedule = '/schedule';
  static const String routeSettings = '/settings';

  static Listenable? _getRefreshListenable() {
    try {
      return GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange);
    } catch (_) {
      return null;
    }
  }

  static final GoRouter router = GoRouter(
    initialLocation: routeSplash,
    refreshListenable: _getRefreshListenable(),
    redirect: (BuildContext context, GoRouterState state) {
      Session? session;
      try {
        session = Supabase.instance.client.auth.currentSession;
      } catch (e) {
        debugPrint('AppRouter: Supabase not initialized yet, skipping session check.');
      }
      
      final loggingIn = state.matchedLocation == routeLogin || state.matchedLocation == routeRegister;
      final isSplash = state.matchedLocation == routeSplash;

      if (isSplash) {
        if (session != null) {
          return routeDashboard;
        }
        // Let the SplashScreen build and perform auto-transition timer
        return null;
      }

      if (session == null && !loggingIn) {
        return routeLogin;
      }
      if (session != null && loggingIn) {
        return routeDashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: routeSplash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: routeLogin,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: routeRegister,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: routeDashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: routeTasks,
        builder: (context, state) => const TaskListScreen(),
      ),
      GoRoute(
        path: routeAddTask,
        builder: (context, state) => const AddTaskScreen(),
      ),
      GoRoute(
        path: '$routeEditTask/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return EditTaskScreen(taskId: id);
        },
      ),
      GoRoute(
        path: routeSchedule,
        builder: (context, state) => const ScheduleScreen(),
      ),
      GoRoute(
        path: routeSettings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
