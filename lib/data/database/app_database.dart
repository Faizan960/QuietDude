import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DataClassName('PrivacyRuleRow')
class PrivacyRules extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get priorityRank => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('RuleConditionRow')
class RuleConditionRows extends Table {
  TextColumn get id => text()();
  TextColumn get ruleId =>
      text().references(PrivacyRules, #id, onDelete: KeyAction.cascade)();
  TextColumn get kind => text()();
  IntColumn get startMinute => integer().nullable()();
  IntColumn get endMinute => integer().nullable()();
  TextColumn get value => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('RuleActionRow')
class RuleActionRows extends Table {
  TextColumn get id => text()();
  TextColumn get ruleId =>
      text().references(PrivacyRules, #id, onDelete: KeyAction.cascade)();
  TextColumn get kind => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [PrivacyRules, RuleConditionRows, RuleActionRows])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.open() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationSupportDirectory();
    final file = File(p.join(directory.path, 'quietdude.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
