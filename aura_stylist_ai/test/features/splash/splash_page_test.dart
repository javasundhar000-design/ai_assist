import 'package:aura_stylist_ai/core/router/app_routes.dart';
import 'package:aura_stylist_ai/features/auth/domain/entities/app_user.dart';
import 'package:aura_stylist_ai/features/auth/presentation/pages/login_page.dart';
import 'package:aura_stylist_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:aura_stylist_ai/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:aura_stylist_ai/features/profile/presentation/providers/profile_providers.dart';
import 'package:aura_stylist_ai/features/splash/presentation/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../auth/fakes/fake_auth_repository.dart';
import '../profile/fakes/fake_profile_repository.dart';

const _testUser = AppUser(
  uid: 'existing-uid',
  email: 'returning@example.com',
  isGuest: false,
  emailVerified: true,
);

/// Builds a minimal router with just the routes involved in the splash ->
/// login/dashboard handoff, so SplashPage's `context.go(...)` calls have
/// somewhere real to land.
GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashPage()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginPage()),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (_, __) => const DashboardPage(),
      ),
    ],
  );
}

Future<void> _pumpAllBootstrapSteps(WidgetTester tester) async {
  // Matches the delays in SplashController: 500 + 700 + (session check,
  // resolved instantly by the fake repo) + 500ms.
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'SplashPage shows branding while loading, then navigates to /login '
    'when no session is restored',
    (tester) async {
      final fakeAuthRepo = FakeAuthRepository(); // signed out

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
            profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
          ],
          child: MaterialApp.router(routerConfig: _buildTestRouter()),
        ),
      );

      // Initial frame: branding is visible immediately.
      expect(find.text('AURA STYLIST AI'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await _pumpAllBootstrapSteps(tester);

      // No session -> should have navigated to LoginPage.
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(SplashPage), findsNothing);
    },
  );

  testWidgets(
    'SplashPage navigates to /dashboard when a session is restored',
    (tester) async {
      final signedInAuthRepo = FakeAuthRepository(initialUser: _testUser);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(signedInAuthRepo),
            profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
          ],
          child: MaterialApp.router(routerConfig: _buildTestRouter()),
        ),
      );

      await _pumpAllBootstrapSteps(tester);

      expect(find.byType(DashboardPage), findsOneWidget);
      expect(find.byType(SplashPage), findsNothing);
    },
  );
}
