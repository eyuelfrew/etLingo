import 'package:flutter/material.dart';

/// Bilingual product chrome (nav, buttons, empty states).
/// Learning content still follows the learner's base language.
class EtStrings {
  static String _lang = 'en';

  static String get lang => _lang;
  static bool get isAmharic => _lang == 'am';

  static void setLang(String code) {
    _lang = (code == 'am') ? 'am' : 'en';
  }

  static String _t(String en, String am) => _lang == 'am' ? am : en;

  // Brand
  static String get brand => 'ኢትLang';
  static String get brandTagline =>
      _t('Learn the languages of Ethiopia', 'የኢትዮጵያ ቋንቋዎችን ይማሩ');
  static String get languagesLine =>
      'አማርኛ · Afaan Oromoo · ትግርኛ · Soomaali';

  // Nav
  static String get tabLearn => _t('Learn', 'ተምር');
  static String get tabWords => _t('Words', 'ቃላት');
  static String get tabRank => _t('Rank', 'ደረጃ');
  static String get tabYou => _t('You', 'እርስዎ');

  // Learn path
  static String get wordOfDay => _t('Word of the day', 'የቀን ቃል');
  static String get dailyGoal => _t('Daily goal', 'ዕለታዊ ግብ');
  static String get xp => 'XP';
  static String get hearts => _t('Hearts', 'ልቦች');
  static String get streak => _t('Day streak', 'ቀናት');
  static String get start => _t('START', 'ጀምር');
  static String get learn => _t('LEARN', 'ተምር');
  static String get boss => _t('Boss', 'ሙከራ');
  static String get unit => _t('Unit', 'ክፍል');
  static String get course => _t('Course', 'ትምህርት');
  static String get slowMotto => _t('Slowly by slowly', 'ቀስ በቀስ');
  static String get noContentYet => _t(
        'This lesson is still being prepared — it will arrive soon!',
        'ይህ ትምህርት እየተዘጋጀ ነው — በቅርቡ ይመጣል!',
      );
  static String get pullToRefresh => _t('Pull to refresh', 'ለማደስ ይጎትቱ');

  // Lesson
  static String get check => _t('Check', 'አረጋግጥ');
  static String get continueLabel => _t('Continue', 'ቀጥል');
  static String get gotIt => _t('Got it →', 'ተረድቻለሁ →');
  static String get startQuiz => _t('Start quiz', 'ፈተና ጀምር');
  static String get perfect => _t('Perfect!', 'ጎበዝ!');
  static String get perfectSub => _t(
        'Zero mistakes — nicely done!',
        'ስህተት የለም — እንደሚታመን!',
      );
  static String get lessonDone => _t('Lesson complete!', 'ትምህርቱ ተጠናቋል!');
  static String get keepGoing => _t('Keep going', 'ቀጥሎ ይማሩ');
  static String get leaveLesson => _t('Leave lesson?', 'ትምህርቱን ላቆይ?');
  static String get leaveLessonBody => _t(
        'Progress in this lesson will be lost.',
        'በዚህ ትምህርት ውስጥ ያለው እድገት ይጠፋል።',
      );
  static String get keepLearning => _t('Keep learning', 'መማር አቀጥል');
  static String get quit => _t('Quit', 'ውጣ');
  static String get outOfHearts => _t('Out of hearts!', 'ልቦች ተጠፍተዋል!');
  static String get refillHearts => _t('Refill hearts ♥', 'ልቦችን ሞላ ♥');
  static String get correct => _t('Perfect!', 'ጎበዝ!');
  static String get notQuite => _t('Not quite…', 'አልተሳካም…');
  static String get correctAnswer => _t('Correct answer', 'ትክክለኛው መልስ');
  static String get noQuestions => _t('No questions yet', 'ጥያቄዎች አልተዘጋጁም');
  static String get tapToListen => _t('Tap to listen', 'ለማዳመጥ ይንኩ');
  static String get swipeNext => _t('Swipe for the next word', 'ቀጥሎ ለማየት ይጎትቱ');
  static String get readyQuiz =>
      _t('Ready to test what you learned?', 'የተማሩትን ለመፈተሽ ዝግጁ ነዎት?');

  // Teaching
  static String get newWords => _t('New words', 'አዲስ ቃላት');
  static String get listen => _t('Listen', 'አዳምጥ');

  // Phrasebook
  static String get phrasebook => _t('Phrasebook', 'የቃላት መጠቈለያ');
  static String get phrasebookSub =>
      _t('Every word in your pocket', 'ቃላት በኪስዎ ውስጥ');
  static String get searchWords => _t('Search words…', 'ቃላት ፈልግ…');
  static String get practiceAloud =>
      _t('Practice out loud · 🎙', 'ከመምህሩ ጋር በድጋሚ ይናገሩ · 🎙');

  // Rank
  static String get goldLeague => _t('Gold League', 'ወርቅ ሊግ');
  static String get yourRank => _t('Your rank', 'የእርስዎ ደረጃ');
  static String get you => _t('You', 'እርስዎ');

  // Profile
  static String get profile => _t('Profile', 'መገለጫ');
  static String get yourName => _t('Your name', 'የእርስዎ ስም');
  static String get nameHint => _t('How should we call you?', 'እንዴት ልንጽልዎት?');
  static String get save => _t('Save', 'አስቀምጥ');
  static String get cancel => _t('Cancel', 'ሰርዝ');
  static String get signOut => _t('Sign out', 'ውጣ');
  static String get signOutQ => _t('Sign out?', 'ለመውጣት?');
  static String get progressSaved => _t(
        'Your progress is saved on the server and will be here when you return.',
        'እድገትዎ በሰርቨሩ ላይ ይቀመጣል — በተመለሱ ጊዜ እዚሁ ይገኛል።',
      );
  static String get resetProgress => _t('Reset progress', 'እድገትን ዳግም አስጀምር');
  static String get notifications => _t('Notifications', 'ማሳወቂያዎች');
  static String get notificationSettings =>
      _t('Notification settings', 'የማሳወቂያ ቅንብሮች');
  static String get switchCourse => _t('Switch course', 'ትምህርት ቀይር');
  static String get baseLanguage => _t('Base language', 'የማስታወሻ ቋንቋ');
  static String get appLanguage => _t('App language', 'የአፕ ቋንቋ');
  static String get appLanguageHint => _t(
        'Interface language for menus and buttons',
        'የምናሌና ቁልፎች ቋንቋ',
      );
  static String get achievements => _t('Achievements', 'ስኬቶች');
  static String get badges => _t('Badges', 'ሜዳልያዎች');
  static String get settingsTitle => _t('SETTINGS', 'ቅንብሮች');

  // Auth / onboarding
  static String get welcome => _t('Welcome!', 'እንኳን ደህና መጡ!');
  static String get pickLanguage => _t(
        'Which Ethiopian language do you want to learn?',
        'የትኛውን የኢትዮጵያ ቋንቋ መማር ይፈልጋሉ?',
      );
  static String get pickLanguageSub => _t(
        'Learn using the language you already know.',
        'የሚያውቁትን ቋንቋ ተጠቀም ይማሩ።',
      );
  static String get signInGoogle => _t('Continue with Google', 'በ Google ይግቡ');
  static String get continueAsGuest =>
      _t('Or continue as guest', 'ወይም እንደ እንግዳ ይቀጥሉ');
  static String get signInTitle => _t('Start your journey', 'ጉዞዎን ይጀምሩ');
  static String get signInSub => _t(
        'Sign in to save progress — or try as a guest.',
        'እድገትዎን ለማስቀመጥ ይግቡ — ወይም እንደ እንግዳ ይሞክሩ።',
      );
  static String get retry => _t('Retry', 'እንደገና ሞክር');
  static String get noLanguages => _t('No languages available yet', 'ምንም ቋንቋ አልተገኘም');
  static String get needApi => _t(
        'Cannot reach the server. Please try again.',
        'ሰርቨሩ አልተገኘም። እባክዎ እንደገና ይሞክሩ።',
      );
  static String get chooseBase => _t(
        'Language you already speak',
        'የሚያውቁት ቋንቋ',
      );
  static String get chooseBaseSub => _t(
        'Prompts and meanings appear in this language',
        'ትርጉሞች በዚህ ቋንቋ ይታያሉ',
      );

  // Misc
  static String get emptyPhrasebook => _t('No phrases yet', 'ቃላት አልተገኙም');
  static String get emptyNotifications => _t('No notifications', 'ማሳወቂያ የለም');
  static String get goalComplete => _t('Daily goal complete!', 'ዕለታዊ ግብ ተጠናቋል!');
  static String get xpEarned => _t('XP earned', 'የተገኘ XP');
  static String get dayStreak => _t('Day streak', 'ቀን ተከታታይ');
  static String get lessonsDone => _t('Lessons done', 'የተጠናቁ ትምህርቶች');
  static String get guestLearner => _t('Guest learner', 'እንግዳ ተማሪ');
  static String get signInToSave =>
      _t('Sign in to save your progress', 'እድገትዎን ለማስቀመጥ ይግቡ');
  static String get baseSetTo => _t('Base language set to', 'የማስታወሻ ቋንቋ');
  static String get appLangSetTo => _t('App language set to', 'የአፕ ቋንቋ ተቀይሯል');
}

/// Convenience alias used across screens.
typedef EtS = EtStrings;

ThemeData unusedThemeGuard() => ThemeData();
