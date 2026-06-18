import '../models/learning_path.dart';
import '../services/api_client.dart';
import '../services/supabase_service.dart';

class LearningRepository {
  Future<List<LearningPath>> getPaths() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    final paths = await SupabaseService.client
        .from('learning_paths')
        .select()
        .order('sort_order');

    final lessons = await SupabaseService.client
        .from('lessons')
        .select('id, path_id');

    final completed = await SupabaseService.client
        .from('user_lessons')
        .select('lesson_id')
        .eq('user_id', userId)
        .not('completed_at', 'is', null);

    final completedLessonIds = (completed as List).map((r) => r['lesson_id'] as String).toSet();

    final totalsByPath = <String, int>{};
    final completedByPath = <String, int>{};

    for (final lesson in lessons as List) {
      final pathId = lesson['path_id'] as String;
      totalsByPath[pathId] = (totalsByPath[pathId] ?? 0) + 1;
      if (completedLessonIds.contains(lesson['id'])) {
        completedByPath[pathId] = (completedByPath[pathId] ?? 0) + 1;
      }
    }

    return (paths as List)
        .map((json) => LearningPath.fromJson(
              json,
              totalLessons: totalsByPath[json['id']] ?? 0,
              completedLessons: completedByPath[json['id']] ?? 0,
            ))
        .toList();
  }

  Future<List<Lesson>> getLessonsForPath(String pathId) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    final lessons = await SupabaseService.client
        .from('lessons')
        .select()
        .eq('path_id', pathId)
        .order('sort_order');

    final completed = await SupabaseService.client
        .from('user_lessons')
        .select('lesson_id')
        .eq('user_id', userId)
        .not('completed_at', 'is', null);

    final completedIds = (completed as List).map((r) => r['lesson_id'] as String).toSet();

    return (lessons as List)
        .map((json) => Lesson.fromJson(json, isCompleted: completedIds.contains(json['id'])))
        .toList();
  }

  Future<List<Lesson>> getTodaysLessons({int limit = 5}) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) throw Exception('Not authenticated');

    final completed = await SupabaseService.client
        .from('user_lessons')
        .select('lesson_id')
        .eq('user_id', userId)
        .not('completed_at', 'is', null);

    final completedIds = (completed as List).map((r) => r['lesson_id'] as String).toSet();

    final lessons = await SupabaseService.client
        .from('lessons')
        .select()
        .order('sort_order')
        .limit(limit + completedIds.length);

    return (lessons as List)
        .map((json) => Lesson.fromJson(json, isCompleted: completedIds.contains(json['id'])))
        .where((l) => true)
        .take(limit)
        .toList();
  }

  /// Submits quiz answers to the Node API, which scores them server-side
  /// and atomically awards XP/coins, updates the streak, and progresses
  /// quests. Returns the raw response payload for the UI to animate.
  Future<Map<String, dynamic>> completeLesson({
    required String lessonId,
    required List<Map<String, dynamic>> answers,
    required int timeSpentSeconds,
  }) async {
    final data = await ApiClient.instance.post('/lessons/$lessonId/complete', {
      'answers': answers,
      'timeSpentSeconds': timeSpentSeconds,
    });
    return data as Map<String, dynamic>;
  }
}
