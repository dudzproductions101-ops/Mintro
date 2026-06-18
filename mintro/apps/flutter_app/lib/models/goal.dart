enum GoalStatus { active, completed, archived }

GoalStatus _statusFromString(String value) {
  switch (value) {
    case 'completed':
      return GoalStatus.completed;
    case 'archived':
      return GoalStatus.archived;
    default:
      return GoalStatus.active;
  }
}

/// Maps to the `goals` table.
class Goal {
  final String id;
  final String name;
  final String? icon;
  final double targetAmount;
  final double currentAmount;
  final String currency;
  final DateTime? deadline;
  final GoalStatus status;

  const Goal({
    required this.id,
    required this.name,
    required this.icon,
    required this.targetAmount,
    required this.currentAmount,
    required this.currency,
    required this.deadline,
    required this.status,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'EUR',
      deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline'] as String) : null,
      status: _statusFromString(json['status'] as String? ?? 'active'),
    );
  }

  double get progress => targetAmount == 0 ? 0 : (currentAmount / targetAmount).clamp(0, 1);
  double get remaining => (targetAmount - currentAmount).clamp(0, targetAmount);
  int get progressPercent => (progress * 100).round();
}
