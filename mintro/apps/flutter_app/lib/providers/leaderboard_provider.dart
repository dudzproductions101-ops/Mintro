import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_providers.dart';

final leaderboardProvider = FutureProvider((ref) {
  return ref.read(leaderboardRepositoryProvider).getMyLeaderboard();
});

final achievementsProvider = FutureProvider((ref) {
  return ref.read(achievementRepositoryProvider).getAllWithStatus();
});
