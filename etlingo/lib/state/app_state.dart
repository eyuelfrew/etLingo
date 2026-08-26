import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/content_service.dart';

class AppState extends ChangeNotifier {
  AppState([AuthService? auth]) : _content = _makeContent(auth);

  static ContentService _makeContent(AuthService? auth) {
    if (auth != null) return auth.content;
    // Standalone mode (tests / guest): course endpoints are public.
    return ContentService(ApiClient(tokenProvider: () async => null));
  }

  final ContentService _content;

  Language _language = _emptyLanguage;
  List<Language> _languages = const [];
  final Set<String> _completedLessons = {};
  int _xp = 0;
  int _xpToday = 0;
  int _hearts = 5;
  final int _streak = 0;
  bool _onboarded = false;

  bool _loadingLanguages = false;
  bool _loadingContent = false;
  String? _error;

  static const String _langKey = 'etlingo_language';

  Language get language => _language;
  List<Language> get languages => _languages;
  int get xp => _xp;
  int get xpToday => _xpToday;
  int get hearts => _hearts;
  int get streak => _streak;
  bool get onboarded => _onboarded;
  Set<String> get completedLessons => _completedLessons;
  bool get loadingLanguages => _loadingLanguages;
  bool get loadingContent => _loadingContent;
  String? get error => _error;

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

  /// Fetch the admin-managed language list for the picker.
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

  /// Restore a previously chosen language on cold start (loads full content).
  Future<bool> restoreSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_langKey);
    if (code == null || code.isEmpty) return false;

    try {
      final full = await _content.loadLanguageContent(code);
      if (full == null) return false;
      _language = full;
      _onboarded = true;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Re-fetch the current language's units/lessons/questions from the backend.
  ///
  /// Content is cached in memory after the initial load, so lessons and
  /// questions published by admins afterwards never appeared until the learner
  /// re-picked the language or reinstalled. Call this from pull-to-refresh
  /// (and anywhere freshness matters). Progress is untouched — completed
  /// lesson ids live separately.
  Future<bool> refreshLanguage() async {
    final code = _language.id;
    if (code.isEmpty || _loadingContent) return false;

    _loadingContent = true;
    _error = null;
    notifyListeners();
    try {
      final fresh = await _content.loadLanguageContent(code);
      if (!mounted) return false; // guard below via hasListeners pattern
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

  /// Pick a language, then pull its full admin-managed course content.
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
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loadingContent = false;
      notifyListeners();
    }
  }

  void loseHeart() {
    if (_hearts > 0) _hearts--;
    notifyListeners();
  }

  void refillHearts() {
    _hearts = 5;
    notifyListeners();
  }

  void completeLesson(Lesson lesson, {required int mistakes}) {
    _completedLessons.add(lesson.id);
    final bonus = mistakes == 0 ? 5 : 0;
    final earned = 10 + bonus;
    _xp += earned;
    _xpToday += earned;
    notifyListeners();
  }

  int lessonReward({required int mistakes}) => mistakes == 0 ? 15 : 10;

  void resetProgress() {
    _completedLessons.clear();
    _xp = 0;
    _xpToday = 0;
    _hearts = 5;
    notifyListeners();
  }
}
