import '../models/leaderboard.dart';
import '../services/api_client.dart';

class LeaderboardRepository {
  Future<LeaderboardResult> getMyLeaderboard() async {
    final data = await ApiClient.instance.get('/leaderboard/me');
    return LeaderboardResult.fromJson(data as Map<String, dynamic>);
  }
}
