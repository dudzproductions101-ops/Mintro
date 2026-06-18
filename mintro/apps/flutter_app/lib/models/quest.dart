enum QuestPeriod { daily, weekly, monthly }

QuestPeriod _periodFromString(String value) {
  switch (value) {
    case 'weekly':
      return QuestPeriod.weekly;
    case 'monthly':
      return QuestPeriod.monthly;
    default:
      return QuestPeriod.daily;
  }
}

/// Maps to a `user_quests` row joined with its `quests` template.
class Quest {
  final String userQuestId;
  final String questId;
  final String title;
  final String description;
  final String? icon;
  final QuestPeriod period;
  final int currentValue;
  final int targetValue;
  final int xpReward;
  final int coinReward;
  final bool completed;
  final bool claimed;
  final DateTime periodEnd;
  final bool isFeatured;

  const Quest({
    required this.userQuestId,
    required this.questId,
    required this.title,
    required this.description,
    required this.icon,
    required this.period,
    required this.currentValue,
    required this.targetValue,
    required this.xpReward,
    required this.coinReward,
    required this.completed,
    required this.claimed,
    required this.periodEnd,
    required this.isFeatured,
  });

  factory Quest.fromJson(Map<String, dynamic> json) {
    final template = json['quests'] as Map<String, dynamic>? ?? {};

    return Quest(
      userQuestId: json['id'] as String,
      questId: json['quest_id'] as String,
      title: template['title'] as String? ?? '',
      description: template['description'] as String? ?? '',
      icon: template['icon'] as String?,
      period: _periodFromString(template['period'] as String? ?? 'daily'),
      currentValue: json['current_value'] as int? ?? 0,
      targetValue: template['target_value'] as int? ?? 1,
      xpReward: template['xp_reward'] as int? ?? 0,
      coinReward: template['coin_reward'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
      claimed: json['claimed'] as bool? ?? false,
      periodEnd: DateTime.tryParse(json['period_end'] as String? ?? '') ?? DateTime.now(),
      isFeatured: template['is_featured'] as bool? ?? false,
    );
  }

  double get progress => targetValue == 0 ? 0 : (currentValue / targetValue).clamp(0, 1);

  Duration get timeRemaining {
    final remaining = periodEnd.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }
}
