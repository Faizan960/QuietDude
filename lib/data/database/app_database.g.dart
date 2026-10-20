// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PrivacyRulesTable extends PrivacyRules
    with TableInfo<$PrivacyRulesTable, PrivacyRuleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrivacyRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _priorityRankMeta = const VerificationMeta(
    'priorityRank',
  );
  @override
  late final GeneratedColumn<int> priorityRank = GeneratedColumn<int>(
    'priority_rank',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    enabled,
    priorityRank,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'privacy_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrivacyRuleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('priority_rank')) {
      context.handle(
        _priorityRankMeta,
        priorityRank.isAcceptableOrUnknown(
          data['priority_rank']!,
          _priorityRankMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_priorityRankMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PrivacyRuleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrivacyRuleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      priorityRank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority_rank'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PrivacyRulesTable createAlias(String alias) {
    return $PrivacyRulesTable(attachedDatabase, alias);
  }
}

class PrivacyRuleRow extends DataClass implements Insertable<PrivacyRuleRow> {
  final String id;
  final String name;
  final bool enabled;
  final int priorityRank;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PrivacyRuleRow({
    required this.id,
    required this.name,
    required this.enabled,
    required this.priorityRank,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['enabled'] = Variable<bool>(enabled);
    map['priority_rank'] = Variable<int>(priorityRank);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PrivacyRulesCompanion toCompanion(bool nullToAbsent) {
    return PrivacyRulesCompanion(
      id: Value(id),
      name: Value(name),
      enabled: Value(enabled),
      priorityRank: Value(priorityRank),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PrivacyRuleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrivacyRuleRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      priorityRank: serializer.fromJson<int>(json['priorityRank']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'enabled': serializer.toJson<bool>(enabled),
      'priorityRank': serializer.toJson<int>(priorityRank),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PrivacyRuleRow copyWith({
    String? id,
    String? name,
    bool? enabled,
    int? priorityRank,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PrivacyRuleRow(
    id: id ?? this.id,
    name: name ?? this.name,
    enabled: enabled ?? this.enabled,
    priorityRank: priorityRank ?? this.priorityRank,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PrivacyRuleRow copyWithCompanion(PrivacyRulesCompanion data) {
    return PrivacyRuleRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      priorityRank: data.priorityRank.present
          ? data.priorityRank.value
          : this.priorityRank,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrivacyRuleRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('enabled: $enabled, ')
          ..write('priorityRank: $priorityRank, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, enabled, priorityRank, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrivacyRuleRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.enabled == this.enabled &&
          other.priorityRank == this.priorityRank &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PrivacyRulesCompanion extends UpdateCompanion<PrivacyRuleRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<bool> enabled;
  final Value<int> priorityRank;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PrivacyRulesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.enabled = const Value.absent(),
    this.priorityRank = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrivacyRulesCompanion.insert({
    required String id,
    required String name,
    this.enabled = const Value.absent(),
    required int priorityRank,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       priorityRank = Value(priorityRank),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PrivacyRuleRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<bool>? enabled,
    Expression<int>? priorityRank,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (enabled != null) 'enabled': enabled,
      if (priorityRank != null) 'priority_rank': priorityRank,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrivacyRulesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<bool>? enabled,
    Value<int>? priorityRank,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PrivacyRulesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      priorityRank: priorityRank ?? this.priorityRank,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (priorityRank.present) {
      map['priority_rank'] = Variable<int>(priorityRank.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrivacyRulesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('enabled: $enabled, ')
          ..write('priorityRank: $priorityRank, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RuleConditionRowsTable extends RuleConditionRows
    with TableInfo<$RuleConditionRowsTable, RuleConditionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RuleConditionRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleIdMeta = const VerificationMeta('ruleId');
  @override
  late final GeneratedColumn<String> ruleId = GeneratedColumn<String>(
    'rule_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES privacy_rules (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMinuteMeta = const VerificationMeta(
    'startMinute',
  );
  @override
  late final GeneratedColumn<int> startMinute = GeneratedColumn<int>(
    'start_minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endMinuteMeta = const VerificationMeta(
    'endMinute',
  );
  @override
  late final GeneratedColumn<int> endMinute = GeneratedColumn<int>(
    'end_minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ruleId,
    kind,
    startMinute,
    endMinute,
    value,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rule_condition_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<RuleConditionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('rule_id')) {
      context.handle(
        _ruleIdMeta,
        ruleId.isAcceptableOrUnknown(data['rule_id']!, _ruleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ruleIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('start_minute')) {
      context.handle(
        _startMinuteMeta,
        startMinute.isAcceptableOrUnknown(
          data['start_minute']!,
          _startMinuteMeta,
        ),
      );
    }
    if (data.containsKey('end_minute')) {
      context.handle(
        _endMinuteMeta,
        endMinute.isAcceptableOrUnknown(data['end_minute']!, _endMinuteMeta),
      );
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RuleConditionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RuleConditionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ruleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      startMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_minute'],
      ),
      endMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_minute'],
      ),
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
    );
  }

  @override
  $RuleConditionRowsTable createAlias(String alias) {
    return $RuleConditionRowsTable(attachedDatabase, alias);
  }
}

class RuleConditionRow extends DataClass
    implements Insertable<RuleConditionRow> {
  final String id;
  final String ruleId;
  final String kind;
  final int? startMinute;
  final int? endMinute;
  final String? value;
  const RuleConditionRow({
    required this.id,
    required this.ruleId,
    required this.kind,
    this.startMinute,
    this.endMinute,
    this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['rule_id'] = Variable<String>(ruleId);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || startMinute != null) {
      map['start_minute'] = Variable<int>(startMinute);
    }
    if (!nullToAbsent || endMinute != null) {
      map['end_minute'] = Variable<int>(endMinute);
    }
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  RuleConditionRowsCompanion toCompanion(bool nullToAbsent) {
    return RuleConditionRowsCompanion(
      id: Value(id),
      ruleId: Value(ruleId),
      kind: Value(kind),
      startMinute: startMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(startMinute),
      endMinute: endMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(endMinute),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
    );
  }

  factory RuleConditionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RuleConditionRow(
      id: serializer.fromJson<String>(json['id']),
      ruleId: serializer.fromJson<String>(json['ruleId']),
      kind: serializer.fromJson<String>(json['kind']),
      startMinute: serializer.fromJson<int?>(json['startMinute']),
      endMinute: serializer.fromJson<int?>(json['endMinute']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ruleId': serializer.toJson<String>(ruleId),
      'kind': serializer.toJson<String>(kind),
      'startMinute': serializer.toJson<int?>(startMinute),
      'endMinute': serializer.toJson<int?>(endMinute),
      'value': serializer.toJson<String?>(value),
    };
  }

  RuleConditionRow copyWith({
    String? id,
    String? ruleId,
    String? kind,
    Value<int?> startMinute = const Value.absent(),
    Value<int?> endMinute = const Value.absent(),
    Value<String?> value = const Value.absent(),
  }) => RuleConditionRow(
    id: id ?? this.id,
    ruleId: ruleId ?? this.ruleId,
    kind: kind ?? this.kind,
    startMinute: startMinute.present ? startMinute.value : this.startMinute,
    endMinute: endMinute.present ? endMinute.value : this.endMinute,
    value: value.present ? value.value : this.value,
  );
  RuleConditionRow copyWithCompanion(RuleConditionRowsCompanion data) {
    return RuleConditionRow(
      id: data.id.present ? data.id.value : this.id,
      ruleId: data.ruleId.present ? data.ruleId.value : this.ruleId,
      kind: data.kind.present ? data.kind.value : this.kind,
      startMinute: data.startMinute.present
          ? data.startMinute.value
          : this.startMinute,
      endMinute: data.endMinute.present ? data.endMinute.value : this.endMinute,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RuleConditionRow(')
          ..write('id: $id, ')
          ..write('ruleId: $ruleId, ')
          ..write('kind: $kind, ')
          ..write('startMinute: $startMinute, ')
          ..write('endMinute: $endMinute, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, ruleId, kind, startMinute, endMinute, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RuleConditionRow &&
          other.id == this.id &&
          other.ruleId == this.ruleId &&
          other.kind == this.kind &&
          other.startMinute == this.startMinute &&
          other.endMinute == this.endMinute &&
          other.value == this.value);
}

class RuleConditionRowsCompanion extends UpdateCompanion<RuleConditionRow> {
  final Value<String> id;
  final Value<String> ruleId;
  final Value<String> kind;
  final Value<int?> startMinute;
  final Value<int?> endMinute;
  final Value<String?> value;
  final Value<int> rowid;
  const RuleConditionRowsCompanion({
    this.id = const Value.absent(),
    this.ruleId = const Value.absent(),
    this.kind = const Value.absent(),
    this.startMinute = const Value.absent(),
    this.endMinute = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RuleConditionRowsCompanion.insert({
    required String id,
    required String ruleId,
    required String kind,
    this.startMinute = const Value.absent(),
    this.endMinute = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ruleId = Value(ruleId),
       kind = Value(kind);
  static Insertable<RuleConditionRow> custom({
    Expression<String>? id,
    Expression<String>? ruleId,
    Expression<String>? kind,
    Expression<int>? startMinute,
    Expression<int>? endMinute,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ruleId != null) 'rule_id': ruleId,
      if (kind != null) 'kind': kind,
      if (startMinute != null) 'start_minute': startMinute,
      if (endMinute != null) 'end_minute': endMinute,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RuleConditionRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? ruleId,
    Value<String>? kind,
    Value<int?>? startMinute,
    Value<int?>? endMinute,
    Value<String?>? value,
    Value<int>? rowid,
  }) {
    return RuleConditionRowsCompanion(
      id: id ?? this.id,
      ruleId: ruleId ?? this.ruleId,
      kind: kind ?? this.kind,
      startMinute: startMinute ?? this.startMinute,
      endMinute: endMinute ?? this.endMinute,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ruleId.present) {
      map['rule_id'] = Variable<String>(ruleId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (startMinute.present) {
      map['start_minute'] = Variable<int>(startMinute.value);
    }
    if (endMinute.present) {
      map['end_minute'] = Variable<int>(endMinute.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RuleConditionRowsCompanion(')
          ..write('id: $id, ')
          ..write('ruleId: $ruleId, ')
          ..write('kind: $kind, ')
          ..write('startMinute: $startMinute, ')
          ..write('endMinute: $endMinute, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RuleActionRowsTable extends RuleActionRows
    with TableInfo<$RuleActionRowsTable, RuleActionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RuleActionRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleIdMeta = const VerificationMeta('ruleId');
  @override
  late final GeneratedColumn<String> ruleId = GeneratedColumn<String>(
    'rule_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES privacy_rules (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, ruleId, kind];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rule_action_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<RuleActionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('rule_id')) {
      context.handle(
        _ruleIdMeta,
        ruleId.isAcceptableOrUnknown(data['rule_id']!, _ruleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ruleIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RuleActionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RuleActionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ruleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
    );
  }

  @override
  $RuleActionRowsTable createAlias(String alias) {
    return $RuleActionRowsTable(attachedDatabase, alias);
  }
}

class RuleActionRow extends DataClass implements Insertable<RuleActionRow> {
  final String id;
  final String ruleId;
  final String kind;
  const RuleActionRow({
    required this.id,
    required this.ruleId,
    required this.kind,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['rule_id'] = Variable<String>(ruleId);
    map['kind'] = Variable<String>(kind);
    return map;
  }

  RuleActionRowsCompanion toCompanion(bool nullToAbsent) {
    return RuleActionRowsCompanion(
      id: Value(id),
      ruleId: Value(ruleId),
      kind: Value(kind),
    );
  }

  factory RuleActionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RuleActionRow(
      id: serializer.fromJson<String>(json['id']),
      ruleId: serializer.fromJson<String>(json['ruleId']),
      kind: serializer.fromJson<String>(json['kind']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ruleId': serializer.toJson<String>(ruleId),
      'kind': serializer.toJson<String>(kind),
    };
  }

  RuleActionRow copyWith({String? id, String? ruleId, String? kind}) =>
      RuleActionRow(
        id: id ?? this.id,
        ruleId: ruleId ?? this.ruleId,
        kind: kind ?? this.kind,
      );
  RuleActionRow copyWithCompanion(RuleActionRowsCompanion data) {
    return RuleActionRow(
      id: data.id.present ? data.id.value : this.id,
      ruleId: data.ruleId.present ? data.ruleId.value : this.ruleId,
      kind: data.kind.present ? data.kind.value : this.kind,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RuleActionRow(')
          ..write('id: $id, ')
          ..write('ruleId: $ruleId, ')
          ..write('kind: $kind')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ruleId, kind);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RuleActionRow &&
          other.id == this.id &&
          other.ruleId == this.ruleId &&
          other.kind == this.kind);
}

class RuleActionRowsCompanion extends UpdateCompanion<RuleActionRow> {
  final Value<String> id;
  final Value<String> ruleId;
  final Value<String> kind;
  final Value<int> rowid;
  const RuleActionRowsCompanion({
    this.id = const Value.absent(),
    this.ruleId = const Value.absent(),
    this.kind = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RuleActionRowsCompanion.insert({
    required String id,
    required String ruleId,
    required String kind,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ruleId = Value(ruleId),
       kind = Value(kind);
  static Insertable<RuleActionRow> custom({
    Expression<String>? id,
    Expression<String>? ruleId,
    Expression<String>? kind,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ruleId != null) 'rule_id': ruleId,
      if (kind != null) 'kind': kind,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RuleActionRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? ruleId,
    Value<String>? kind,
    Value<int>? rowid,
  }) {
    return RuleActionRowsCompanion(
      id: id ?? this.id,
      ruleId: ruleId ?? this.ruleId,
      kind: kind ?? this.kind,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ruleId.present) {
      map['rule_id'] = Variable<String>(ruleId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RuleActionRowsCompanion(')
          ..write('id: $id, ')
          ..write('ruleId: $ruleId, ')
          ..write('kind: $kind, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PrivacyRulesTable privacyRules = $PrivacyRulesTable(this);
  late final $RuleConditionRowsTable ruleConditionRows =
      $RuleConditionRowsTable(this);
  late final $RuleActionRowsTable ruleActionRows = $RuleActionRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    privacyRules,
    ruleConditionRows,
    ruleActionRows,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'privacy_rules',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('rule_condition_rows', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'privacy_rules',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('rule_action_rows', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$PrivacyRulesTableCreateCompanionBuilder =
    PrivacyRulesCompanion Function({
      required String id,
      required String name,
      Value<bool> enabled,
      required int priorityRank,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PrivacyRulesTableUpdateCompanionBuilder =
    PrivacyRulesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<bool> enabled,
      Value<int> priorityRank,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$PrivacyRulesTableReferences
    extends BaseReferences<_$AppDatabase, $PrivacyRulesTable, PrivacyRuleRow> {
  $$PrivacyRulesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RuleConditionRowsTable, List<RuleConditionRow>>
  _ruleConditionRowsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.ruleConditionRows,
        aliasName: $_aliasNameGenerator(
          db.privacyRules.id,
          db.ruleConditionRows.ruleId,
        ),
      );

  $$RuleConditionRowsTableProcessedTableManager get ruleConditionRowsRefs {
    final manager = $$RuleConditionRowsTableTableManager(
      $_db,
      $_db.ruleConditionRows,
    ).filter((f) => f.ruleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _ruleConditionRowsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RuleActionRowsTable, List<RuleActionRow>>
  _ruleActionRowsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ruleActionRows,
    aliasName: $_aliasNameGenerator(
      db.privacyRules.id,
      db.ruleActionRows.ruleId,
    ),
  );

  $$RuleActionRowsTableProcessedTableManager get ruleActionRowsRefs {
    final manager = $$RuleActionRowsTableTableManager(
      $_db,
      $_db.ruleActionRows,
    ).filter((f) => f.ruleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ruleActionRowsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PrivacyRulesTableFilterComposer
    extends Composer<_$AppDatabase, $PrivacyRulesTable> {
  $$PrivacyRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priorityRank => $composableBuilder(
    column: $table.priorityRank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> ruleConditionRowsRefs(
    Expression<bool> Function($$RuleConditionRowsTableFilterComposer f) f,
  ) {
    final $$RuleConditionRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ruleConditionRows,
      getReferencedColumn: (t) => t.ruleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RuleConditionRowsTableFilterComposer(
            $db: $db,
            $table: $db.ruleConditionRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ruleActionRowsRefs(
    Expression<bool> Function($$RuleActionRowsTableFilterComposer f) f,
  ) {
    final $$RuleActionRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ruleActionRows,
      getReferencedColumn: (t) => t.ruleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RuleActionRowsTableFilterComposer(
            $db: $db,
            $table: $db.ruleActionRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PrivacyRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $PrivacyRulesTable> {
  $$PrivacyRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priorityRank => $composableBuilder(
    column: $table.priorityRank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrivacyRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrivacyRulesTable> {
  $$PrivacyRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get priorityRank => $composableBuilder(
    column: $table.priorityRank,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> ruleConditionRowsRefs<T extends Object>(
    Expression<T> Function($$RuleConditionRowsTableAnnotationComposer a) f,
  ) {
    final $$RuleConditionRowsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.ruleConditionRows,
          getReferencedColumn: (t) => t.ruleId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RuleConditionRowsTableAnnotationComposer(
                $db: $db,
                $table: $db.ruleConditionRows,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> ruleActionRowsRefs<T extends Object>(
    Expression<T> Function($$RuleActionRowsTableAnnotationComposer a) f,
  ) {
    final $$RuleActionRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ruleActionRows,
      getReferencedColumn: (t) => t.ruleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RuleActionRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.ruleActionRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PrivacyRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrivacyRulesTable,
          PrivacyRuleRow,
          $$PrivacyRulesTableFilterComposer,
          $$PrivacyRulesTableOrderingComposer,
          $$PrivacyRulesTableAnnotationComposer,
          $$PrivacyRulesTableCreateCompanionBuilder,
          $$PrivacyRulesTableUpdateCompanionBuilder,
          (PrivacyRuleRow, $$PrivacyRulesTableReferences),
          PrivacyRuleRow,
          PrefetchHooks Function({
            bool ruleConditionRowsRefs,
            bool ruleActionRowsRefs,
          })
        > {
  $$PrivacyRulesTableTableManager(_$AppDatabase db, $PrivacyRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrivacyRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrivacyRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrivacyRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> priorityRank = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrivacyRulesCompanion(
                id: id,
                name: name,
                enabled: enabled,
                priorityRank: priorityRank,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<bool> enabled = const Value.absent(),
                required int priorityRank,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PrivacyRulesCompanion.insert(
                id: id,
                name: name,
                enabled: enabled,
                priorityRank: priorityRank,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PrivacyRulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({ruleConditionRowsRefs = false, ruleActionRowsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ruleConditionRowsRefs) db.ruleConditionRows,
                    if (ruleActionRowsRefs) db.ruleActionRows,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (ruleConditionRowsRefs)
                        await $_getPrefetchedData<
                          PrivacyRuleRow,
                          $PrivacyRulesTable,
                          RuleConditionRow
                        >(
                          currentTable: table,
                          referencedTable: $$PrivacyRulesTableReferences
                              ._ruleConditionRowsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PrivacyRulesTableReferences(
                                db,
                                table,
                                p0,
                              ).ruleConditionRowsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ruleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (ruleActionRowsRefs)
                        await $_getPrefetchedData<
                          PrivacyRuleRow,
                          $PrivacyRulesTable,
                          RuleActionRow
                        >(
                          currentTable: table,
                          referencedTable: $$PrivacyRulesTableReferences
                              ._ruleActionRowsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PrivacyRulesTableReferences(
                                db,
                                table,
                                p0,
                              ).ruleActionRowsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ruleId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PrivacyRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrivacyRulesTable,
      PrivacyRuleRow,
      $$PrivacyRulesTableFilterComposer,
      $$PrivacyRulesTableOrderingComposer,
      $$PrivacyRulesTableAnnotationComposer,
      $$PrivacyRulesTableCreateCompanionBuilder,
      $$PrivacyRulesTableUpdateCompanionBuilder,
      (PrivacyRuleRow, $$PrivacyRulesTableReferences),
      PrivacyRuleRow,
      PrefetchHooks Function({
        bool ruleConditionRowsRefs,
        bool ruleActionRowsRefs,
      })
    >;
typedef $$RuleConditionRowsTableCreateCompanionBuilder =
    RuleConditionRowsCompanion Function({
      required String id,
      required String ruleId,
      required String kind,
      Value<int?> startMinute,
      Value<int?> endMinute,
      Value<String?> value,
      Value<int> rowid,
    });
typedef $$RuleConditionRowsTableUpdateCompanionBuilder =
    RuleConditionRowsCompanion Function({
      Value<String> id,
      Value<String> ruleId,
      Value<String> kind,
      Value<int?> startMinute,
      Value<int?> endMinute,
      Value<String?> value,
      Value<int> rowid,
    });

final class $$RuleConditionRowsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RuleConditionRowsTable,
          RuleConditionRow
        > {
  $$RuleConditionRowsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PrivacyRulesTable _ruleIdTable(_$AppDatabase db) =>
      db.privacyRules.createAlias(
        $_aliasNameGenerator(db.ruleConditionRows.ruleId, db.privacyRules.id),
      );

  $$PrivacyRulesTableProcessedTableManager get ruleId {
    final $_column = $_itemColumn<String>('rule_id')!;

    final manager = $$PrivacyRulesTableTableManager(
      $_db,
      $_db.privacyRules,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ruleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RuleConditionRowsTableFilterComposer
    extends Composer<_$AppDatabase, $RuleConditionRowsTable> {
  $$RuleConditionRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMinute => $composableBuilder(
    column: $table.endMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  $$PrivacyRulesTableFilterComposer get ruleId {
    final $$PrivacyRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ruleId,
      referencedTable: $db.privacyRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrivacyRulesTableFilterComposer(
            $db: $db,
            $table: $db.privacyRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RuleConditionRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $RuleConditionRowsTable> {
  $$RuleConditionRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMinute => $composableBuilder(
    column: $table.endMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  $$PrivacyRulesTableOrderingComposer get ruleId {
    final $$PrivacyRulesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ruleId,
      referencedTable: $db.privacyRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrivacyRulesTableOrderingComposer(
            $db: $db,
            $table: $db.privacyRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RuleConditionRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RuleConditionRowsTable> {
  $$RuleConditionRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endMinute =>
      $composableBuilder(column: $table.endMinute, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  $$PrivacyRulesTableAnnotationComposer get ruleId {
    final $$PrivacyRulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ruleId,
      referencedTable: $db.privacyRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrivacyRulesTableAnnotationComposer(
            $db: $db,
            $table: $db.privacyRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RuleConditionRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RuleConditionRowsTable,
          RuleConditionRow,
          $$RuleConditionRowsTableFilterComposer,
          $$RuleConditionRowsTableOrderingComposer,
          $$RuleConditionRowsTableAnnotationComposer,
          $$RuleConditionRowsTableCreateCompanionBuilder,
          $$RuleConditionRowsTableUpdateCompanionBuilder,
          (RuleConditionRow, $$RuleConditionRowsTableReferences),
          RuleConditionRow,
          PrefetchHooks Function({bool ruleId})
        > {
  $$RuleConditionRowsTableTableManager(
    _$AppDatabase db,
    $RuleConditionRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RuleConditionRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RuleConditionRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RuleConditionRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ruleId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int?> startMinute = const Value.absent(),
                Value<int?> endMinute = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RuleConditionRowsCompanion(
                id: id,
                ruleId: ruleId,
                kind: kind,
                startMinute: startMinute,
                endMinute: endMinute,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ruleId,
                required String kind,
                Value<int?> startMinute = const Value.absent(),
                Value<int?> endMinute = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RuleConditionRowsCompanion.insert(
                id: id,
                ruleId: ruleId,
                kind: kind,
                startMinute: startMinute,
                endMinute: endMinute,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RuleConditionRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ruleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (ruleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.ruleId,
                                referencedTable:
                                    $$RuleConditionRowsTableReferences
                                        ._ruleIdTable(db),
                                referencedColumn:
                                    $$RuleConditionRowsTableReferences
                                        ._ruleIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RuleConditionRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RuleConditionRowsTable,
      RuleConditionRow,
      $$RuleConditionRowsTableFilterComposer,
      $$RuleConditionRowsTableOrderingComposer,
      $$RuleConditionRowsTableAnnotationComposer,
      $$RuleConditionRowsTableCreateCompanionBuilder,
      $$RuleConditionRowsTableUpdateCompanionBuilder,
      (RuleConditionRow, $$RuleConditionRowsTableReferences),
      RuleConditionRow,
      PrefetchHooks Function({bool ruleId})
    >;
typedef $$RuleActionRowsTableCreateCompanionBuilder =
    RuleActionRowsCompanion Function({
      required String id,
      required String ruleId,
      required String kind,
      Value<int> rowid,
    });
typedef $$RuleActionRowsTableUpdateCompanionBuilder =
    RuleActionRowsCompanion Function({
      Value<String> id,
      Value<String> ruleId,
      Value<String> kind,
      Value<int> rowid,
    });

final class $$RuleActionRowsTableReferences
    extends BaseReferences<_$AppDatabase, $RuleActionRowsTable, RuleActionRow> {
  $$RuleActionRowsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PrivacyRulesTable _ruleIdTable(_$AppDatabase db) =>
      db.privacyRules.createAlias(
        $_aliasNameGenerator(db.ruleActionRows.ruleId, db.privacyRules.id),
      );

  $$PrivacyRulesTableProcessedTableManager get ruleId {
    final $_column = $_itemColumn<String>('rule_id')!;

    final manager = $$PrivacyRulesTableTableManager(
      $_db,
      $_db.privacyRules,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ruleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RuleActionRowsTableFilterComposer
    extends Composer<_$AppDatabase, $RuleActionRowsTable> {
  $$RuleActionRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  $$PrivacyRulesTableFilterComposer get ruleId {
    final $$PrivacyRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ruleId,
      referencedTable: $db.privacyRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrivacyRulesTableFilterComposer(
            $db: $db,
            $table: $db.privacyRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RuleActionRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $RuleActionRowsTable> {
  $$RuleActionRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  $$PrivacyRulesTableOrderingComposer get ruleId {
    final $$PrivacyRulesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ruleId,
      referencedTable: $db.privacyRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrivacyRulesTableOrderingComposer(
            $db: $db,
            $table: $db.privacyRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RuleActionRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RuleActionRowsTable> {
  $$RuleActionRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  $$PrivacyRulesTableAnnotationComposer get ruleId {
    final $$PrivacyRulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ruleId,
      referencedTable: $db.privacyRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrivacyRulesTableAnnotationComposer(
            $db: $db,
            $table: $db.privacyRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RuleActionRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RuleActionRowsTable,
          RuleActionRow,
          $$RuleActionRowsTableFilterComposer,
          $$RuleActionRowsTableOrderingComposer,
          $$RuleActionRowsTableAnnotationComposer,
          $$RuleActionRowsTableCreateCompanionBuilder,
          $$RuleActionRowsTableUpdateCompanionBuilder,
          (RuleActionRow, $$RuleActionRowsTableReferences),
          RuleActionRow,
          PrefetchHooks Function({bool ruleId})
        > {
  $$RuleActionRowsTableTableManager(
    _$AppDatabase db,
    $RuleActionRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RuleActionRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RuleActionRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RuleActionRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ruleId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RuleActionRowsCompanion(
                id: id,
                ruleId: ruleId,
                kind: kind,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ruleId,
                required String kind,
                Value<int> rowid = const Value.absent(),
              }) => RuleActionRowsCompanion.insert(
                id: id,
                ruleId: ruleId,
                kind: kind,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RuleActionRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ruleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (ruleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.ruleId,
                                referencedTable: $$RuleActionRowsTableReferences
                                    ._ruleIdTable(db),
                                referencedColumn:
                                    $$RuleActionRowsTableReferences
                                        ._ruleIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RuleActionRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RuleActionRowsTable,
      RuleActionRow,
      $$RuleActionRowsTableFilterComposer,
      $$RuleActionRowsTableOrderingComposer,
      $$RuleActionRowsTableAnnotationComposer,
      $$RuleActionRowsTableCreateCompanionBuilder,
      $$RuleActionRowsTableUpdateCompanionBuilder,
      (RuleActionRow, $$RuleActionRowsTableReferences),
      RuleActionRow,
      PrefetchHooks Function({bool ruleId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PrivacyRulesTableTableManager get privacyRules =>
      $$PrivacyRulesTableTableManager(_db, _db.privacyRules);
  $$RuleConditionRowsTableTableManager get ruleConditionRows =>
      $$RuleConditionRowsTableTableManager(_db, _db.ruleConditionRows);
  $$RuleActionRowsTableTableManager get ruleActionRows =>
      $$RuleActionRowsTableTableManager(_db, _db.ruleActionRows);
}
