import 'package:aura_stylist_ai/core/router/app_router.dart';
import 'package:aura_stylist_ai/core/router/app_routes.dart';
import 'package:aura_stylist_ai/features/auth/domain/entities/app_user.dart';
import 'package:aura_stylist_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:aura_stylist_ai/features/profile/domain/entities/user_profile.dart';
import 'package:aura_stylist_ai/features/profile/presentation/providers/profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/auth/fakes/fake_auth_repository.dart';
import '../../features/profile/fakes/fake_profile_repository.dart';

/// Regression test for a real bug: signing in updated Firebase correctly,
/// but the login screen never navigated away. The cause was `redirect`
/// reading a separately-subscribed async provider (`authStateChangesProvider`)
/// that hadn't caught up yet at the moment `refreshListenable` fired --
/// see `routerProvider`'s doc comment for the full explanation. `redirect`
/// now reads `authRepository.currentUser` directly, which has no such lag.
void main() {
  late FakeAuthRepository authRepo;
  late ProviderContainer container;

  setUp(() {
    authRepo = FakeAuthRepository(); // starts signed out
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        profileRepositoryProvider.overrideWithValue(
          FakeProfileRepository(seed: {
            'test-uid': UserProfile(
              uid: 'test-uid',
              name: 'Test User',
              createdAt: DateTime.now(),
            ),
          }),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> pumpAppAt(WidgetTester tester, {required String location}) async {
    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    // A bounded pump, not pumpAndSettle(): the app boots at /splash (per
    // routerProvider's fixed initialLocation) whose logo has two
    // indefinitely-repeating AnimationControllers -- pumpAndSettle()
    // would hang waiting for those to finish, which they never do.
    await tester.pump();
    router.go(location);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets(
    'signing in from /login automatically navigates to /dashboard '
    '(regression test for the redirect race)',
    (tester) async {
      await pumpAppAt(tester, location: AppRoutes.login);
      expect(find.text('Welcome back'), findsOneWidget);

      // Sign in "out of band" -- exactly what LoginController does after a
      // successful FirebaseAuth call: it never navigates itself, it only
      // updates auth state and trusts the router's redirect to react.
      await authRepo.signInWithEmail(email: 'test@example.com', password: 'x');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Welcome back'), findsNothing);
      // "Wardrobe" is a Dashboard-only nav card label -- its presence
      // confirms the redirect actually landed on /dashboard, not just
      // that /login's own content disappeared.
      expect(find.text('Wardrobe'), findsOneWidget);
    },
  );

  testWidgets(
    'signing out from /dashboard automatically navigates to /login',
    (tester) async {
      authRepo = FakeAuthRepository(
        initialUser: const AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          displayName: 'Test User',
          isGuest: false,
          emailVerified: true,
        ),
      );
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
          profileRepositoryProvider.overrideWithValue(
            FakeProfileRepository(seed: {
              'test-uid': UserProfile(
                uid: 'test-uid',
                name: 'Test User',
                createdAt: DateTime.now(),
              ),
            }),
          ),
        ],
      );
      addTearDown(container.dispose);

      await pumpAppAt(tester, location: AppRoutes.dashboard);

      await authRepo.signOut();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Welcome back'), findsOneWidget);
    },
  );

  testWidgets('signed-out user hitting a protected route is sent to /login',
      (tester) async {
    await pumpAppAt(tester, location: AppRoutes.wardrobe);
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
