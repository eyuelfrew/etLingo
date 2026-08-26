import '../data/models.dart';
import 'api_client.dart';

/// Loads admin-managed course content from the backend.
class ContentService {
  ContentService(this._client);

  final ApiClient _client;

  /// Active languages for the picker (metadata only).
  Future<List<Language>> loadLanguages() async {
    final data = await _client.get('/app/languages', auth: false);
    if (data is! List) return const [];
    return data
        .map((j) => Language.summaryJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Full units/lessons/questions/phrases for one language.
  Future<Language?> loadLanguageContent(String code) async {
    final data = await _client.get('/app/bootstrap/$code', auth: false);
    if (data is! Map<String, dynamic>) return null;
    return Language.fullJson(
      (data['language'] ?? const {}) as Map<String, dynamic>,
      (data['units'] ?? const []) as List<dynamic>,
      (data['lessons'] ?? const []) as List<dynamic>,
      (data['questions'] ?? const []) as List<dynamic>,
      (data['phrases'] ?? const []) as List<dynamic>,
    );
  }
}

class AppNotification {
  final int id;
  final String title;
  final String body;
  final String type;
  final bool broadcast;
  final bool read;
  final DateTime? createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.broadcast,
    required this.read,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] is num ? (j['id'] as num).toInt() : 0,
        title: (j['title'] ?? '').toString(),
        body: (j['body'] ?? '').toString(),
        type: (j['type'] ?? 'general').toString(),
        broadcast: j['broadcast'] == true,
        read: j['read'] == true,
        createdAt:
            j['createdAt'] is String ? DateTime.tryParse(j['createdAt'] as String) : null,
      );
}

/// Per-learner notification opt-outs, mirrored from the backend
/// (`GET/PUT /app/notifications/preferences`). `promotions` defaults to off on
/// the server; everything else defaults to on.
class AppNotificationPrefs {
  final bool pushEnabled;
  final bool lessonReminders;
  final bool streakMilestones;
  final bool achievements;
  final bool newContent;
  final bool appUpdates;
  final bool tips;
  final bool promotions;

  const AppNotificationPrefs({
    this.pushEnabled = true,
    this.lessonReminders = true,
    this.streakMilestones = true,
    this.achievements = true,
    this.newContent = true,
    this.appUpdates = true,
    this.tips = true,
    this.promotions = false,
  });

  factory AppNotificationPrefs.fromJson(Map<String, dynamic> j) =>
      AppNotificationPrefs(
        pushEnabled: j['pushEnabled'] != false,
        lessonReminders: j['lessonReminders'] != false,
        streakMilestones: j['streakMilestones'] != false,
        achievements: j['achievements'] != false,
        newContent: j['newContent'] != false,
        appUpdates: j['appUpdates'] != false,
        tips: j['tips'] != false,
        promotions: j['promotions'] == true,
      );

  Map<String, dynamic> toJson() => {
        'pushEnabled': pushEnabled,
        'lessonReminders': lessonReminders,
        'streakMilestones': streakMilestones,
        'achievements': achievements,
        'newContent': newContent,
        'appUpdates': appUpdates,
        'tips': tips,
        'promotions': promotions,
      };

  AppNotificationPrefs copyWith({
    bool? pushEnabled,
    bool? lessonReminders,
    bool? streakMilestones,
    bool? achievements,
    bool? newContent,
    bool? appUpdates,
    bool? tips,
    bool? promotions,
  }) =>
      AppNotificationPrefs(
        pushEnabled: pushEnabled ?? this.pushEnabled,
        lessonReminders: lessonReminders ?? this.lessonReminders,
        streakMilestones: streakMilestones ?? this.streakMilestones,
        achievements: achievements ?? this.achievements,
        newContent: newContent ?? this.newContent,
        appUpdates: appUpdates ?? this.appUpdates,
        tips: tips ?? this.tips,
        promotions: promotions ?? this.promotions,
      );
}