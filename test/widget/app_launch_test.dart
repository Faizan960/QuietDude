import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quietdude/app/app.dart';
import 'package:quietdude/app/providers.dart';
import 'package:quietdude/domain/models/notification_listener.dart';

import '../fixtures/fake_platform_adapter.dart';
import '../fixtures/fake_rule_repository.dart';
import '../fixtures/rule_fixtures.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester,
    FakeRuleRepository repository, {
    FakePlatformAdapter? adapter,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ruleRepositoryProvider.overrideWithValue(repository),
          platformAdapterProvider.overrideWithValue(
            adapter ?? FakePlatformAdapter(),
          ),
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
    expect(find.text('Access not granted'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('1 rule · 1 enabled'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
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

  testWidgets('refreshes listener access when the app resumes', (tester) async {
    final repository = FakeRuleRepository();
    addTearDown(repository.dispose);
    final adapter = FakePlatformAdapter();
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );

    await pumpApp(tester, repository, adapter: adapter);
    expect(find.text('Access not granted'), findsOneWidget);
    final initialRequests = adapter.listenerStatusRequests;

    adapter.listenerStatus = const NotificationListenerStatus(
      access: NotificationAccessStatus.granted,
      connection: NotificationConnectionStatus.connected,
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(adapter.listenerStatusRequests, greaterThan(initialRequests));
    expect(find.text('Access granted'), findsOneWidget);
    expect(find.text('Listener connected'), findsOneWidget);
  });

  testWidgets('refreshes listener access on native connection changes', (
    tester,
  ) async {
    final repository = FakeRuleRepository();
    addTearDown(repository.dispose);
    final connectionEvents =
        StreamController<NotificationConnectionStatus>.broadcast();
    addTearDown(connectionEvents.close);
    final adapter = FakePlatformAdapter(
      connectionEvents: connectionEvents.stream,
    );

    await pumpApp(tester, repository, adapter: adapter);
    expect(find.text('Access not granted'), findsOneWidget);

    adapter.listenerStatus = const NotificationListenerStatus(
      access: NotificationAccessStatus.granted,
      connection: NotificationConnectionStatus.connected,
    );
    connectionEvents.add(NotificationConnectionStatus.connected);
    await tester.pumpAndSettle();

    expect(find.text('Access granted'), findsOneWidget);
    expect(find.text('Listener connected'), findsOneWidget);
  });

  testWidgets('reconciles a lagging access read after a connection change', (
    tester,
  ) async {
    final repository = FakeRuleRepository();
    addTearDown(repository.dispose);
    final connectionEvents =
        StreamController<NotificationConnectionStatus>.broadcast();
    addTearDown(connectionEvents.close);
    final adapter = FakePlatformAdapter(
      connectionEvents: connectionEvents.stream,
    );

    await pumpApp(tester, repository, adapter: adapter);
    expect(find.text('Access not granted'), findsOneWidget);

    connectionEvents.add(NotificationConnectionStatus.connected);
    await tester.pump();
    await tester.pump();

    adapter.listenerStatus = const NotificationListenerStatus(
      access: NotificationAccessStatus.granted,
      connection: NotificationConnectionStatus.connected,
    );
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    expect(find.text('Access granted'), findsOneWidget);
    expect(find.text('Listener connected'), findsOneWidget);
  });
}
