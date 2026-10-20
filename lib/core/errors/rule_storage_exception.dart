class RuleStorageException implements Exception {
  const RuleStorageException(this.operation, this.cause);

  final String operation;
  final Object cause;

  @override
  String toString() => 'RuleStorageException($operation): $cause';
}
