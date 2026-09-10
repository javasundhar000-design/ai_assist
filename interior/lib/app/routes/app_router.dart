import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/authentication/providers/auth_provider.dart';
import '../../features/authentication/screens/forgot_password_screen.dart';
import '../../features/authentication/screens/login_screen.dart';
import '../../features/authentication/screens/register_screen.dart';
import '../../features/authentication/screens/splash_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/projects/screens/create_project_screen.dart';
import '../../features/projects/screens/project_details_screen.dart';
import '../../features/room_scanner/screens/room_scanner_screen.dart';
import '../../features/room_scanner/screens/scan_preview_screen.dart';
import '../../features/room_analysis/screens/room_analysis_screen.dart';
import '../../features/room_analysis/screens/detected_objects_screen.dart';
import '../../features/furniture/screens/furniture_catalog_screen.dart';
import '../../features/furniture/screens/furniture_details_screen.dart';
import '../../features/furniture/screens/furniture_3d_preview_screen.dart';
import '../../features/interior_design/screens/design_style_selection_screen.dart';
import '../../features/interior_design/screens/design_recommendation_screen.dart';
import '../../features/ar_visualization/screens/ar_visualization_screen.dart';
import '../../features/design_history/screens/design_history_screen.dart';
import '../../features/design_history/screens/design_details_screen.dart';
import '../../features/design_history/screens/design_comparison_select_screen.dart';
import '../../features/design_history/screens/design_comparison_screen.dart';

/// Single source of truth for navigation + the
/// "authenticated? -> dashboard : login" decision (Sec. 6 flow).
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/create-project',
        builder: (_, __) => const CreateProjectScreen(),
      ),
      GoRoute(
        path: '/projects/:id',
        builder: (context, state) => ProjectDetailsScreen(
          projectId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/projects/:id/scan-room',
        builder: (context, state) => RoomScannerScreen(
          projectId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/projects/:id/scan-preview',
        builder: (context, state) => ScanPreviewScreen(
          projectId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/projects/:id/room-analysis/:roomId',
        builder: (context, state) => RoomAnalysisScreen(
          projectId: state.pathParameters['id']!,
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/projects/:id/room-analysis/:roomId/objects',
        builder: (context, state) => DetectedObjectsScreen(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/furniture',
        builder: (_, __) => const FurnitureCatalogScreen(),
      ),
      GoRoute(
        path: '/furniture/:id',
        builder: (context, state) => FurnitureDetailsScreen(
          furnitureId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/furniture/:id/3d',
        builder: (context, state) => Furniture3DPreviewScreen(
          furnitureId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/projects/:id/room-analysis/:roomId/style',
        builder: (context, state) => DesignStyleSelectionScreen(
          projectId: state.pathParameters['id']!,
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/projects/:id/room-analysis/:roomId/recommendations',
        builder: (context, state) => DesignRecommendationScreen(
          projectId: state.pathParameters['id']!,
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/projects/:id/room-analysis/:roomId/ar',
        builder: (context, state) => ArVisualizationScreen(
          projectId: state.pathParameters['id']!,
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/projects/:id/designs',
        builder: (context, state) => DesignHistoryScreen(
          projectId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/projects/:id/designs/compare',
        builder: (context, state) {
          final a = state.uri.queryParameters['a'];
          final b = state.uri.queryParameters['b'];
          if (a == null || b == null) {
            // Shouldn't happen via normal navigation (the select screen
            // always supplies both), but fail gracefully rather than
            // crash on a malformed deep link.
            return const Scaffold(
              body: Center(child: Text('Select two designs to compare.')),
            );
          }
          return DesignComparisonScreen(designIdA: a, designIdB: b);
        },
      ),
      // NOTE: this dynamic :designId route must stay AFTER the static
      // /designs/compare route above — go_router matches in declaration
      // order, and :designId would otherwise swallow "compare" as if it
      // were a design id.
      GoRoute(
        path: '/projects/:id/designs/:designId',
        builder: (context, state) => DesignDetailsScreen(
          projectId: state.pathParameters['id']!,
          designId: state.pathParameters['designId']!,
        ),
      ),
      GoRoute(
        path: '/projects/:id/designs-compare-select',
        builder: (context, state) => DesignComparisonSelectScreen(
          projectId: state.pathParameters['id']!,
        ),
      ),
    ],
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final onSplash = loc == '/splash';
      final onAuthScreen = loc == '/login' ||
          loc == '/register' ||
          loc == '/forgot-password';

      return authState.when(
        loading: () => onSplash ? null : '/splash',
        error: (_, __) => onAuthScreen ? null : '/login',
        data: (user) {
          final signedIn = user != null;
          if (!signedIn) {
            return onAuthScreen ? null : '/login';
          }
          // Signed in: never let them sit on splash/login/register.
          if (onSplash || onAuthScreen) return '/dashboard';
          return null;
        },
      );
    },
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authStateProvider.notifier).stream,
    ),
  );
});

/// Bridges a Riverpod stream to ChangeNotifier so GoRouter can react to
/// auth-state changes and re-run its `redirect` callback.
class GoRouterRefreshStream extends ChangeNotifier {
  late final Stream<dynamic> _stream;
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _stream = stream.asBroadcastStream();
    _stream.listen((_) => notifyListeners());
  }
}
