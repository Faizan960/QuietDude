import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/notification_listener.dart';
import 'providers.dart';
import 'router.dart';
import 'theme.dart';

class QuietdudeApp extends ConsumerStatefulWidget {
  const QuietdudeApp({super.key});

  @override
  ConsumerState<QuietdudeApp> createState() => _QuietdudeAppState();
}

class _QuietdudeAppState extends ConsumerState<QuietdudeApp>
    with WidgetsBindingObserver {
  Timer? _statusReconcileTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _statusReconcileTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshListenerState();
    }
  }

  void _refreshListenerState() {
    ref.invalidate(notificationListenerStatusProvider);
    ref.invalidate(platformCapabilitiesProvider);
  }

  void _reconcileAfterConnectionChange() {
    _refreshListenerState();
    _statusReconcileTimer?.cancel();
    _statusReconcileTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _refreshListenerState();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<NotificationConnectionStatus>>(
      notificationConnectionStatusProvider,
      (previous, next) {
        if (next.hasValue && previous?.asData?.value != next.asData?.value) {
          _reconcileAfterConnectionChange();
        }
      },
    );

    return MaterialApp.router(
      title: 'Quietdude',
      debugShowCheckedModeBanner: false,
      theme: QuietdudeTheme.light(),
      darkTheme: QuietdudeTheme.dark(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
