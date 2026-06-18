/// Maps to the `learning_paths` table.
class LearningPath {
  final String id;
  final String slug;
  final String title;
  final String description;
  final String? icon;
  final String colorHex;
  final String difficulty;
  final int sortOrder;
  final bool isPremium;
  final int completedLessons;
  final int totalLessons;

  const LearningPath({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.icon,
    required this.colorHex,
    required this.difficulty,
    required this.sortOrder,
    required this.isPremium,
    required this.completedLessons,
    required this.totalLessons,
  });

  factory LearningPath.fromJson(
    Map<String, dynamic> json, {
    int completedLessons = 0,
    int totalLessons = 0,
  }) {
    return LearningPath(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String?,
      colorHex: json['color_hex'] as String? ?? '#1F7A3D',
      difficulty: json['difficulty'] as String? ?? 'beginner',
      sortOrder: json['sort_order'] as int? ?? 0,
      isPremium: json['is_premium'] as bool? ?? false,
      completedLessons: completedLessons,
      totalLessons: totalLessons,
    );
  }

  double get progress => totalLessons == 0 ? 0 : completedLessons / totalLessons;
  bool get isComplete => totalLessons > 0 && completedLessons >= totalLessons;
}

enum LessonType {
  multipleChoice,
  matchPairs,
  dragDrop,
  simulation,
  trueFalse,
  flashcard,
  scenario,
}

LessonType _lessonTypeFromString(String value) {
  switch (value) {
    case 'multiple_choice':
      return LessonType.multipleChoice;
    case 'match_pairs':
      return LessonType.matchPairs;
    case 'drag_drop':
      return LessonType.dragDrop;
    case 'simulation':
      return LessonType.simulation;
    case 'true_false':
      return LessonType.trueFalse;
    case 'flashcard':
      return LessonType.flashcard;
    case 'scenario':
      return LessonType.scenario;
    default:
      return LessonType.multipleChoice;
  }
}

/// Maps to the `lessons` table.
class Lesson {
  final String id;
  final String pathId;
  final String slug;
  final String title;
  final String description;
  final LessonType type;
  final String? icon;
  final int xpReward;
  final int coinReward;
  final int sortOrder;
  final int estimatedMinutes;
  final bool isPremium;
  final bool isCompleted;
  final List<QuizQuestion> questions;

  const Lesson({
    required this.id,
    required this.pathId,
    required this.slug,
    required this.title,
    required this.description,
    required this.type,
    required this.icon,
    required this.xpReward,
    required this.coinReward,
    required this.sortOrder,
    required this.estimatedMinutes,
    required this.isPremium,
    required this.isCompleted,
    required this.questions,
  });

  factory Lesson.fromJson(Map<String, dynamic> json, {bool isCompleted = false}) {
    final content = json['content'] as Map<String, dynamic>? ?? {};
    final rawQuestions = content['questions'] as List<dynamic>? ?? [];

    return Lesson(
      id: json['id'] as String,
      pathId: json['path_id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      type: _lessonTypeFromString(json['lesson_type'] as String? ?? 'multiple_choice'),
      icon: json['icon'] as String?,
      xpReward: json['xp_reward'] as int? ?? 10,
      coinReward: json['coin_reward'] as int? ?? 5,
      sortOrder: json['sort_order'] as int? ?? 0,
      estimatedMinutes: json['estimated_minutes'] as int? ?? 5,
      isPremium: json['is_premium'] as bool? ?? false,
      isCompleted: isCompleted,
      questions: rawQuestions
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }
}

class QuizQuestion {
  final String id;
  final String type;
  final String prompt;
  final List<QuizOption> options;

  const QuizQuestion({
    required this.id,
    required this.type,
    required this.prompt,
    required this.options,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? [];
    return QuizQuestion(
      id: json['id'] as String,
      type: json['type'] as String,
      prompt: json['prompt'] as String,
      options: rawOptions
          .map((o) => QuizOption.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }
}

class QuizOption {
  final String id;
  final String label;

  const QuizOption({required this.id, required this.label});

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(id: json['id'] as String, label: json['label'] as String);
  }
}
