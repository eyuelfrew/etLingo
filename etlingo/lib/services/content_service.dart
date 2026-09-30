import '../data/models.dart';
import 'api_client.dart';

export 'api_client.dart' show ApiClient, ApiException;

/// Loads admin-managed course content from the backend.
class ContentService {
  ContentService(this._client);

  final ApiClient _client;

  Future<List<Language>> loadLanguages() async {
    final data = await _client.get('/app/languages', auth: false);
    if (data is! List) return const [];
    return data
        .map((j) => Language.summaryJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Instruction languages the learner already speaks (admin-managed).
  Future<List<BaseLanguageOption>> loadBaseLanguages() async {
    final data = await _client.get('/app/base-languages', auth: false);
    if (data is! List) return BaseLanguageOption.defaults;
    final rows = data
        .whereType<Map>()
        .map((j) => BaseLanguageOption.fromJson(Map<String, dynamic>.from(j)))
        .where((b) => b.code.isNotEmpty)
        .toList();
    return rows.isEmpty ? BaseLanguageOption.defaults : rows;
  }

  Future<
      ({
        Language? language,
        List<int> purchasedUnitIds,
      })> loadLanguageContent(String code) async {
    final data = await _client.getWithOptionalAuth('/app/bootstrap/$code');
    if (data is! Map<String, dynamic>) {
      return (language: null, purchasedUnitIds: const <int>[]);
    }
    final lang = Language.fullJson(
      (data['language'] ?? const {}) as Map<String, dynamic>,
      (data['units'] ?? const []) as List<dynamic>,
      (data['lessons'] ?? const []) as List<dynamic>,
      (data['questions'] ?? const []) as List<dynamic>,
      (data['phrases'] ?? const []) as List<dynamic>,
    );
    final raw = data['purchasedUnitIds'];
    final ids = <int>[];
    if (raw is List) {
      for (final x in raw) {
        final n = x is num ? x.toInt() : int.tryParse('$x');
        if (n != null) ids.add(n);
      }
    }
    return (language: lang, purchasedUnitIds: ids);
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
        createdAt: j['createdAt'] is String
            ? DateTime.tryParse(j['createdAt'] as String)
            : null,
      );
}

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
