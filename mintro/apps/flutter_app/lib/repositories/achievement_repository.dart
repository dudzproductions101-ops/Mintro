import '../models/achievement.dart';
import '../services/supabase_service.dart';

class AchievementRepository {
  Future<List<Achievement>> getAllWithStatus() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    final achievements = await SupabaseService.client
        .from('achievements')
        .select()
        .order('sort_order');

    final earned = await SupabaseService.client
        .from('user_achievements')
        .select('achievement_id, earned_at')
        .eq('user_id', userId);

    final earnedMap = <String, DateTime>{
      for (final row in earned as List)
        row['achievement_id'] as String: DateTime.parse(row['earned_at'] as String),
    };

    return (achievements as List)
        .map((json) => Achievement.fromJson(
              json,
              earnedAt: earnedMap[json['id']],
            ))
        .toList();
  }
}
