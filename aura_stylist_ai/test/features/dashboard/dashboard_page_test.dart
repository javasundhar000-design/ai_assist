import 'package:aura_stylist_ai/core/router/app_routes.dart';
import 'package:aura_stylist_ai/features/auth/domain/entities/app_user.dart';
import 'package:aura_stylist_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:aura_stylist_ai/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:aura_stylist_ai/features/profile/domain/entities/user_profile.dart';
import 'package:aura_stylist_ai/features/profile/presentation/providers/profile_providers.dart';
import 'package:aura_stylist_ai/features/wardrobe/presentation/pages/wardrobe_page.dart';
import 'package:aura_stylist_ai/features/wardrobe/presentation/providers/wardrobe_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';


import '../auth/fakes/fake_auth_repository.dart';
import '../profile/fakes/fake_profile_repository.dart';
import '../wardrobe/fakes/fake_wardrobe_repository.dart';

const _user = AppUser(
  uid: 'uid-1',
  email: 'priya@example.com',
  displayName: 'Priya',
  isGuest: false,
  emailVerified: true,
);

void main() {
  testWidgets(
    'DashboardPage greets the signed-in user by profile name and shows '
    'the feature grid',
    (tester) async {
      final authRepo = FakeAuthRepository(initialUser: _user);
      final profileRepo = FakeProfileRepository(seed: {
        'uid-1': UserProfile(
          uid: 'uid-1',
          name: 'Priya',
          email: 'priya@example.com',
          createdAt: DateTime.now(),
        ),
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepo),
            profileRepositoryProvider.overrideWithValue(profileRepo),
          ],
          child: const MaterialApp(home: DashboardPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome back, Priya!'), findsOneWidget);
      expect(find.text('Smart Mirror'), findsOneWidget);
      expect(find.text('Wardrobe'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
    },
  );

  testWidgets(
    'Tapping the Wardrobe card navigates to the real WardrobePage (Module 10)',
    (tester) async {
      final authRepo = FakeAuthRepository(initialUser: _user);
      final profileRepo = FakeProfileRepository(seed: {
        'uid-1': UserProfile(
          uid: 'uid-1',
          name: 'Priya',
          createdAt: DateTime.now(),
        ),
      });

      final router = GoRouter(
        initialLocation: AppRoutes.dashboard,
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.wardrobe,
            builder: (context, state) => const WardrobePage(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepo),
            profileRepositoryProvider.overrideWithValue(profileRepo),
            wardrobeRepositoryProvider.overrideWithValue(FakeWardrobeRepository()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wardrobe'));
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
    },
  );
}
