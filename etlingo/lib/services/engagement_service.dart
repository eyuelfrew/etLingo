import 'package:flutter/foundation.dart';

import 'api_client.dart';

class EngagementComment {
  final int id;
  final int userId;
  final String author;
  final String body;
  final DateTime? createdAt;
  final bool mine;

  EngagementComment({
    required this.id,
    required this.userId,
    required this.author,
    required this.body,
    this.createdAt,
    this.mine = false,
  });

  factory EngagementComment.fromJson(Map<String, dynamic> j) => EngagementComment(
        id: (j['id'] as num?)?.toInt() ?? 0,
        userId: (j['userId'] as num?)?.toInt() ?? 0,
        author: (j['author'] ?? '').toString(),
        body: (j['body'] ?? '').toString(),
        createdAt: j['createdAt'] is String
            ? DateTime.tryParse(j['createdAt'] as String)
            : null,
        mine: j['mine'] == true,
      );
}

class Engagement {
  final String target;
  final int id;
  final int likes;
  final bool likedByMe;
  final int commentCount;
  final List<EngagementComment> comments;

  Engagement({
    required this.target,
    required this.id,
    this.likes = 0,
    this.likedByMe = false,
    this.commentCount = 0,
    this.comments = const [],
  });

  Engagement copyWith({
    int? likes,
    bool? likedByMe,
    int? commentCount,
    List<EngagementComment>? comments,
  }) =>
      Engagement(
        target: target,
        id: id,
        likes: likes ?? this.likes,
        likedByMe: likedByMe ?? this.likedByMe,
        commentCount: commentCount ?? this.commentCount,
        comments: comments ?? this.comments,
      );

  factory Engagement.fromJson(Map<String, dynamic> j,
      {String target = '', int id = 0}) {
    final raw = j['comments'];
    return Engagement(
      target: (j['target'] ?? target).toString(),
      id: (j['id'] as num?)?.toInt() ?? id,
      likes: (j['likes'] as num?)?.toInt() ?? 0,
      likedByMe: j['likedByMe'] == true,
      commentCount: (j['commentCount'] as num?)?.toInt() ??
          (raw is List ? raw.length : 0),
      comments: raw is List
          ? raw
              .whereType<Map>()
              .map(
                  (e) => EngagementComment.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

/// Likes are sticky (one per user) and persist on the server after logout/login.
class EngagementService {
  EngagementService(this._client);
  final ApiClient _client;

  /// Counts are public; JWT is sent when signed in so `likedByMe` is correct.
  Future<Engagement> unit(int unitId) async {
    final data =
        await _client.getWithOptionalAuth('/app/engagement/units/$unitId');
    if (data is Map<String, dynamic>) {
      return Engagement.fromJson(data, target: 'unit', id: unitId);
    }
    return Engagement(target: 'unit', id: unitId);
  }

  Future<Engagement> language(int languageId) async {
    final data = await _client
        .getWithOptionalAuth('/app/engagement/languages/$languageId');
    if (data is Map<String, dynamic>) {
      return Engagement.fromJson(data, target: 'language', id: languageId);
    }
    return Engagement(target: 'language', id: languageId);
  }

  /// One-time like. Does not unlike on repeat taps.
  Future<({bool liked, int likes, bool alreadyLiked})> likeUnit(
      int unitId) async {
    final data = await _client.post('/app/engagement/units/$unitId/like');
    debugPrint('[engagement] likeUnit $unitId → $data');
    if (data is! Map) {
      // Server returned empty/null body — treat as success if no exception.
      return (liked: true, likes: 0, alreadyLiked: false);
    }
    return (
      liked: data['liked'] != false,
      likes: (data['likes'] as num?)?.toInt() ?? 0,
      alreadyLiked: data['alreadyLiked'] == true,
    );
  }

  Future<({bool liked, int likes, bool alreadyLiked})> likeLanguage(
      int languageId) async {
    final data =
        await _client.post('/app/engagement/languages/$languageId/like');
    debugPrint('[engagement] likeLanguage $languageId → $data');
    if (data is! Map) {
      return (liked: true, likes: 0, alreadyLiked: false);
    }
    return (
      liked: data['liked'] != false,
      likes: (data['likes'] as num?)?.toInt() ?? 0,
      alreadyLiked: data['alreadyLiked'] == true,
    );
  }

  Future<({bool liked, int likes, bool alreadyLiked})> likeCultureUnit(
      int cultureUnitId) async {
    final data =
        await _client.post('/app/engagement/culture-units/$cultureUnitId/like');
    debugPrint('[engagement] likeCultureUnit $cultureUnitId → $data');
    if (data is! Map) {
      return (liked: true, likes: 0, alreadyLiked: false);
    }
    return (
      liked: data['liked'] != false,
      likes: (data['likes'] as num?)?.toInt() ?? 0,
      alreadyLiked: data['alreadyLiked'] == true,
    );
  }

  Future<EngagementComment?> commentCultureUnit(
      int cultureUnitId, String body) async {
    final data = await _client.post(
      '/app/engagement/culture-units/$cultureUnitId/comments',
      body: {'body': body},
    );
    if (data is Map && data['comment'] is Map) {
      return EngagementComment.fromJson(
          Map<String, dynamic>.from(data['comment'] as Map));
    }
    return null;
  }

  Future<Engagement> cultureUnit(int cultureUnitId) async {
    final data = await _client
        .getWithOptionalAuth('/app/engagement/culture-units/$cultureUnitId');
    if (data is Map<String, dynamic>) {
      return Engagement.fromJson(data,
          target: 'cultureUnit', id: cultureUnitId);
    }
    return Engagement(target: 'cultureUnit', id: cultureUnitId);
  }

  Future<EngagementComment?> commentUnit(int unitId, String body) async {
    final data = await _client.post(
      '/app/engagement/units/$unitId/comments',
      body: {'body': body},
    );
    if (data is Map && data['comment'] is Map) {
      return EngagementComment.fromJson(
          Map<String, dynamic>.from(data['comment'] as Map));
    }
    return null;
  }

  Future<EngagementComment?> commentLanguage(int languageId, String body) async {
    final data = await _client.post(
      '/app/engagement/languages/$languageId/comments',
      body: {'body': body},
    );
    if (data is Map && data['comment'] is Map) {
      return EngagementComment.fromJson(
          Map<String, dynamic>.from(data['comment'] as Map));
    }
    return null;
  }
}
