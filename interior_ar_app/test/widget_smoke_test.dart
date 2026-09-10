import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_assist/core/theme/app_theme.dart';
import 'package:ai_assist/shared/cards/accessible_card.dart';

void main() {
  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(theme: AppTheme.light, home: Scaffold(body: child)),
    );
  }

  testWidgets('AccessibleCard renders title and responds to tap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      wrap(
        AccessibleCard(
          title: 'Blind',
          subtitle: 'Vision Support',
          icon: Icons.check_circle_rounded,
          onTap: () => tapped = true,
        ),
      ),
    );

    expect(find.text('Blind'), findsOneWidget);
    expect(find.text('Vision Support'), findsOneWidget);

    await tester.tap(find.byType(AccessibleCard));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('AccessibleCard shows a selected border state without crashing', (tester) async {
    await tester.pumpWidget(
      wrap(const AccessibleCard(title: 'Non-Speaking', selected: true)),
    );
    expect(find.text('Non-Speaking'), findsOneWidget);
  });
}
