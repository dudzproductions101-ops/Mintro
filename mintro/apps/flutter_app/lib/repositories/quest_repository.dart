import '../models/quest.dart';
import '../services/api_client.dart';

class QuestRepository {
  Future<List<Quest>> getActiveQuests() async {
    final data = await ApiClient.instance.get('/quests/active') as List;
    return data.map((json) => Quest.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> claimReward(String userQuestId) async {
    final data = await ApiClient.instance.post('/quests/$userQuestId/claim');
    return data as Map<String, dynamic>;
  }
}
