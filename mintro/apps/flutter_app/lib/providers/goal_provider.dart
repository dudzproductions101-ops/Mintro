import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_providers.dart';
import 'profile_provider.dart';

final goalsProvider = FutureProvider((ref) {
  return ref.read(goalRepositoryProvider).getGoals();
});

class GoalContributionNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> contribute(String goalId, double amount) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final result = await ref.read(goalRepositoryProvider).contribute(goalId, amount);
      final rewards = result['rewardsGranted'] as Map<String, dynamic>;

      if ((rewards['xp'] as int) > 0 || (rewards['coins'] as int) > 0) {
        ref.invalidate(profileProvider);
      }

      ref.invalidate(goalsProvider);
    });
  }
}

final goalContributionProvider =
    AsyncNotifierProvider<GoalContributionNotifier, void>(GoalContributionNotifier.new);
