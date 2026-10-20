import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quietdude/app/app.dart';
import 'package:quietdude/app/providers.dart';

import '../fixtures/fake_platform_adapter.dart';
import '../fixtures/fake_rule_repository.dart';
import '../fixtures/rule_fixtures.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester,
    FakeRuleRepository repository,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ruleRepositoryProvider.overrideWithValue(repository),
          platformAdapterProvider.overrideWithValue(FakePlatformAdapter()),
        ],
        child: const QuietdudeApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('launches and displays the home screen', (tester) async {
    final repository = FakeRuleRepository([buildRule(name: 'Work focus')]);
    addTearDown(repository.dispose);

    await pumpApp(tester, repository);

    expect(find.text('Quietdude'), findsOneWidget);
    expect(find.text('Your notifications. Your rules.'), findsOneWidget);
    expect(find.text('Enforcement is not implemented yet'), findsOneWidget);
    expect(find.text('1 rule · 1 enabled'), findsOneWidget);
    expect(find.text('Work focus'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Manage rules'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Manage rules'), findsOneWidget);
  });

  testWidgets('navigates to the rules screen and creates a rule', (
    tester,
  ) async {
    final repository = FakeRuleRepository();
    addTearDown(repository.dispose);

    await pumpApp(tester, repository);

    await tester.scrollUntilVisible(
      find.text('Manage rules'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Manage rules'));
    await tester.pumpAndSettle();
    expect(find.text('No rules yet'), findsOneWidget);

    await tester.tap(find.text('Add rule'));
    await tester.pumpAndSettle();
    expect(find.text('New rule'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Focus mode');
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(find.text('Focus mode'), findsOneWidget);
    expect(find.text('No rules yet'), findsNothing);
    expect(await repository.getRules(), hasLength(1));
  });
}
