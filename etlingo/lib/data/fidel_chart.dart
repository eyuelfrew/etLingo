import 'dart:math';

import '../services/script_service.dart';

/// Bundled Ge'ez (fidel) base letters + romanization for the trainer.
class FidelLetter {
  final String glyph;
  final String roman;
  final String sound;
  final String audioUrl;
  final String orderName;
  final int formIndex;
  const FidelLetter(this.glyph, this.roman, this.sound,
      {this.audioUrl = '', this.orderName = '', this.formIndex = 0});

  factory FidelLetter.fromScript(ScriptLetter l) => FidelLetter(
        l.glyph,
        l.roman.isNotEmpty ? l.roman : l.name,
        l.sound.isNotEmpty
            ? l.sound
            : (l.roman.isNotEmpty ? l.roman : l.name),
        audioUrl: l.audioUrl,
        orderName: l.orderName,
        formIndex: l.formIndex,
      );

  bool get hasAudio => audioUrl.isNotEmpty;
  String get familyKey => orderName.isNotEmpty ? orderName : glyph;
}

class FidelChart {
  /// Vowel-order labels for Ge'ez families (form_index 0..6).
  static const formLabels = [
    '1st · ä',
    '2nd · u',
    '3rd · i',
    '4th · a',
    '5th · e',
    '6th · ə',
    '7th · o',
    '8th · wa',
  ];

  /// Seven orders × forms are simplified to base (hä) letters for practice.
  static const List<FidelLetter> bases = [
    FidelLetter('ሀ', 'hä', 'ha'),
    FidelLetter('ለ', 'lä', 'la'),
    FidelLetter('ሐ', 'ḥä', 'hha'),
    FidelLetter('መ', 'mä', 'ma'),
    FidelLetter('ሠ', 'śä', 'sha'),
    FidelLetter('ረ', 'rä', 'ra'),
    FidelLetter('ሰ', 'sä', 'sa'),
    FidelLetter('ሸ', 'šä', 'sh'),
    FidelLetter('ቀ', 'qä', 'qa'),
    FidelLetter('በ', 'bä', 'ba'),
    FidelLetter('ቨ', 'vä', 'va'),
    FidelLetter('ተ', 'tä', 'ta'),
    FidelLetter('ቸ', 'čä', 'ch'),
    FidelLetter('ኀ', 'ḫä', 'hha2'),
    FidelLetter('ነ', 'nä', 'na'),
    FidelLetter('ኘ', 'ñä', 'nya'),
    FidelLetter('አ', 'ʾä', 'a'),
    FidelLetter('ከ', 'kä', 'ka'),
    FidelLetter('ኸ', 'xä', 'xa'),
    FidelLetter('ወ', 'wä', 'wa'),
    FidelLetter('ዐ', 'ʿä', 'aa'),
    FidelLetter('ዘ', 'zä', 'za'),
    FidelLetter('ዠ', 'žä', 'zha'),
    FidelLetter('የ', 'yä', 'ya'),
    FidelLetter('ደ', 'dä', 'da'),
    FidelLetter('ጀ', 'jä', 'ja'),
    FidelLetter('ገ', 'gä', 'ga'),
    FidelLetter('ጠ', 'ṭä', 'tha'),
    FidelLetter('ጨ', 'č̣ä', 'cha'),
    FidelLetter('ጰ', 'p̣ä', 'pha'),
    FidelLetter('ጸ', 'ṣä', 'tsa'),
    FidelLetter('ፀ', 'ṣ́ä', 'tsha'),
    FidelLetter('ፈ', 'fä', 'fa'),
    FidelLetter('ፐ', 'pä', 'pa'),
  ];

  /// Prefer admin-managed letters; fall back to bundled chart.
  static List<FidelLetter> resolve(List<ScriptLetter> remote) {
    if (remote.isEmpty) return bases;
    return remote.map(FidelLetter.fromScript).toList();
  }

  /// Group letters into families by `orderName` (e.g. all ሀ-row forms).
  /// Family order follows each family's lowest `sortOrder` (admin drag order).
  static List<LetterFamily> groupFamilies(List<ScriptLetter> letters) {
    final map = <String, List<ScriptLetter>>{};
    for (final l in letters) {
      final key = l.orderName.isEmpty ? l.glyph : l.orderName;
      map.putIfAbsent(key, () => []).add(l);
    }
    final keys = map.keys.toList()
      ..sort((a, b) {
        final aMin = map[a]!.map((l) => l.sortOrder).reduce((x, y) => x < y ? x : y);
        final bMin = map[b]!.map((l) => l.sortOrder).reduce((x, y) => x < y ? x : y);
        if (aMin != bMin) return aMin.compareTo(bMin);
        return a.compareTo(b);
      });
    return keys.map((k) {
      final members = [...map[k]!]
        ..sort((a, b) {
          if (a.formIndex != b.formIndex) {
            return a.formIndex.compareTo(b.formIndex);
          }
          return a.sortOrder.compareTo(b.sortOrder);
        });
      return LetterFamily(key: k, letters: members);
    }).toList();
  }

  /// Filter a quiz pool to one family (for “whole family” practice).
  static List<FidelLetter> familyPool(List<FidelLetter> all, String familyKey) {
    return all.where((l) => l.roman.startsWith(familyKey) || l.sound.startsWith(familyKey)).toList();
  }

  static FidelLetter random(List<FidelLetter> pool, [Random? rng]) {
    final r = rng ?? Random();
    if (pool.isEmpty) return bases[r.nextInt(bases.length)];
    return pool[r.nextInt(pool.length)];
  }

  /// n distinct distractors + the correct letter, shuffled.
  /// If [sameFamily], distractors come from the same family (harder).
  static List<FidelLetter> quizOptions(
    FidelLetter correct,
    List<FidelLetter> pool, {
    int n = 3,
    bool sameFamily = false,
    Random? rng,
  }) {
    final r = rng ?? Random();
    final source = pool.isEmpty ? bases : pool;
    List<FidelLetter> candidates = source;
    if (sameFamily && correct.orderName.isNotEmpty) {
      final fam = source
          .where((e) => e.orderName == correct.orderName)
          .toList();
      if (fam.length > n) candidates = fam;
    }
    final rest = List<FidelLetter>.of(candidates)
      ..removeWhere((e) => e.glyph == correct.glyph)
      ..shuffle(r);
    final picks = rest.take(n).toList();
    if (picks.length < n) {
      final extra = List<FidelLetter>.of(source)
        ..removeWhere(
            (e) => e.glyph == correct.glyph || picks.any((p) => p.glyph == e.glyph))
        ..shuffle(r);
      picks.addAll(extra.take(n - picks.length));
    }
    return [correct, ...picks]..shuffle(r);
  }

  /// Letters that share the same family (ሀ ሁ ሂ ሃ ሄ ህ ሆ…).
  static List<FidelLetter> familyOf(FidelLetter letter, List<FidelLetter> pool) {
    if (letter.orderName.isEmpty) return [letter];
    return pool.where((l) => l.orderName == letter.orderName).toList()
      ..sort((a, b) => a.formIndex.compareTo(b.formIndex));
  }
}

class LetterFamily {
  final String key;
  final List<ScriptLetter> letters;
  const LetterFamily({required this.key, required this.letters});

  ScriptLetter get head => letters.first;
  String get sample => letters.map((l) => l.glyph).join('');
}
