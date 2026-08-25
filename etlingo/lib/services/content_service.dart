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