import 'dart:ffi';
import 'dart:io';

import 'package:sqlite3/open.dart';

/// The Dart VM on Windows does not bundle sqlite3. Windows ships
/// winsqlite3.dll, which is sufficient for Drift's basic SQL operations.
void configureSqliteForTests() {
  if (Platform.isWindows) {
    open.overrideFor(
      OperatingSystem.windows,
      () => DynamicLibrary.open('winsqlite3.dll'),
    );
  }
}
