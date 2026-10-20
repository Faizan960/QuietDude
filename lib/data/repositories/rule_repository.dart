import '../../domain/models/privacy_rule.dart';

abstract interface class RuleRepository {
  Stream<List<PrivacyRule>> watchRules();

  Future<List<PrivacyRule>> getRules();

  Future<PrivacyRule?> findById(String id);

  Future<void> upsert(PrivacyRule rule);

  Future<void> delete(String id);
}
