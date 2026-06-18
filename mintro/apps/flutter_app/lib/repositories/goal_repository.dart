import '../models/goal.dart';
import '../services/api_client.dart';

class GoalRepository {
  Future<List<Goal>> getGoals() async {
    final data = await ApiClient.instance.get('/goals') as List;
    return data.map((json) => Goal.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Goal> createGoal({
    required String name,
    String? icon,
    required double targetAmount,
    String currency = 'EUR',
    String? deadline,
    double initialAmount = 0,
  }) async {
    final data = await ApiClient.instance.post('/goals', {
      'name': name,
      if (icon != null) 'icon': icon,
      'targetAmount': targetAmount,
      'currency': currency,
      if (deadline != null) 'deadline': deadline,
      'initialAmount': initialAmount,
    });
    return Goal.fromJson(data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> contribute(String goalId, double amount) async {
    final data = await ApiClient.instance.post('/goals/$goalId/contribute', {'amount': amount});
    return data as Map<String, dynamic>;
  }
}
