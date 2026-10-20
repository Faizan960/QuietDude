import 'dart:async';

import 'package:quietdude/data/repositories/rule_repository.dart';
import 'package:quietdude/domain/models/privacy_rule.dart';

class FakeRuleRepository implements RuleRepository {
  FakeRuleRepository([Iterable<PrivacyRule> seed = const []])
    : _rules = List.of(seed);

  final List<PrivacyRule> _rules;
  final _controller = StreamController<List<PrivacyRule>>.broadcast();

  @override
  Stream<List<PrivacyRule>> watchRules() async* {
    yield List.unmodifiable(_rules);
    yield* _controller.stream;
  }

  @override
  Future<List<PrivacyRule>> getRules() async {
    return List.unmodifiable(_rules);
  }

  @override
  Future<PrivacyRule?> findById(String id) async {
    for (final rule in _rules) {
      if (rule.id == id) {
        return rule;
      }
    }
    return null;
  }

  @override
  Future<void> upsert(PrivacyRule rule) async {
    final index = _rules.indexWhere((existing) => existing.id == rule.id);
    if (index == -1) {
      _rules.add(rule);
    } else {
      _rules[index] = rule;
    }
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    _rules.removeWhere((rule) => rule.id == id);
    _emit();
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_rules));
    }
  }

  Future<void> dispose() => _controller.close();
}
