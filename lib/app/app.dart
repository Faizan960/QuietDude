import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class QuietdudeApp extends ConsumerWidget {
  const QuietdudeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Quietdude',
      debugShowCheckedModeBanner: false,
      theme: QuietdudeTheme.light(),
      darkTheme: QuietdudeTheme.dark(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
