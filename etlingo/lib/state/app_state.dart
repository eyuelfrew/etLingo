import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/ui/et_strings.dart';
import '../data/models.dart';
import '../features/culture/culture_screen.dart';
import '../services/auth_service.dart';
import '../services/content_service.dart';
import '../services/engagement_service.dart';
import '../services/script_service.dart';
import '../services/topic_service.dart';
import '../widgets/app_ad_card.dart';

class AppState extends ChangeNotifier {
  AppState([AuthService? auth]) : _auth = auth {
    _content = _makeContent(auth);
    _api = auth != null
        ? ApiClient(tokenProvider: () async => auth.token)
        : ApiClient(tokenProvider: () async => null);
    _engagement = EngagementService(_api);
    _loadLocalProgress();
    _restoreAppLanguage();
    _restoreCultureDone();
    ensureCultureCacheFlags();
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
    EtStrings.setLang(_appLanguage); // notifies langNotifier → UI rebuilds
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
  late final EngagementService _engagement;

  EngagementService get engagement => _engagement;
  bool get canEngage => isSignedIn;

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
  bool _subscribed = false;
  bool get subscribed => _subscribed;

  /// Unit ids unlocked by one-time purchase (chapter paywalls).
  final Set<int> _ownedUnitIds = {};
  bool ownsUnit(int? unitId) =>
      unitId != null && (_ownedUnitIds.contains(unitId) || _subscribed);

  bool isUnitLocked(Unit unit) {
    if (!unit.isPaid && !unit.isPremium) return false;
    return !ownsUnit(unit.dbId);
  }

  /// Purchase a paid chapter via Chapa (returns payment URL or error msg).
  Future<Map<String, dynamic>?> checkoutUnit(int unitId) async {
    try {
      final data = await _api.post('/app/checkout/unit', body: {'unitId': unitId});
      if (data is Map<String, dynamic>) {
        final raw = data['purchasedUnitIds'];
        if (raw is List) {
          for (final x in raw) {
            final n = x is num ? x.toInt() : int.tryParse('$x');
            if (n != null) _ownedUnitIds.add(n);
          }
        }
        if (data['status'] == 'owned' || data['status'] == 'paid') {
          _ownedUnitIds.add(unitId);
        }
        notifyListeners();
        return data;
      }
    } catch (e) {
      return {'error': e.toString().replaceFirst('Exception: ', '')};
    }
    return null;
  }

  Future<void> markUnitOwned(int unitId) async {
    _ownedUnitIds.add(unitId);
    notifyListeners();
    await _persistLocalProgress();
  }

  /// Pull subscription status (Chapa verify / admin grant).
  Future<void> loadEntitlements() async {
    try {
      final data = await _api.get('/app/entitlements');
      if (data is Map) {
        _subscribed = data['subscribed'] == true;
        notifyListeners();
      }
    } catch (_) {}
  }

  bool _loadingLanguages = false;
  bool _loadingContent = false;
  String? _error;

  static const String _langKey = 'etlingo_language';
  static const String _baseLangKey = 'etlingo_base_language';
  static const String _appLangKey = 'etlingo_app_language';
  static const String _progressKey = 'etlingo_local_progress';
  static const String _cultureCacheKey = 'etlingo_culture_cache';
  static const String _cultureDoneKey = 'etlingo_culture_done';

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
      final res = await _content.loadLanguageContent(code);
      final full = res.language;
      _ownedUnitIds
        ..clear()
        ..addAll(res.purchasedUnitIds);
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
      final res = await _content.loadLanguageContent(code);
      final fresh = res.language;
      _ownedUnitIds
        ..clear()
        ..addAll(res.purchasedUnitIds);
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
    unawaited(loadLanguageScripts(forceRefresh: true));

    _loadingContent = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _content.loadLanguageContent(lang.id);
      final full = res.language;
      _ownedUnitIds
        ..clear()
        ..addAll(res.purchasedUnitIds);
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
    // 1) Clear on-device cache first so UI updates immediately.
    _completedLessons.clear();
    _xp = 0;
    _xpToday = 0;
    _hearts = 5;
    _streak = 0;
    notifyListeners();
    await _persistLocalProgress();

    // 2) If signed in, also wipe the server — otherwise the next login
    //    pulls the old XP/lessons back via GET /app/progress.
    if (_auth?.token != null) {
      try {
        final data = await _api.post('/app/progress/reset');
        if (data is Map<String, dynamic>) {
          _applyServerProgress(data);
          notifyListeners();
          await _persistLocalProgress();
        }
      } catch (e) {
        debugPrint('[progress] server reset failed (local kept cleared): $e');
      }
    }
  }

  /// Fetch Culture Path chapters + cards for the current course language.
  /// Caches the payload and falls back to it when offline.
  Future<List<CultureChapter>> loadCulture({bool forceRefresh = false}) async {
    final code = _language.id;
    if (code.isEmpty) return const [];
    final cacheKey = '$_cultureCacheKey:$code';
    try {
      final data = await _api.getWithOptionalAuth('/app/culture/$code');
      if (data is! Map<String, dynamic>) {
        return loadCultureCached(code);
      }
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, jsonEncode(data));
        await prefs.setBool('$_cultureCacheKey:ready:$code', true);
      } catch (_) {}
      _cultureCached[code] = true;
      _cachedCultureKeys.add(code);
      return _chaptersFromCultureJson(data);
    } catch (e) {
      debugPrint('[culture] load failed: $e');
      return loadCultureCached(code);
    }
  }

  final Map<String, bool> _cultureCached = {};
  final Set<String> _cachedCultureKeys = {};

  bool isCultureCached(String code) =>
      _cultureCached[code] == true || _cachedCultureKeys.contains(code);

  Future<void> ensureCultureCacheFlags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final k in prefs.getKeys()) {
        if (k.startsWith('$_cultureCacheKey:ready:')) {
          final code = k.split(':').last;
          if (prefs.getBool(k) == true) {
            _cachedCultureKeys.add(code);
            _cultureCached[code] = true;
          }
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> downloadCulturePack(String code) async {
    final ok = await loadCulture();
    final cached = ok.isNotEmpty;
    if (cached) {
      _cultureCached[code] = true;
      _cachedCultureKeys.add(code);
      notifyListeners();
    }
    return cached;
  }

  Future<List<CultureChapter>> loadCultureCached(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_cultureCacheKey:$code');
      if (raw == null) return const [];
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _cultureCached[code] = true;
      _cachedCultureKeys.add(code);
      return _chaptersFromCultureJson(data);
    } catch (_) {
      return const [];
    }
  }

  List<CultureChapter> _chaptersFromCultureJson(Map<String, dynamic> data) {
    final done = <String>{};
    final doneRaw = data['completedCardIds'];
    if (doneRaw is List) {
      done.addAll(doneRaw.map((e) => e.toString()));
    }
    // Merge locally completed cards (guest / offline).
    done.addAll(_localCultureDone);
    final rawCards = (data['cards'] as List?) ?? [];
    final byUnit = <int, List<CultureCardModel>>{};
    for (final raw in rawCards) {
      final m = Map<String, dynamic>.from(raw as Map);
      final uid = (m['cultureUnitId'] as num?)?.toInt() ?? 0;
      byUnit.putIfAbsent(uid, () => []).add(CultureCardModel.fromJson(m));
    }
    final rawUnits = (data['units'] as List?) ?? [];
    final out = <CultureChapter>[];
    for (final u in rawUnits) {
      final m = Map<String, dynamic>.from(u as Map);
      final uid = (m['id'] as num?)?.toInt() ?? 0;
      final unitCards = byUnit[uid] ?? const <CultureCardModel>[];
      final doneCount = unitCards.where((c) => done.contains(c.id)).length;
      out.add(CultureChapter(
        id: uid,
        title: (m['title'] ?? '').toString(),
        subtitle: (m['subtitle'] ?? '').toString(),
        theme: (m['theme'] ?? 'fact').toString(),
        color: colorFromHex(m['colorHex'], fallback: _language.color),
        dark: colorFromHex(m['darkHex'], fallback: _language.dark),
        icon: iconFromName(m['icon']?.toString()),
        cards: unitCards,
        doneCount: doneCount,
      ));
    }
    return out;
  }

  final Set<String> _localCultureDone = {};

  /// Mark a culture card complete and sync XP (sticky, like lesson progress).
  Future<int> completeCultureCard(CultureCardModel card) async {
    _localCultureDone.add(card.id);
    if (_auth?.token == null) {
      notifyListeners();
      await _persistCultureDone();
      return 0;
    }
    try {
      final data = await _api.post('/app/culture/cards/${card.id}/complete');
      final earned = data is Map ? (data['earned'] as num?)?.toInt() ?? 0 : 0;
      if (earned > 0) {
        _xp += earned;
        _xpToday += earned;
        notifyListeners();
        await _persistLocalProgress();
      }
      await _persistCultureDone();
      return earned;
    } catch (e) {
      debugPrint('[culture] complete card failed: $e');
      await _persistCultureDone();
      return 0;
    }
  }

  Future<void> _persistCultureDone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cultureDoneKey, jsonEncode(_localCultureDone.toList()));
    } catch (_) {}
  }

  Future<void> _restoreCultureDone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cultureDoneKey);
      if (raw == null) return;
      final list = jsonDecode(raw);
      if (list is List) {
        _localCultureDone
          ..clear()
          ..addAll(list.map((e) => e.toString()));
      }
    } catch (_) {}
  }

  CultureCardModel? _proverbOfDay;
  CultureCardModel? get proverbOfDay => _proverbOfDay;

  Map<String, dynamic>? _cultureCalendar;
  Map<String, dynamic>? get cultureCalendar => _cultureCalendar;

  /// Today's proverb (rotates server-side by day).
  Future<CultureCardModel?> loadProverbOfDay() async {
    final code = _language.id;
    if (code.isEmpty) return null;
    try {
      final data = await _api.getWithOptionalAuth(
          '/app/culture/proverb/$code?base=$_baseLanguage');
      if (data is Map<String, dynamic>) {
        _proverbOfDay = CultureCardModel.fromJson(data);
      } else {
        _proverbOfDay = null;
      }
      notifyListeners();
      return _proverbOfDay;
    } catch (e) {
      debugPrint('[culture] proverb failed: $e');
      return _proverbOfDay;
    }
  }

  /// Ethiopian calendar + holiday challenge context.
  Future<Map<String, dynamic>?> loadCultureCalendar() async {
    try {
      final data = await _api.getWithOptionalAuth('/app/culture/calendar');
      if (data is Map<String, dynamic>) {
        _cultureCalendar = data;
        notifyListeners();
      }
      return _cultureCalendar;
    } catch (e) {
      debugPrint('[culture] calendar failed: $e');
      return _cultureCalendar;
    }
  }

  /// Generic API helpers for community / exchange screens.
  Future<dynamic> apiGet(String path) => _api.getWithOptionalAuth(path);
  Future<dynamic> apiPost(String path, Map<String, dynamic> body) =>
      _api.post(path, body: body);

  ScriptService get _scripts => ScriptService(apiGet);

  LanguageScripts? _languageScripts;
  LanguageScripts? get languageScripts => _languageScripts;

  /// Load writing system + alphabet for the current course language (cached).
  Future<LanguageScripts?> loadLanguageScripts({bool forceRefresh = false}) async {
    final code = _language.id;
    if (code.isEmpty) return _languageScripts;
    try {
      _languageScripts =
          await _scripts.forLanguage(code, forceRefresh: forceRefresh);
      notifyListeners();
    } catch (e) {
      debugPrint('[scripts] load failed: $e');
    }
    return _languageScripts;
  }

  ScriptInfo? get primaryScript => _languageScripts?.primary;

  TopicService get _topics => TopicService(apiGet);
  TopicPack? _topicsPack;
  TopicPack? get topicsPack => _topicsPack;

  /// Theme packs (Animals, Food…) for the current language (cached offline).
  Future<TopicPack?> loadTopics({bool forceRefresh = false}) async {
    final code = _language.id;
    if (code.isEmpty) return _topicsPack;
    try {
      _topicsPack = await _topics.forLanguage(
        code,
        base: _baseLanguage,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('[topics] load failed: $e');
    }
    return _topicsPack;
  }

  /// One live ad for a placement (home_top, culture_top…).
  Future<AdBanner?> loadAd(String position) async {
    try {
      final data = await _api.getWithOptionalAuth(
        '/app/ads/slot?position=$position&lang=${_language.id}',
      );
      if (data is Map<String, dynamic>) return AdBanner.fromJson(data);
    } catch (e) {
      debugPrint('[ads] load failed: $e');
    }
    return null;
  }

  Future<void> trackAdClick(int adId) async {
    try {
      await _api.post('/app/ads/$adId/click');
    } catch (_) {}
  }

  /// Mark a topic word as known (+2 XP first time).
  Future<int> markWordKnown(int wordId) async {
    try {
      final data = await _api.post('/app/topics/words/$wordId/known');
      final earned = data is Map ? (data['earned'] as num?)?.toInt() ?? 0 : 0;
      if (earned > 0) {
        _xp += earned;
        _xpToday += earned;
        notifyListeners();
        await _persistLocalProgress();
      }
      return earned;
    } catch (e) {
      debugPrint('[topics] mark known failed: $e');
      return 0;
    }
  }

  Future<void> unmarkWordKnown(int wordId) async {
    try {
      await _api.post('/app/topics/words/$wordId/unmark');
    } catch (_) {
      try {
        await _api.post('/app/topics/words/$wordId/known');
      } catch (_) {}
    }
  }

  /// Phrasebook for the current course language.
  Future<List<Phrase>> loadPhrases() async {
    final code = _language.id;
    if (code.isEmpty) return const [];
    try {
      final data = await _api.getWithOptionalAuth('/app/$code/phrases');
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => Phrase.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      if (data is Map && data['phrases'] is List) {
        return (data['phrases'] as List)
            .whereType<Map>()
            .map((e) => Phrase.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e) {
      debugPrint('[phrases] load failed: $e');
    }
    return _language.phrases;
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
