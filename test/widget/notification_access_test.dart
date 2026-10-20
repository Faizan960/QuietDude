import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quietdude/app/providers.dart';
import 'package:quietdude/domain/models/notification_listener.dart';
import 'package:quietdude/features/permissions/widgets/notification_access_card.dart';

import '../fixtures/fake_platform_adapter.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester,
    FakePlatformAdapter adapter,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [platformAdapterProvider.overrideWithValue(adapter)],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: NotificationAccessCard()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows granted access and a connected listener', (tester) async {
    final adapter = FakePlatformAdapter(
      listenerStatus: const NotificationListenerStatus(
        access: NotificationAccessStatus.granted,
        connection: NotificationConnectionStatus.connected,
      ),
    );

    await pumpCard(tester, adapter);

    expect(find.text('Access granted'), findsOneWidget);
    expect(find.text('Listener connected'), findsOneWidget);
    expect(find.text('Access not granted'), findsNothing);
  });

  testWidgets('shows denied access and does not grant it by opening settings', (
    tester,
  ) async {
    final adapter = FakePlatformAdapter(openListenerSettingsResult: true);

    await pumpCard(tester, adapter);

    expect(find.text('Access not granted'), findsOneWidget);
    expect(find.text('Observation unavailable'), findsOneWidget);

    await tester.tap(find.text('Open notification access settings'));
    await tester.pumpAndSettle();

    expect(adapter.openListenerSettingsRequests, 1);
    expect(find.text('Access not granted'), findsOneWidget);
    expect(find.text('Access granted'), findsNothing);
  });

  testWidgets('reports a failure when settings cannot be opened', (
    tester,
  ) async {
    final adapter = FakePlatformAdapter(openListenerSettingsResult: false);

    await pumpCard(tester, adapter);
    await tester.tap(find.text('Open notification access settings'));
    await tester.pumpAndSettle();

    expect(
      find.text('Android notification access settings could not be opened.'),
      findsOneWidget,
    );
  });

  testWidgets('explains unsupported platforms without a settings action', (
    tester,
  ) async {
    final adapter = FakePlatformAdapter(
      listenerStatus: const NotificationListenerStatus.unsupported(),
    );

    await pumpCard(tester, adapter);

    expect(find.text('Observation unavailable'), findsWidgets);
    expect(find.text('Open notification access settings'), findsNothing);
  });
}
