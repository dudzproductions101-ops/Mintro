/// Maps to the `achievements` table, joined with `user_achievements` to
/// determine `earnedAt`.
class Achievement {
  final String id;
  final String slug;
  final String title;
  final String description;
  final String? icon;
  final String category;
  final int xpReward;
  final int coinReward;
  final DateTime? earnedAt;

  const Achievement({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.xpReward,
    required this.coinReward,
    required this.earnedAt,
  });

  bool get isEarned => earnedAt != null;

  factory Achievement.fromJson(Map<String, dynamic> json, {DateTime? earnedAt}) {
    return Achievement(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String?,
      category: json['category'] as String? ?? 'general',
      xpReward: json['xp_reward'] as int? ?? 0,
      coinReward: json['coin_reward'] as int? ?? 0,
      earnedAt: earnedAt,
    );
  }
}
