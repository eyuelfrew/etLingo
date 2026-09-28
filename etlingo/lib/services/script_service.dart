import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Writing system + alphabet letter (from admin-managed scripts API).
class ScriptInfo {
  final int id;
  final String code;
  final String name;
  final String nativeName;
  final String direction;
  final String family;
  final String sample;
  final String description;
  final bool isPrimary;
  final String role;
  final List<ScriptLetter> letters;

  ScriptInfo({
    required this.id,
    required this.code,
    required this.name,
    this.nativeName = '',
    this.direction = 'ltr',
    this.family = '',
    this.sample = '',
    this.description = '',
    this.isPrimary = false,
    this.role = 'secondary',
    this.letters = const [],
  });

  factory ScriptInfo.fromJson(Map<String, dynamic> j) {
    final raw = j['letters'];
    return ScriptInfo(
      id: (j['id'] as num?)?.toInt() ?? 0,
      code: (j['code'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      nativeName: (j['nativeName'] ?? '').toString(),
      direction: (j['direction'] ?? 'ltr').toString(),
      family: (j['family'] ?? '').toString(),
      sample: (j['sample'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      isPrimary: j['isPrimary'] == true,
      role: (j['role'] ?? 'secondary').toString(),
      letters: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => ScriptLetter.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

class ScriptLetter {
  final int id;
  final String glyph;
  final String name;
  final String roman;
  final String sound;
  final String orderName;
  final int formIndex;
  final String audioUrl;
  final String notes;
  final int sortOrder;

  ScriptLetter({
    required this.id,
    required this.glyph,
    this.name = '',
    this.roman = '',
    this.sound = '',
    this.orderName = '',
    this.formIndex = 0,
    this.audioUrl = '',
    this.notes = '',
    this.sortOrder = 0,
  });

  factory ScriptLetter.fromJson(Map<String, dynamic> j) => ScriptLetter(
        id: (j['id'] as num?)?.toInt() ?? 0,
        glyph: (j['glyph'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        roman: (j['roman'] ?? '').toString(),
        sound: (j['sound'] ?? '').toString(),
        orderName: (j['orderName'] ?? '').toString(),
        formIndex: (j['formIndex'] as num?)?.toInt() ?? 0,
        audioUrl: (j['audioUrl'] ?? j['audio_url'] ?? '').toString(),
        notes: (j['notes'] ?? '').toString(),
        sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
      );

  bool get hasAudio => audioUrl.isNotEmpty;
}

class LanguageScripts {
  final String code;
  final String name;
  final String nativeName;
  final List<ScriptInfo> scripts;

  LanguageScripts({
    required this.code,
    required this.name,
    required this.nativeName,
    this.scripts = const [],
  });

  factory LanguageScripts.fromJson(Map<String, dynamic> j) {
    final raw = j['scripts'];
    final lang = j['language'] is Map
        ? Map<String, dynamic>.from(j['language'] as Map)
        : const <String, dynamic>{};
    return LanguageScripts(
      code: (lang['code'] ?? '').toString(),
      name: (lang['name'] ?? '').toString(),
      nativeName: (lang['nativeName'] ?? '').toString(),
      scripts: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => ScriptInfo.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  ScriptInfo? get primary =>
      scripts.cast<ScriptInfo?>().firstWhere((s) => s!.isPrimary, orElse: () => null) ??
      (scripts.isEmpty ? null : scripts.first);
}

/// Thin client for /app/scripts with on-device cache (offline alphabet).
class ScriptService {
  ScriptService(this._get);
  final Future<dynamic> Function(String path) _get;

  static const _cachePrefix = 'etlingo_scripts_cache:';
  final Map<String, LanguageScripts> _memory = {};

  Future<LanguageScripts> forLanguage(String code, {bool forceRefresh = false}) async {
    if (!forceRefresh && _memory.containsKey(code)) return _memory[code]!;
    try {
      final data = await _get('/app/scripts?lang=$code');
      if (data is Map<String, dynamic>) {
        final pack = LanguageScripts.fromJson(data);
        _memory[code] = pack;
        await _saveCache(code, pack);
        return pack;
      }
    } catch (_) {
      final cached = await _readCache(code);
      if (cached != null) return cached;
    }
    return _memory[code] ?? LanguageScripts(code: code, name: '', nativeName: '');
  }

  Future<ScriptInfo> byCode(String scriptCode) async {
    try {
      final data = await _get('/app/scripts/$scriptCode/letters');
      if (data is Map<String, dynamic>) return ScriptInfo.fromJson(data);
    } catch (_) {}
    return ScriptInfo(id: 0, code: scriptCode, name: scriptCode);
  }

  Future<List<ScriptInfo>> all() async {
    final data = await _get('/app/scripts');
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => ScriptInfo.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  Future<void> _saveCache(String code, LanguageScripts pack) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_cachePrefix$code', jsonEncode({
        'language': {
          'code': pack.code,
          'name': pack.name,
          'nativeName': pack.nativeName,
        },
        'scripts': pack.scripts
            .map((s) => {
                  'id': s.id,
                  'code': s.code,
                  'name': s.name,
                  'nativeName': s.nativeName,
                  'direction': s.direction,
                  'family': s.family,
                  'sample': s.sample,
                  'description': s.description,
                  'isPrimary': s.isPrimary,
                  'role': s.role,
                  'letters': s.letters
                      .map((l) => {
                            'id': l.id,
                            'glyph': l.glyph,
                            'name': l.name,
                            'roman': l.roman,
                            'sound': l.sound,
                            'orderName': l.orderName,
                            'formIndex': l.formIndex,
                            'audioUrl': l.audioUrl,
                            'notes': l.notes,
                            'sortOrder': l.sortOrder,
                          })
                      .toList(),
                })
            .toList(),
      }));
    } catch (_) {}
  }

  Future<LanguageScripts?> _readCache(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_cachePrefix$code');
      if (raw == null) return null;
      final pack = LanguageScripts.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
      _memory[code] = pack;
      return pack;
    } catch (_) {
      return null;
    }
  }

  bool isCachedInMemory(String code) => _memory.containsKey(code);
}

/// Visual chip for a script (used on language / culture screens).
class ScriptBadge extends StatelessWidget {
  final ScriptInfo script;
  final VoidCallback? onTap;

  const ScriptBadge({super.key, required this.script, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF078930).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF078930).withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              script.sample.isEmpty
                  ? script.name.substring(0, 1)
                  : script.sample.substring(0, script.sample.length.clamp(1, 2)),
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF078930)),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  script.name,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800),
                ),
                Text(
                  '${script.letters.length} letters${script.isPrimary ? ' · primary' : ''}',
                  style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B6B6B)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
