enum RulePriority {
  low(0, 'Low'),
  normal(1, 'Normal'),
  high(2, 'High'),
  critical(3, 'Critical');

  const RulePriority(this.rank, this.label);

  final int rank;
  final String label;

  static RulePriority fromRank(int rank) {
    return RulePriority.values.firstWhere(
      (priority) => priority.rank == rank,
      orElse: () => RulePriority.normal,
    );
  }
}
