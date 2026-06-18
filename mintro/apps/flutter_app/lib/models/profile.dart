/// Maps to the `profiles` table.
class Profile {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String currency;
  final int totalXp;
  final int level;
  final int coins;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;
  final int streakFreezeCount;
  final String league;
  final int dailyXpGoal;

  const Profile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.currency,
    required this.totalXp,
    required this.level,
    required this.coins,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActiveDate,
    required this.streakFreezeCount,
    required this.league,
    required this.dailyXpGoal,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      currency: json['currency'] as String? ?? 'EUR',
      totalXp: json['total_xp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      coins: json['coins'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastActiveDate: json['last_active_date'] != null
          ? DateTime.tryParse(json['last_active_date'] as String)
          : null,
      streakFreezeCount: json['streak_freeze_count'] as int? ?? 0,
      league: json['league'] as String? ?? 'copper',
      dailyXpGoal: json['daily_xp_goal'] as int? ?? 50,
    );
  }

  /// XP required to reach [level] + 1, derived from the same formula used
  /// server-side: level = floor(sqrt(xp / 50)) + 1  =>  xp = 50 * (level)^2
  int get xpForCurrentLevel => 50 * (level - 1) * (level - 1);
  int get xpForNextLevel => 50 * level * level;

  int get xpIntoCurrentLevel => totalXp - xpForCurrentLevel;
  int get xpNeededForLevel => xpForNextLevel - xpForCurrentLevel;

  double get levelProgress =>
      xpNeededForLevel == 0 ? 1 : (xpIntoCurrentLevel / xpNeededForLevel).clamp(0, 1);

  Profile copyWith({
    int? totalXp,
    int? level,
    int? coins,
    int? currentStreak,
    int? longestStreak,
  }) {
    return Profile(
      id: id,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      currency: currency,
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      coins: coins ?? this.coins,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate,
      streakFreezeCount: streakFreezeCount,
      league: league,
      dailyXpGoal: dailyXpGoal,
    );
  }
}

/// Maps to a row in `daily_xp_log` for today.
class DailyXpProgress {
  final int xpEarned;
  final bool goalMet;

  const DailyXpProgress({required this.xpEarned, required this.goalMet});

  factory DailyXpProgress.fromJson(Map<String, dynamic> json) {
    return DailyXpProgress(
      xpEarned: json['xp_earned'] as int? ?? 0,
      goalMet: json['goal_met'] as bool? ?? false,
    );
  }
}
