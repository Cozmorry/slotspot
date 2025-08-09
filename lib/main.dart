import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/analytics/analytics_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/auth/auth_providers.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/settings/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Allow running without Firebase configured yet
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const lavenderSeed = Color(0xFFB57EDC); // default lavender

    final authAsync = ref.watch(authStateChangesProvider);
    final router = _createRouter(authAsync);

    final themeMode = ref.watch(themeModeControllerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'SlotSpot',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: lavenderSeed,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: lavenderSeed,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

class RootShell extends StatelessWidget {
  const RootShell({super.key, required this.child, required this.currentLocation});

  final Widget child;
  final String currentLocation;

  static const tabs = ['/reserve', '/crowd', '/feedback', '/analytics', '/profile'];

  @override
  Widget build(BuildContext context) {
    final currentIndex = tabs.indexWhere((t) => currentLocation.startsWith(t)).clamp(0, tabs.length - 1);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => context.go(tabs[index]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.event_available), label: 'Reserve'),
          NavigationDestination(icon: Icon(Icons.groups), label: 'Crowdsource'),
          NavigationDestination(icon: Icon(Icons.feedback), label: 'Feedback'),
          NavigationDestination(icon: Icon(Icons.analytics), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// Simple placeholder screens
class ReserveScreen extends StatelessWidget {
  const ReserveScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Reserve'));
}

class CrowdsourceScreen extends StatelessWidget {
  const CrowdsourceScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Crowdsource'));
}

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Feedback'));
}

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});
  @override
  Widget build(BuildContext context) => const AnalyticsScreenView();
}

GoRouter _createRouter(AsyncValue<User?> authAsync) {
  return GoRouter(
    initialLocation: '/signin',
    redirect: (context, state) {
      final isAuthKnown = !authAsync.isLoading;
      final isLoggedIn = authAsync.asData?.value != null;
      final isOnSignIn = state.uri.toString().startsWith('/signin');

      if (!isAuthKnown) return null; // wait
      if (!isLoggedIn && !isOnSignIn) return '/signin';
      if (isLoggedIn && isOnSignIn) return '/reserve';
      return null;
    },
    routes: [
      GoRoute(path: '/signin', builder: (ctx, st) => const SignInScreen()),
      ShellRoute(
        builder: (context, state, child) => RootShell(
          key: state.pageKey,
          currentLocation: state.uri.toString(),
          child: child,
        ),
        routes: [
          GoRoute(path: '/reserve', builder: (ctx, st) => const ReserveScreen()),
          GoRoute(path: '/crowd', builder: (ctx, st) => const CrowdsourceScreen()),
          GoRoute(path: '/feedback', builder: (ctx, st) => const FeedbackScreen()),
          GoRoute(path: '/analytics', builder: (ctx, st) => const AnalyticsScreen()),
          GoRoute(path: '/profile', builder: (ctx, st) => const ProfileScreen()),
        ],
      ),
    ],
  );
}
