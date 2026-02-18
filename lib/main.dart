import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_config.dart';
import 'services/notification_service.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/task_detail_screen.dart';
import 'screens/tag_management_screen.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    realtimeClientOptions: const RealtimeClientOptions(
      eventsPerSecond: 2,
    ),
  );

  // Initialize locale data for Japanese
  await initializeDateFormatting('ja');

  // Initialize notifications (iOS only)
  if (!kIsWeb) {
    await NotificationService().initialize();
    await NotificationService().requestPermissions();
  }

  runApp(const ProviderScope(child: TodoApp()));
}

class TodoApp extends ConsumerWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    final router = GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final isLoggedIn =
            Supabase.instance.client.auth.currentUser != null;
        final isAuthRoute = state.matchedLocation == '/auth';

        if (!isLoggedIn && !isAuthRoute) return '/auth';
        if (isLoggedIn && isAuthRoute) return '/';
        return null;
      },
      routes: [
        GoRoute(
          path: '/auth',
          builder: (context, state) => const AuthScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/task/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            return TaskDetailScreen(
              taskId: id == 'new' ? null : id,
            );
          },
        ),
        GoRoute(
          path: '/tags',
          builder: (context, state) => const TagManagementScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'ToDo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
