import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/profile_repository.dart';
import '../repositories/learning_repository.dart';
import '../repositories/quest_repository.dart';
import '../repositories/goal_repository.dart';
import '../repositories/leaderboard_repository.dart';
import '../repositories/achievement_repository.dart';

final profileRepositoryProvider = Provider((ref) => ProfileRepository());
final learningRepositoryProvider = Provider((ref) => LearningRepository());
final questRepositoryProvider = Provider((ref) => QuestRepository());
final goalRepositoryProvider = Provider((ref) => GoalRepository());
final leaderboardRepositoryProvider = Provider((ref) => LeaderboardRepository());
final achievementRepositoryProvider = Provider((ref) => AchievementRepository());
