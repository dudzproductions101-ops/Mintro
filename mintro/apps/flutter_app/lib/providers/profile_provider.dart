import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import 'repository_providers.dart';

class ProfileNotifier extends AsyncNotifier<Profile> {
  @override
  Future<Profile> build() async {
    return ref.read(profileRepositoryProvider).getMyProfile();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(profileRepositoryProvider).getMyProfile());
  }

  /// Applies a local optimistic update immediately after a server call
  /// returns new totals (avoids a full refetch round-trip for snappy XP/coin
  /// count-up animations), then the next natural refresh reconciles fully.
  void applyDelta({int? newTotalXp, int? newLevel, int? newCoins, int? newStreak}) {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(current.copyWith(
      totalXp: newTotalXp,
      level: newLevel,
      coins: newCoins,
      currentStreak: newStreak,
    ));
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, Profile>(ProfileNotifier.new);

/// Today's XP-goal progress, shown on the Home dashboard progress bar.
final dailyXpProgressProvider = FutureProvider((ref) {
  return ref.read(profileRepositoryProvider).getTodayProgress();
});

/// Which weekdays (1=Mon..7=Sun) have activity this week, for the streak dots.
final activeDaysThisWeekProvider = FutureProvider((ref) {
  return ref.read(profileRepositoryProvider).getActiveDaysThisWeek();
});
