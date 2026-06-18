import '../models/profile.dart';
import '../services/supabase_service.dart';

class ProfileRepository {
  Future<Profile> getMyProfile() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    final data = await SupabaseService.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return Profile.fromJson(data);
  }

  Future<DailyXpProgress> getTodayProgress() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    final today = DateTime.now().toIso8601String().substring(0, 10);

    final data = await SupabaseService.client
        .from('daily_xp_log')
        .select('xp_earned, goal_met')
        .eq('user_id', userId)
        .eq('log_date', today)
        .maybeSingle();

    return data != null
        ? DailyXpProgress.fromJson(data)
        : const DailyXpProgress(xpEarned: 0, goalMet: false);
  }

  /// Streak status for the current week (Mon-Sun), used to render the
  /// weekday dots on the Home screen.
  Future<Set<int>> getActiveDaysThisWeek() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final mondayStr = DateTime(monday.year, monday.month, monday.day)
        .toIso8601String()
        .substring(0, 10);

    final rows = await SupabaseService.client
        .from('daily_xp_log')
        .select('log_date')
        .eq('user_id', userId)
        .gte('log_date', mondayStr)
        .gt('xp_earned', 0);

    return (rows as List)
        .map((r) => DateTime.parse(r['log_date'] as String).weekday)
        .toSet();
  }

  Future<void> updateDailyXpGoal(int goal) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    await SupabaseService.client
        .from('profiles')
        .update({'daily_xp_goal': goal})
        .eq('id', userId);
  }
}
