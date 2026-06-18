import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/learning_path.dart';
import 'repository_providers.dart';
import 'profile_provider.dart';

final learningPathsProvider = FutureProvider((ref) {
  return ref.read(learningRepositoryProvider).getPaths();
});

final lessonsForPathProvider = FutureProvider.family<List<Lesson>, String>((ref, pathId) {
  return ref.read(learningRepositoryProvider).getLessonsForPath(pathId);
});

final todaysLessonsProvider = FutureProvider((ref) {
  return ref.read(learningRepositoryProvider).getTodaysLessons();
});

/// Result of the most recent lesson completion call, used by the lesson
/// completion screen to drive XP/coin/streak/level-up/quest animations.
class LessonCompletionState {
  final bool passed;
  final int score;
  final int xpEarned;
  final int coinsEarned;
  final bool leveledUp;
  final bool streakExtended;
  final List<dynamic> questUpdates;

  const LessonCompletionState({
    required this.passed,
    required this.score,
    required this.xpEarned,
    required this.coinsEarned,
    required this.leveledUp,
    required this.streakExtended,
    required this.questUpdates,
  });

  factory LessonCompletionState.fromJson(Map<String, dynamic> json) {
    final xp = json['xp'] as Map<String, dynamic>;
    final streak = json['streak'] as Map<String, dynamic>;

    return LessonCompletionState(
      passed: json['passed'] as bool,
      score: json['score'] as int,
      xpEarned: json['xpEarned'] as int,
      coinsEarned: json['coinsEarned'] as int,
      leveledUp: xp['leveledUp'] as bool? ?? false,
      streakExtended: streak['extended'] as bool? ?? false,
      questUpdates: json['questUpdates'] as List<dynamic>? ?? [],
    );
  }
}

class LessonCompletionNotifier extends AsyncNotifier<LessonCompletionState?> {
  @override
  LessonCompletionState? build() => null;

  Future<void> submit({
    required String lessonId,
    required List<Map<String, dynamic>> answers,
    required int timeSpentSeconds,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final raw = await ref.read(learningRepositoryProvider).completeLesson(
            lessonId: lessonId,
            answers: answers,
            timeSpentSeconds: timeSpentSeconds,
          );

      final result = LessonCompletionState.fromJson(raw);

      if (result.passed) {
        final xp = raw['xp'] as Map<String, dynamic>;
        final coins = raw['coins'] as Map<String, dynamic>;
        final streak = raw['streak'] as Map<String, dynamic>;

        ref.read(profileProvider.notifier).applyDelta(
              newTotalXp: xp['newTotalXp'] as int?,
              newLevel: xp['newLevel'] as int?,
              newCoins: coins['newTotal'] as int?,
              newStreak: streak['currentStreak'] as int?,
            );

        ref.invalidate(dailyXpProgressProvider);
        ref.invalidate(activeDaysThisWeekProvider);
        ref.invalidate(todaysLessonsProvider);
        ref.invalidate(learningPathsProvider);
      }

      return result;
    });
  }
}

final lessonCompletionProvider =
    AsyncNotifierProvider<LessonCompletionNotifier, LessonCompletionState?>(
  LessonCompletionNotifier.new,
);
