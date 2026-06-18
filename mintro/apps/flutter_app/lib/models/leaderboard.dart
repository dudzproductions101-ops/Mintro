class LeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final int weeklyXp;
  final int currentStreak;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.weeklyXp,
    required this.currentStreak,
    required this.isCurrentUser,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int,
      userId: json['user_id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      weeklyXp: json['weekly_xp'] as int,
      currentStreak: json['current_streak'] as int? ?? 0,
      isCurrentUser: json['is_current_user'] as bool? ?? false,
    );
  }

  /// Initials used for the placeholder avatar badge (e.g. "Sofia Chen" -> "SC").
  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

class LeaderboardResult {
  final String league;
  final DateTime weekStart;
  final List<LeaderboardEntry> entries;
  final int? currentUserRank;
  final int totalInLeague;

  const LeaderboardResult({
    required this.league,
    required this.weekStart,
    required this.entries,
    required this.currentUserRank,
    required this.totalInLeague,
  });

  factory LeaderboardResult.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'] as List<dynamic>? ?? [];
    return LeaderboardResult(
      league: json['league'] as String,
      weekStart: DateTime.tryParse(json['weekStart'] as String? ?? '') ?? DateTime.now(),
      entries: rawEntries
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentUserRank: json['currentUserRank'] as int?,
      totalInLeague: json['totalInLeague'] as int? ?? 0,
    );
  }

  List<LeaderboardEntry> get podium => entries.take(3).toList();
}
