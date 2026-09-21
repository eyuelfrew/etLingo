import 'package:flutter/material.dart';

enum QuestionKind { mcq, match, fill, listen }

/// Instruction language option (what the learner already speaks).
class BaseLanguageOption {
  final String code;
  final String name;
  final String nativeName;

  const BaseLanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
  });

  factory BaseLanguageOption.fromJson(Map<String, dynamic> j) {
    final code = (j['id'] ?? j['code'] ?? '').toString();
    return BaseLanguageOption(
      code: code,
      name: (j['name'] ?? code).toString(),
      nativeName: (j['nativeName'] ?? j['native_name'] ?? j['name'] ?? code)
          .toString(),
    );
  }

  static const List<BaseLanguageOption> defaults = [
    BaseLanguageOption(code: 'en', name: 'English', nativeName: 'English'),
    BaseLanguageOption(code: 'am', name: 'Amharic', nativeName: 'አማርኛ'),
    BaseLanguageOption(code: 'om', name: 'Afaan Oromoo', nativeName: 'Afaan Oromoo'),
    BaseLanguageOption(code: 'ti', name: 'Tigrinya', nativeName: 'ትግርኛ'),
    BaseLanguageOption(code: 'so', name: 'Somali', nativeName: 'Soomaali'),
  ];
}

/// Maps admin-managed icon names (e.g. 'waving_hand_rounded') to Material icons.
IconData iconFromName(String? name) {
  const icons = <String, IconData>{
    'waving_hand_rounded': Icons.waving_hand_rounded,
    'menu_book_rounded': Icons.menu_book_rounded,
    'school_rounded': Icons.school_rounded,
    'sailing_rounded': Icons.sailing_rounded,
    'coffee_rounded': Icons.coffee_rounded,
    'music_note_rounded': Icons.music_note_rounded,
    'landscape_rounded': Icons.landscape_rounded,
    'flag_rounded': Icons.flag_rounded,
    'star_rounded': Icons.star_rounded,
    'chat_bubble_rounded': Icons.chat_bubble_rounded,
    'restaurant_rounded': Icons.restaurant_rounded,
    'home_rounded': Icons.home_rounded,
    'shopping_bag_rounded': Icons.shopping_bag_rounded,
    'directions_bus_rounded': Icons.directions_bus_rounded,
    'favorite_rounded': Icons.favorite_rounded,
  };
  return icons[name] ?? Icons.waving_hand_rounded;
}

Color colorFromHex(dynamic hex, {Color fallback = const Color(0xFF078930)}) {
  if (hex is! String || hex.length < 7) return fallback;
  final value = int.tryParse(hex.substring(1, 7), radix: 16);
  if (value == null) return fallback;
  return Color(0xFF000000 | value);
}

class WordOption {
  final String label;
  final String? emoji;
  const WordOption(this.label, {this.emoji});

  factory WordOption.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return WordOption(
        (json['label'] ?? '').toString(),
        emoji: json['emoji']?.toString(),
      );
    }
    return WordOption(json.toString());
  }
}

class TeachItem {
  final String target;
  final String translit;
  final String meaning;
  final Map<String, String> meanings;
  final String audioUrl;
  const TeachItem({
    required this.target,
    this.translit = '',
    this.meaning = '',
    this.meanings = const {},
    this.audioUrl = '',
  });

  String meaningFor(String baseLang) {
    if (meanings.containsKey(baseLang) && meanings[baseLang]!.isNotEmpty) {
      return meanings[baseLang]!;
    }
    return meaning;
  }

  factory TeachItem.fromJson(Map<String, dynamic> j) {
    final rawMeanings = j['meanings'];
    final meanings = <String, String>{};
    if (rawMeanings is Map) {
      for (final entry in rawMeanings.entries) {
        meanings[entry.key.toString()] = entry.value?.toString() ?? '';
      }
    }
    return TeachItem(
      target: (j['target'] ?? '').toString(),
      translit: (j['translit'] ?? '').toString(),
      meaning: (j['meaning'] ?? '').toString(),
      meanings: meanings,
      audioUrl: (j['audioUrl'] ?? '').toString(),
    );
  }
}

class Question {
  final QuestionKind kind;
  final String prompt;
  final String subPrompt;
  final String hint;
  final Map<String, dynamic> content;
  final List<WordOption> options;
  final int answerIndex;
  final List<String> matchLeft;
  final List<String> matchRight;
  final String audioUrl;

  const Question({
    required this.kind,
    required this.prompt,
    this.subPrompt = '',
    this.hint = '',
    this.content = const {},
    this.options = const [],
    this.answerIndex = -1,
    this.matchLeft = const [],
    this.matchRight = const [],
    this.audioUrl = '',
  });

  /// Returns the prompt for a given base language, falling back to the default prompt.
  String promptFor(String baseLang) {
    final lc = content[baseLang];
    if (lc is Map && (lc['prompt']?.toString().isNotEmpty ?? false)) {
      return lc['prompt'].toString();
    }
    return prompt;
  }

  /// Returns the subPrompt for a given base language.
  String subPromptFor(String baseLang) {
    final lc = content[baseLang];
    if (lc is Map && (lc['subPrompt']?.toString().isNotEmpty ?? false)) {
      return lc['subPrompt'].toString();
    }
    return subPrompt;
  }

  /// Returns the hint for a given base language.
  String hintFor(String baseLang) {
    final lc = content[baseLang];
    if (lc is Map && (lc['hint']?.toString().isNotEmpty ?? false)) {
      return lc['hint'].toString();
    }
    return hint;
  }

  const Question.mcq({
    required this.prompt,
    this.subPrompt = '',
    this.hint = '',
    this.content = const {},
    required this.options,
    required this.answerIndex,
    this.audioUrl = '',
  }) : kind = QuestionKind.mcq,
       matchLeft = const [],
       matchRight = const [];

  const Question.fill({
    required this.prompt,
    required this.subPrompt,
    this.content = const {},
    required this.options,
    required this.answerIndex,
    this.audioUrl = '',
  }) : kind = QuestionKind.fill,
       hint = '',
       matchLeft = const [],
       matchRight = const [];

  const Question.match({
    required this.prompt,
    this.content = const {},
    required this.matchLeft,
    required this.matchRight,
    this.audioUrl = '',
  }) : kind = QuestionKind.match,
       subPrompt = '',
       hint = '',
       options = const [],
       answerIndex = -1;

  factory Question.fromJson(Map<String, dynamic> j) {
    final kindStr = (j['kind'] ?? 'mcq').toString();
    final kind = QuestionKind.values.firstWhere(
      (k) => k.name == kindStr,
      orElse: () => QuestionKind.mcq,
    );
    List<String> stringList(dynamic v) =>
        v is List ? v.map((e) => e.toString()).toList() : <String>[];

    // Parse content map
    final rawContent = j['content'];
    final contentMap = <String, dynamic>{};
    if (rawContent is Map) {
      for (final entry in rawContent.entries) {
        contentMap[entry.key.toString()] = entry.value;
      }
    }

    return Question(
      kind: kind,
      prompt: (j['prompt'] ?? '').toString(),
      subPrompt: (j['subPrompt'] ?? '').toString(),
      hint: (j['hint'] ?? '').toString(),
      content: contentMap,
      options: j['options'] is List
          ? (j['options'] as List).map(WordOption.fromJson).toList()
          : const <WordOption>[],
      answerIndex:
          j['answerIndex'] is num ? (j['answerIndex'] as num).toInt() : -1,
      matchLeft: stringList(j['matchLeft']),
      matchRight: stringList(j['matchRight']),
      audioUrl: (j['audioUrl'] ?? '').toString(),
    );
  }
}

class Lesson {
  final String id;
  final String title;
  final bool isBoss;
  final int xpReward;
  final List<Question> questions;
  final List<TeachItem> teachItems;
  const Lesson(
    this.id,
    this.title, {
    this.isBoss = false,
    this.xpReward = 10,
    required this.questions,
    this.teachItems = const [],
  });

  factory Lesson.fromJson(Map<String, dynamic> j, {required List<Question> questions}) {
    final rawTeach = j['teachContent'];
    final teachItems = rawTeach is List
        ? rawTeach.map((e) => TeachItem.fromJson(e as Map<String, dynamic>)).toList()
        : const <TeachItem>[];
    return Lesson(
      (j['id'] ?? '').toString(),
      (j['title'] ?? '').toString(),
      isBoss: j['isBoss'] == true || j['isBoss'] == 1,
      xpReward: (j['xpReward'] is num) ? (j['xpReward'] as num).toInt() : 10,
      questions: questions,
      teachItems: teachItems,
    );
  }
}

class Unit {
  final String title;
  final String subtitle;
  final Color color;
  final Color dark;
  final IconData icon;
  final List<Lesson> lessons;
  final List<TeachItem> teachItems;
  const Unit({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.dark,
    required this.icon,
    required this.lessons,
    this.teachItems = const [],
  });

  factory Unit.fromJson(Map<String, dynamic> j, {required List<Lesson> lessons}) {
    final rawTeach = j['teachContent'] ?? j['teach_content'];
    final teachItems = rawTeach is List
        ? rawTeach
            .whereType<Map>()
            .map((e) => TeachItem.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : const <TeachItem>[];
    return Unit(
      title: (j['title'] ?? '').toString(),
      subtitle: (j['subtitle'] ?? '').toString(),
      color: colorFromHex(j['colorHex']),
      dark: colorFromHex(j['darkHex'], fallback: const Color(0xFF056B24)),
      icon: iconFromName(j['icon']?.toString()),
      lessons: lessons,
      teachItems: teachItems,
    );
  }

  /// Chapter vocab + any lesson-only extras, de-duplicated by target word.
  List<TeachItem> teachItemsFor(Lesson lesson) {
    final seen = <String>{};
    final out = <TeachItem>[];
    for (final item in [...teachItems, ...lesson.teachItems]) {
      final key = item.target.trim();
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      out.add(item);
    }
    return out;
  }
}

class Phrase {
  final String target;
  final String translit;
  final String meaning;
  final String category;
  final String audioUrl;
  const Phrase(this.target, this.translit, this.meaning, this.category,
      {this.audioUrl = ''});

  factory Phrase.fromJson(Map<String, dynamic> j) {
    return Phrase(
      (j['target'] ?? '').toString(),
      (j['translit'] ?? '').toString(),
      (j['meaning'] ?? '').toString(),
      (j['category'] ?? 'Basics').toString(),
      audioUrl: (j['audioUrl'] ?? j['audio_url'] ?? '').toString(),
    );
  }
}

class Language {
  final String id;
  final String name;
  final String nativeName;
  final String scriptPreview;
  final String speakers;
  final String region;
  final Color color;
  final Color dark;
  final IconData icon;
  final bool comingSoon;
  final String helloTarget;
  final String helloMeaning;
  final List<Unit> units;
  final List<Phrase> phrases;

  const Language({
    required this.id,
    required this.name,
    required this.nativeName,
    required this.scriptPreview,
    required this.speakers,
    required this.region,
    required this.color,
    required this.dark,
    required this.icon,
    this.comingSoon = false,
    required this.helloTarget,
    required this.helloMeaning,
    required this.units,
    required this.phrases,
  });

  /// Metadata-only language (used for the picker before content is loaded).
  factory Language.summaryJson(Map<String, dynamic> j) {
    return Language(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      nativeName: (j['nativeName'] ?? '').toString(),
      scriptPreview: (j['scriptPreview'] ?? '').toString(),
      speakers: (j['speakers'] ?? '').toString(),
      region: (j['region'] ?? '').toString(),
      color: colorFromHex(j['colorHex']),
      dark: colorFromHex(j['darkHex'], fallback: const Color(0xFF056B24)),
      icon: iconFromName(j['icon']?.toString()),
      helloTarget: (j['helloTarget'] ?? '').toString(),
      helloMeaning: (j['helloMeaning'] ?? '').toString(),
      units: const [],
      phrases: const [],
    );
  }

  /// Full language incl. units/lessons/questions/phrases from `/app/bootstrap/:code`.
  factory Language.fullJson(
    Map<String, dynamic> lang,
    List<dynamic> unitList,
    List<dynamic> lessonList,
    List<dynamic> questionList,
    List<dynamic> phraseList,
  ) {
    final summary = Language.summaryJson(lang);

    // Group questions under their lesson, then lessons under their unit.
    final questionsByLesson = <String, List<Question>>{};
    for (final raw in questionList) {
      final q = raw as Map<String, dynamic>;
      final lessonId = (q['lessonId'] ?? '').toString();
      questionsByLesson.putIfAbsent(lessonId, () => []).add(Question.fromJson(q));
    }
    final lessonsByUnit = <String, List<Lesson>>{};
    for (final raw in lessonList) {
      final l = raw as Map<String, dynamic>;
      final lessonId = (l['id'] ?? '').toString();
      final unitId = (l['unitId'] ?? '').toString();
      lessonsByUnit
          .putIfAbsent(unitId, () => [])
          .add(Lesson.fromJson(l, questions: questionsByLesson[lessonId] ?? const []));
    }

    final units = unitList.map((raw) {
      final map = raw as Map<String, dynamic>;
      final unitId = (map['id'] ?? '').toString();
      return Unit.fromJson(map, lessons: lessonsByUnit[unitId] ?? const []);
    }).toList();

    return Language(
      id: summary.id,
      name: summary.name,
      nativeName: summary.nativeName,
      scriptPreview: summary.scriptPreview.isEmpty
          ? summary.helloTarget
          : summary.scriptPreview,
      speakers: summary.speakers,
      region: summary.region,
      color: summary.color,
      dark: summary.dark,
      icon: summary.icon,
      helloTarget: summary.helloTarget,
      helloMeaning: summary.helloMeaning,
      units: units,
      phrases: phraseList
          .map((p) => Phrase.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  int get totalLessons =>
      units.fold(0, (sum, u) => sum + u.lessons.length);
}
