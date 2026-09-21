import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/ui/et_strings.dart';
import '../data/models.dart';
import '../services/auth_service.dart';
import '../services/content_service.dart';

class AppState extends ChangeNotifier {
  AppState([AuthService? auth]) : _auth = auth {
    _content = _makeContent(auth);
    _api = auth != null
        ? ApiClient(tokenProvider: () async => auth.token)
        : ApiClient(tokenProvider: () async => null);
    _loadLocalProgress();
    _restoreAppLanguage();
  }

  Future<void> _restoreAppLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_appLangKey);
      _appLanguage = (saved == 'am') ? 'am' : 'en';
      EtStrings.setLang(_appLanguage);
      notifyListeners();
    } catch (_) {
      EtStrings.setLang('en');
    }
  }

  /// Switch UI chrome language (English / Amharic). Persisted on device.
  Future<void> chooseAppLanguage(String code) async {
    _appLanguage = (code == 'am') ? 'am' : 'en';
    EtStrings.setLang(_appLanguage);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_appLangKey, _appLanguage);
    } catch (_) {}
  }

  static ContentService _makeContent(AuthService? auth) {
    if (auth != null) return auth.content;
    return ContentService(ApiClient(tokenProvider: () async => null));
  }

  final AuthService? _auth;
  late final ContentService _content;
  late final ApiClient _api;

  Language _language = _emptyLanguage;
  List<Language> _languages = const [];
  List<BaseLanguageOption> _baseLanguages = BaseLanguageOption.defaults;
  final Set<String> _completedLessons = {};
  int _xp = 0;
  int _xpToday = 0;
  int _hearts = 5;
  int _streak = 0;
  bool _onboarded = false;
  String _baseLanguage = 'en';
  String _appLanguage = 'en';

  bool _loadingLanguages = false;
  bool _loadingContent = false;
  String? _error;

  static const String _langKey = 'etlingo_language';
  static const String _baseLangKey = 'etlingo_base_language';
  static const String _appLangKey = 'etlingo_app_language';
  static const String _progressKey = 'etlingo_local_progress';

  Language get language => _language;
  List<Language> get languages => _languages;
  List<BaseLanguageOption> get baseLanguages => _baseLanguages;
  String get baseLanguage => _baseLanguage;
  /// UI chrome language: 'en' (default) or 'am'.
  String get appLanguage => _appLanguage;
  int get xp => _xp;
  int get xpToday => _xpToday;
  int get hearts => _hearts;
  int get streak => _streak;
  bool get onboarded => _onboarded;
  Set<String> get completedLessons => _completedLessons;
  bool get loadingLanguages => _loadingLanguages;
  bool get loadingContent => _loadingContent;
  String? get error => _error;
  bool get isSignedIn => _auth?.token != null;

  static const dailyGoal = 50;

  double get goalProgress => (_xpToday / dailyGoal).clamp(0.0, 1.0);

  static Language get _emptyLanguage => const Language(
        id: '',
        name: '',
        nativeName: 'ኢትLang',
        scriptPreview: '',
        speakers: '',
        region: '',
        color: Color(0xFF078930),
        dark: Color(0xFF056B24),
        icon: Icons.waving_hand_rounded,
        helloTarget: 'ሰላም',
        helloMeaning: 'Hello',
        units: [],
        phrases: [],
      );

  bool isLessonComplete(Lesson lesson) => _completedLessons.contains(lesson.id);

  int completedInUnit(Unit unit) =>
      unit.lessons.where((l) => _completedLessons.contains(l.id)).length;

  double unitProgress(Unit unit) {
    if (unit.lessons.isEmpty) return 0;
    return completedInUnit(unit) / unit.lessons.length;
  }

  double get courseProgress {
    final total = _language.totalLessons;
    if (total == 0) return 0;
    var done = 0;
    for (final u in _language.units) {
      done += completedInUnit(u);
    }
    return (done / total).clamp(0.0, 1.0);
  }

  int get totalLessonsDone {
    var done = 0;
    for (final u in _language.units) {
      done += completedInUnit(u);
    }
    return done;
  }

  Lesson? nextLesson() {
    for (final unit in _language.units) {
      for (final lesson in unit.lessons) {
        if (!_completedLessons.contains(lesson.id)) return lesson;
      }
    }
    return null;
  }

  Unit? unitOf(Lesson lesson) {
    for (final unit in _language.units) {
      if (unit.lessons.any((l) => l.id == lesson.id)) return unit;
    }
    return null;
  }

  Future<void> loadLanguages() async {
    if (_loadingLanguages) return;
    _loadingLanguages = true;
    _error = null;
    notifyListeners();
    try {
      _languages = await _content.loadLanguages();
      if (_languages.isEmpty) {
        _error = 'No languages available yet — ask an admin to add some.';
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loadingLanguages = false;
      notifyListeners();
    }
  }

  /// Pull admin-managed base (instruction) languages for the picker.
  Future<void> loadBaseLanguages() async {
    try {
      final list = await _content.loadBaseLanguages();
      if (list.isNotEmpty) {
        _baseLanguages = list;
        if (!_baseLanguages.any((b) => b.code == _baseLanguage)) {
          _baseLanguage = _baseLanguages.first.code;
        }
        notifyListeners();
      }
    } catch (_) {
      // Keep defaults if API is offline.
    }
  }

  Future<bool> restoreSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_langKey);
    final savedBase = prefs.getString(_baseLangKey);
    if (savedBase != null && savedBase.isNotEmpty) _baseLanguage = savedBase;
    await _loadLocalProgress();
    if (code == null || code.isEmpty) return false;

    try {
      final full = await _content.loadLanguageContent(code);
      if (full == null) return false;
      _language = full;
      _onboarded = true;
      notifyListeners();
      await syncProgressFromServer();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> refreshLanguage() async {
    final code = _language.id;
    if (code.isEmpty || _loadingContent) return false;

    _loadingContent = true;
    _error = null;
    notifyListeners();
    try {
      final fresh = await _content.loadLanguageContent(code);
      if (!mounted) return false;
      if (fresh != null && fresh.id == code) {
        _language = fresh;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _loadingContent = false;
      notifyListeners();
    }
  }

  bool get mounted => !_disposed;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> chooseLanguage(Language lang) async {
    _language = lang;
    _onboarded = true;
    notifyListeners();

    _loadingContent = true;
    _error = null;
    notifyListeners();
    try {
      final full = await _content.loadLanguageContent(lang.id);
      if (full != null) _language = full;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_langKey, lang.id);
      await syncProgressFromServer();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loadingContent = false;
      notifyListeners();
    }
  }

  Future<void> chooseBaseLanguage(String code) async {
    _baseLanguage = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseLangKey, code);
  }

  void loseHeart() {
    if (_hearts > 0) _hearts--;
    _persistLocalProgress();
    notifyListeners();
  }

  void refillHearts() {
    _hearts = 5;
    _persistLocalProgress();
    notifyListeners();
  }

  int lessonReward({required int mistakes, int? xpReward}) {
    final base = xpReward ?? 10;
    return mistakes == 0 ? base + 5 : base;
  }

  Future<void> completeLesson(
    Lesson lesson, {
    required int mistakes,
  }) async {
    final already = _completedLessons.contains(lesson.id);
    final earned = lessonReward(mistakes: mistakes, xpReward: lesson.xpReward);
    _completedLessons.add(lesson.id);
    if (!already) {
      _xp += earned;
      _xpToday += earned;
    }
    if (_streak == 0) _streak = 1;
    notifyListeners();
    await _persistLocalProgress();
    await _syncLessonToServer(lesson, mistakes: mistakes, earned: earned);
  }

  Future<void> resetProgress() async {
    _completedLessons.clear();
    _xp = 0;
    _xpToday = 0;
    _hearts = 5;
    _streak = 0;
    notifyListeners();
    await _persistLocalProgress();
  }

  /// Pull server truth (xp/streak/hearts/completed) after sign-in.
  Future<void> syncProgressFromServer() async {
    if (_auth?.token == null) return;
    try {
      final data = await _api.get('/app/progress');
      if (data is! Map<String, dynamic>) return;
      _applyServerProgress(data);
      notifyListeners();
      await _persistLocalProgress();
    } catch (_) {
      // Offline / guest — local cache remains the source of truth.
    }
  }

  Future<void> _syncLessonToServer(
    Lesson lesson, {
    required int mistakes,
    required int earned,
  }) async {
    if (_auth?.token == null) return;
    final lid = int.tryParse(lesson.id);
    if (lid == null) return;
    try {
      final data = await _api.post('/app/progress/lesson', body: {
        'lessonId': lid,
        'mistakes': mistakes,
        'xpEarned': earned,
        'hearts': _hearts,
      });
      if (data is Map<String, dynamic>) {
        _applyServerProgress(data);
        notifyListeners();
        await _persistLocalProgress();
      }
    } catch (e) {
      debugPrint('Progress sync failed (kept locally): $e');
    }
  }

  void _applyServerProgress(Map<String, dynamic> data) {
    final serverXp = data['xp'];
    if (serverXp is num) _xp = serverXp.toInt();
    final serverHearts = data['hearts'];
    if (serverHearts is num) {
      _hearts = serverHearts.toInt().clamp(0, 5);
    }
    final serverStreak = data['streak'];
    if (serverStreak is num) _streak = serverStreak.toInt();

    final ids = data['completedLessonIds'];
    if (ids is List) {
      _completedLessons
        ..clear()
        ..addAll(ids.map((e) => e.toString()));
    }
  }

  Future<void> _loadLocalProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_progressKey);
      if (raw == null) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _xp = (data['xp'] as num?)?.toInt() ?? _xp;
      _xpToday = (data['xpToday'] as num?)?.toInt() ?? 0;
      _hearts = (data['hearts'] as num?)?.toInt() ?? _hearts;
      _streak = (data['streak'] as num?)?.toInt() ?? _streak;
      final ids = data['completed'];
      if (ids is List) {
        _completedLessons
          ..clear()
          ..addAll(ids.map((e) => e.toString()));
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persistLocalProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _progressKey,
        jsonEncode({
          'xp': _xp,
          'xpToday': _xpToday,
          'hearts': _hearts,
          'streak': _streak,
          'completed': _completedLessons.toList(),
        }),
      );
    } catch (_) {}
  }
}
