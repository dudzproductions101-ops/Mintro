import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quest.dart';
import 'repository_providers.dart';
import 'profile_provider.dart';

final activeQuestsProvider = FutureProvider((ref) {
  return ref.read(questRepositoryProvider).getActiveQuests();
});

class QuestClaimNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> claim(Quest quest) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final result = await ref.read(questRepositoryProvider).claimReward(quest.userQuestId);
      final reward = result['reward'] as Map<String, dynamic>;

      ref.read(profileProvider.notifier).applyDelta(
            newTotalXp: reward['newTotalXp'] as int?,
            newLevel: reward['newLevel'] as int?,
            newCoins: reward['newCoins'] as int?,
          );

      ref.invalidate(activeQuestsProvider);
    });
  }
}

final questClaimProvider = AsyncNotifierProvider<QuestClaimNotifier, void>(QuestClaimNotifier.new);
