import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thematic word packs (Animals, Food…) from admin.
class TopicWord {
  final int id;
  final String target;
  final String translit;
  final String meaning;
  final String meaningLocal;
  final Map<String, String> meanings;
  final String audioUrl;
  final String imageUrl;

  TopicWord({
    required this.id,
    required this.target,
    this.translit = '',
    this.meaning = '',
    this.meaningLocal = '',
    this.meanings = const {},
    this.audioUrl = '',
    this.imageUrl = '',
  });

  bool get hasAudio => audioUrl.isNotEmpty;

  String meaningFor(String base) {
    if (meaningLocal.isNotEmpty) return meaningLocal;
    if (meanings[base]?.isNotEmpty == true) return meanings[base]!;
    return meaning;
  }

  factory TopicWord.fromJson(Map<String, dynamic> j) {
    final raw = j['meanings'];
    final map = <String, String>{};
    if (raw is Map) {
      raw.forEach((k, v) => map[k.toString()] = (v ?? '').toString());
    }
    return TopicWord(
      id: (j['id'] as num?)?.toInt() ?? 0,
      target: (j['target'] ?? '').toString(),
      translit: (j['translit'] ?? '').toString(),
      meaning: (j['meaning'] ?? '').toString(),
      meaningLocal: (j['meaningLocal'] ?? '').toString(),
      meanings: map,
      audioUrl: (j['audioUrl'] ?? j['audio_url'] ?? '').toString(),
      imageUrl: (j['imageUrl'] ?? j['image_url'] ?? '').toString(),
    );
  }
}

class TopicCategory {
  final int id;
  final String slug;
  final String title;
  final String nativeTitle;
  final String emoji;
  final Color color;
  final String description;
  final List<TopicWord> words;

  TopicCategory({
    required this.id,
    required this.slug,
    required this.title,
    this.nativeTitle = '',
    this.emoji = '',
    this.color = const Color(0xFF078930),
    this.description = '',
    this.words = const [],
  });

  factory TopicCategory.fromJson(Map<String, dynamic> j) {
    final raw = j['words'];
    final hex = (j['colorHex'] ?? j['color_hex'] ?? '').toString();
    return TopicCategory(
      id: (j['id'] as num?)?.toInt() ?? 0,
      slug: (j['slug'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      nativeTitle: (j['nativeTitle'] ?? j['native_title'] ?? '').toString(),
      emoji: (j['emoji'] ?? '📚').toString(),
      color: _parseColor(hex),
      description: (j['description'] ?? '').toString(),
      words: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => TopicWord.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  static Color _parseColor(String hex) {
    var h = hex.replaceFirst('#', '').trim();
    if (h.length == 6) h = 'FF$h';
    final v = int.tryParse(h, radix: 16);
    return v != null ? Color(v) : const Color(0xFF078930);
  }
}

class TopicPack {
  final List<TopicCategory> categories;
  TopicPack({this.categories = const []});

  factory TopicPack.fromJson(Map<String, dynamic> j) {
    final raw = j['categories'];
    return TopicPack(
      categories: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => TopicCategory.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

class TopicService {
  TopicService(this._get);
  final Future<dynamic> Function(String path) _get;
  static const _cachePrefix = 'etlingo_topics_cache:';
  final Map<String, TopicPack> _memory = {};

  Future<TopicPack> forLanguage(String code, {String base = 'en'}) async {
    if (_memory.containsKey(code)) return _memory[code]!;
    try {
      final data = await _get('/app/topics/$code?base=$base');
      if (data is Map<String, dynamic>) {
        final pack = TopicPack.fromJson(data);
        _memory[code] = pack;
        await _save(code, pack);
        return pack;
      }
    } catch (_) {
      final cached = await _read(code);
      if (cached != null) return cached;
    }
    return _memory[code] ?? TopicPack();
  }

  Future<void> _save(String code, TopicPack pack) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_cachePrefix$code',
        jsonEncode({
          'categories': pack.categories
              .map((c) => {
                    'id': c.id,
                    'slug': c.slug,
                    'title': c.title,
                    'nativeTitle': c.nativeTitle,
                    'emoji': c.emoji,
                    'description': c.description,
                    'words': c.words
                        .map((w) => {
                              'id': w.id,
                              'target': w.target,
                              'translit': w.translit,
                              'meaning': w.meaning,
                              'meaningLocal': w.meaningFor('en'),
                              'meanings': w.meanings,
                              'audioUrl': w.audioUrl,
                              'imageUrl': w.imageUrl,
                            })
                        .toList(),
                  })
              .toList(),
        }),
      );
    } catch (_) {}
  }

  Future<TopicPack?> _read(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_cachePrefix$code');
      if (raw == null) return null;
      final pack = TopicPack.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
      _memory[code] = pack;
      return pack;
    } catch (_) {
      return null;
    }
  }
}
