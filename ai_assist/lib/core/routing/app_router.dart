
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers.dart';
import '../../models/user_role.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/login/login_screen.dart';
import '../../features/auth/register/register_screen.dart';
import '../../features/auth/forgot_password/forgot_password_screen.dart';
import '../../features/blind/dashboard/blind_dashboard.dart';
import '../../features/blind/read_document/read_document_screen.dart';
import '../../features/blind/medicine/medicine_screen.dart';
import '../../features/blind/object/object_screen.dart';
import '../../features/blind/currency/currency_screen.dart';
import '../../features/blind/scene/scene_screen.dart';
import '../../features/blind/history/blind_history_screen.dart';
import '../../features/non_speaking/dashboard/non_speaking_dashboard.dart';
import '../../features/non_speaking/notepad/notepad_screen.dart';
import '../../features/motor/dashboard/motor_dashboard.dart';
import '../../features/motor/calibration/eye_calibration_screen.dart';
import '../../features/motor/keyboard/eye_keyboard_screen.dart';
import '../../features/motor/history/motor_history_screen.dart';
import '../../features/caregiver/dashboard/caregiver_dashboard.dart';
import '../../features/caregiver/linked_users/linked_users_screen.dart';
import '../../features/caregiver/alerts/alerts_screen.dart';
import '../../features/caregiver/activities/activities_screen.dart';
import '../../features/admin/dashboard/admin_dashboard.dart';
import '../../features/admin/users/manage_users_screen.dart';
import '../../features/admin/caregivers/manage_caregivers_screen.dart';
import '../../features/admin/roles/manage_roles_screen.dart';
import '../../features/admin/system/system_monitor_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../widgets/error_view.dart';

/// Every route below is also independently re-checked by the backend (spec
/// §5/§43). This router's `redirect` is a UX convenience — it stops a user
/// from ever *seeing* a screen for a role/permission they don't hold, but it
/// is not the security boundary. The API rejects the underlying request
/// regardless of what this file allows the UI to render.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _GoRouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loggingIn = state.matchedLocation == '/login';
      final registering = state.matchedLocation == '/register';
      final forgotPassword = state.matchedLocation == '/forgot-password';
      final onSplash = state.matchedLocation == '/splash';

      // Still resolving the persisted session — stay on splash.
      if (auth.status == AuthStatus.unknown) {
        return onSplash ? null : '/splash';
      }

      final authed = auth.status == AuthStatus.authenticated;

      if (!authed) {
        // Unauthenticated users may only reach login/register/forgot-password.
        if (loggingIn || registering || forgotPassword) return null;
        return '/login';
      }

      // Authenticated users never manually pick a dashboard (spec §4) and
      // never linger on splash/login/register.
      if (onSplash || loggingIn || registering) {
        return auth.user!.role.homeRoute;
      }

      // Role-prefix routing guard: a BLIND user can't navigate into
      // /admin/* etc. even by typing the URL or a stale deep link.
      final role = auth.user!.role;
      final path = state.matchedLocation;
      final rolePrefixes = {
        UserRole.blind: '/blind',
        UserRole.nonSpeaking: '/non-speaking',
        UserRole.motorImpaired: '/motor',
        UserRole.caregiver: '/caregiver',
        UserRole.admin: '/admin',
      };
      for (final entry in rolePrefixes.entries) {
        if (path.startsWith(entry.value) && entry.key != role) {
          return role.homeRoute;
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen()),

      // Shared
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),

      // Blind
      GoRoute(path: '/blind/home', builder: (context, state) => const BlindDashboard()),
      GoRoute(
          path: '/blind/read-document',
          builder: (context, state) => ReadDocumentScreen()),
      GoRoute(path: '/blind/read-medicine', builder: (context, state) => MedicineScreen()),
      GoRoute(
          path: '/blind/object-recognition',
          builder: (context, state) => ObjectRecognitionScreen()),
      GoRoute(
          path: '/blind/currency-recognition',
          builder: (context, state) => CurrencyRecognitionScreen()),
      GoRoute(
          path: '/blind/scene-understanding',
          builder: (context, state) => SceneUnderstandingScreen()),
      GoRoute(path: '/blind/history', builder: (context, state) => const BlindHistoryScreen()),

      // Non-speaking
      GoRoute(
          path: '/non-speaking/home',
          builder: (context, state) => const NonSpeakingDashboard()),
      GoRoute(
          path: '/non-speaking/notepad', builder: (context, state) => const NotepadScreen()),

      // Motor-impaired
      GoRoute(path: '/motor/home', builder: (context, state) => const MotorDashboard()),
      GoRoute(
          path: '/motor/calibration',
          builder: (context, state) => const EyeCalibrationScreen()),
      GoRoute(path: '/motor/keyboard', builder: (context, state) => const EyeKeyboardScreen()),
      GoRoute(path: '/motor/history', builder: (context, state) => const MotorHistoryScreen()),

      // Caregiver
      GoRoute(path: '/caregiver/home', builder: (context, state) => const CaregiverDashboard()),
      GoRoute(
          path: '/caregiver/users', builder: (context, state) => const LinkedUsersScreen()),
      GoRoute(path: '/caregiver/alerts', builder: (context, state) => const AlertsScreen()),
      GoRoute(
          path: '/caregiver/activities',
          builder: (context, state) => const ActivitiesScreen()),

      // Admin
      GoRoute(path: '/admin/home', builder: (context, state) => const AdminDashboard()),
      GoRoute(path: '/admin/users', builder: (context, state) => const ManageUsersScreen()),
      GoRoute(
          path: '/admin/caregivers',
          builder: (context, state) => const ManageCaregiversScreen()),
      GoRoute(path: '/admin/roles', builder: (context, state) => const ManageRolesScreen()),
      GoRoute(path: '/admin/system', builder: (context, state) => const SystemMonitorScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not Found')),
      body: const ErrorView(message: 'That page could not be found.'),
    ),
  );
});

/// Bridges Riverpod's AuthState stream into a Listenable so GoRouter
/// re-evaluates `redirect` every time auth status changes (login, logout,
/// session restore).
class _GoRouterRefreshNotifier extends ChangeNotifier {
  late final ProviderSubscription<AuthState> _subscription;

  _GoRouterRefreshNotifier(Ref ref) {
    _subscription = ref.listen<AuthState>(
      authControllerProvider,
      (previous, next) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
