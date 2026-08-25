import 'package:flutter/material.dart';
import 'models.dart';

const amharic = Language(
  id: 'am',
  name: 'Amharic',
  nativeName: 'አማርኛ',
  scriptPreview: 'ሀ ለ ሐ መ ሠ ረ ሰ',
  speakers: '57M+',
  region: 'Addis Ababa & Highlands',
  color: Color(0xFF078930),
  dark: Color(0xFF056B24),
  icon: Icons.waving_hand_rounded,
  helloTarget: 'ሰላም',
  helloMeaning: 'Selam · Hello / Peace',
  units: [
    Unit(
      title: 'Unit 1 · ሰላም Greetings',
      subtitle: 'Say hello like a habesha',
      color: Color(0xFF078930),
      dark: Color(0xFF056B24),
      icon: Icons.waving_hand_rounded,
      lessons: [
        Lesson('am_u1_l1', 'First words', questions: [
          Question.mcq(
            prompt: "Which one means 'Hello'?",
            options: [
              WordOption('ሰላም'),
              WordOption('ውሃ'),
              WordOption('ቡና'),
              WordOption('ቤት'),
            ],
            answerIndex: 0,
          ),
          Question.mcq(
            prompt: 'What does this word mean?',
            subPrompt: 'ሰላም',
            hint: 'se·lam',
            options: [
              WordOption('Peace / Hello'),
              WordOption('Water'),
              WordOption('Coffee'),
              WordOption('House'),
            ],
            answerIndex: 0,
          ),
          Question.match(
            prompt: 'Match the pairs',
            matchLeft: ['ሰላም', 'አመሰግናለሁ', 'ደህና ሁን'],
            matchRight: ['Hello', 'Thank you', 'Goodbye'],
          ),
          Question.fill(
            prompt: "'Thank you' in Amharic",
            subPrompt: 'Thank you → ___',
            options: [
              WordOption('አመሰግናለሁ'),
              WordOption('ደህና ሁን'),
              WordOption('እንዴት ነህ'),
            ],
            answerIndex: 0,
          ),
        ]),
        Lesson('am_u1_l2', 'How are you?', questions: [
          Question.mcq(
            prompt: "Ask a friend 'How are you?' (to a man)",
            options: [
              WordOption('እንዴት ነህ?'),
              WordOption('ሰላም?'),
              WordOption('ውሃ?'),
              WordOption('ኢትዮጵያ?'),
            ],
            answerIndex: 0,
          ),
          Question.mcq(
            prompt: 'What does it mean?',
            subPrompt: 'ደህና ነኝ',
            hint: 'deh·na negn',
            options: [
              WordOption('I am fine'),
              WordOption('I am leaving'),
              WordOption('My name is...'),
              WordOption('Good night'),
            ],
            answerIndex: 0,
          ),
          Question.match(
            prompt: 'Match the pairs',
            matchLeft: ['እንዴት ነህ?', 'ደህና ነኝ', 'ስሜ ... ነው'],
            matchRight: ['How are you?', 'I am fine', 'My name is...'],
          ),
          Question.fill(
            prompt: 'Reply to እንዴት ነህ? with "I am fine"',
            subPrompt: 'I am fine → ___',
            options: [
              WordOption('ደህና ነኝ'),
              WordOption('ደህና ሁን'),
              WordOption('አመሰግናለሁ'),
            ],
            answerIndex: 0,
          ),
        ]),
        Lesson('am_u1_l3', 'Unit 1 review', isBoss: true, questions: [
          Question.mcq(
            prompt: 'Which one is a morning greeting?',
            subPrompt: 'እንደምን አደሩ?',
            hint: 'in·de·min a·de·ru',
            options: [
              WordOption('Good morning'),
              WordOption('Good night'),
              WordOption('Goodbye'),
              WordOption('Water'),
            ],
            answerIndex: 0,
          ),
          Question.match(
            prompt: 'Big review — match them all',
            matchLeft: ['ሰላም', 'እንዴት ነህ?', 'አመሰግናለሁ', 'ደህና ሁን'],
            matchRight: ['Hello', 'How are you?', 'Thank you', 'Goodbye'],
          ),
          Question.fill(
            prompt: 'Goodbye in Amharic',
            subPrompt: 'Goodbye → ደህና ___',
            options: [WordOption('ሁን'), WordOption('ነኝ'), WordOption('ነህ')],
            answerIndex: 0,
          ),
        ]),
      ],
    ),
    Unit(
      title: 'Unit 2 · ቡና Coffee & Food',
      subtitle: 'From the birthplace of coffee',
      color: Color(0xFFF7C60A),
      dark: Color(0xFFC99E00),
      icon: Icons.local_cafe_rounded,
      lessons: [
        Lesson('am_u2_l1', 'Coffee ceremony', questions: [
          Question.mcq(
            prompt: "Ethiopia gave the world this drink. Which one is 'Coffee'?",
            options: [
              WordOption('ቡና'),
              WordOption('ውሃ'),
              WordOption('ሻይ'),
              WordOption('እንጀራ'),
            ],
            answerIndex: 0,
          ),
          Question.mcq(
            prompt: 'What does it mean?',
            subPrompt: 'ውሃ',
            hint: 'wih·a',
            options: [WordOption('Water'), WordOption('Milk'), WordOption('Tea'), WordOption('Bread')],
            answerIndex: 0,
          ),
          Question.match(
            prompt: 'Match the pairs',
            matchLeft: ['ቡና', 'ውሃ', 'ሻይ'],
            matchRight: ['Coffee', 'Water', 'Tea'],
          ),
          Question.fill(
            prompt: 'Coffee in Amharic',
            subPrompt: 'Coffee → ___',
            options: [WordOption('ቡና'), WordOption('ሻይ'), WordOption('ውሃ')],
            answerIndex: 0,
          ),
        ]),
        Lesson('am_u2_l2', 'Injera time', questions: [
          Question.mcq(
            prompt: 'What is እንጀራ (injera)?',
            subPrompt: 'እንጀራ',
            hint: 'in·je·ra',
            options: [
              WordOption('Sour flat bread'),
              WordOption('A drink'),
              WordOption('An animal'),
              WordOption('A city'),
            ],
            answerIndex: 0,
          ),
          Question.mcq(
            prompt: 'Which one is TEA?',
            options: [
              WordOption('ሻይ'),
              WordOption('ቡና'),
              WordOption('ውሃ'),
              WordOption('እንጀራ'),
            ],
            answerIndex: 0,
          ),
          Question.fill(
            prompt: 'Order water politely: "Water, please"',
            subPrompt: 'Water please → ውሃ ___',
            options: [WordOption('እባክህ'), WordOption('ሰላም'), WordOption('ደህና')],
            answerIndex: 0,
          ),
        ]),
      ],
    ),
    Unit(
      title: 'Unit 3 · ቁጥሮች Numbers',
      subtitle: 'Count to five at the market',
      color: Color(0xFF0F47AF),
      dark: Color(0xFF0B3685),
      icon: Icons.tag_rounded,
      lessons: [
        Lesson('am_u3_l1', 'One, two, three', questions: [
          Question.mcq(
            prompt: "Which means 'One'?",
            options: [WordOption('አንድ'), WordOption('ሁለት'), WordOption('ሶስት'), WordOption('አራት')],
            answerIndex: 0,
          ),
          Question.mcq(
            prompt: 'What does it mean?',
            subPrompt: 'ሶስት',
            hint: 'sost',
            options: [WordOption('Three'), WordOption('Two'), WordOption('Five'), WordOption('Ten')],
            answerIndex: 0,
          ),
          Question.match(
            prompt: 'Match the numbers',
            matchLeft: ['አንድ', 'ሁለት', 'ሶስት'],
            matchRight: ['One', 'Two', 'Three'],
          ),
          Question.fill(
            prompt: '"Two coffees, please" — pick Two',
            subPrompt: '___ ቡና እባክህ',
            options: [WordOption('ሁለት'), WordOption('አንድ'), WordOption('ሶስት')],
            answerIndex: 0,
          ),
        ]),
        Lesson('am_u3_l2', 'Four and five', questions: [
          Question.mcq(
            prompt: "Which means 'Five'?",
            options: [WordOption('አምስት'), WordOption('አራት'), WordOption('አንድ'), WordOption('ሶስት')],
            answerIndex: 0,
          ),
          Question.mcq(
            prompt: 'What does it mean?',
            subPrompt: 'አራት',
            hint: 'a·rat',
            options: [WordOption('Four'), WordOption('Six'), WordOption('Three'), WordOption('Nine')],
            answerIndex: 0,
          ),
          Question.match(
            prompt: 'Match the numbers',
            matchLeft: ['አራት', 'አምስት', 'አንድ'],
            matchRight: ['Four', 'Five', 'One'],
          ),
        ]),
      ],
    ),
    Unit(
      title: 'Unit 4 · ቤተሰብ Family',
      subtitle: 'Mother, father & home',
      color: Color(0xFFDA121A),
      dark: Color(0xFFA80E14),
      icon: Icons.family_restroom_rounded,
      lessons: [
        Lesson('am_u4_l1', 'My family', questions: [
          Question.mcq(
            prompt: "Which one means 'Mother'?",
            options: [WordOption('እናት'), WordOption('አባት'), WordOption('ቤት'), WordOption('ከተማ')],
            answerIndex: 0,
          ),
          Question.mcq(
            prompt: 'What does it mean?',
            subPrompt: 'አባት',
            hint: 'a·bat',
            options: [WordOption('Father'), WordOption('Mother'), WordOption('Brother'), WordOption('Home')],
            answerIndex: 0,
          ),
          Question.match(
            prompt: 'Match the pairs',
            matchLeft: ['እናት', 'አባት', 'ቤት'],
            matchRight: ['Mother', 'Father', 'House'],
          ),
          Question.mcq(
            prompt: 'Which word spells ETHIOPIA?',
            options: [
              WordOption('ኢትዮጵያ'),
              WordOption('እንጀራ'),
              WordOption('አመሰግናለሁ'),
              WordOption('እንዴት'),
            ],
            answerIndex: 0,
          ),
        ]),
      ],
    ),
  ],
  phrases: [
    Phrase('ሰላም', 'se·lam', 'Hello / Peace', 'Greetings'),
    Phrase('እንዴት ነህ?', 'en·det nehh', 'How are you? (to a man)', 'Greetings'),
    Phrase('እንዴት ነሽ?', 'en·det nesh', 'How are you? (to a woman)', 'Greetings'),
    Phrase('ደህና ነኝ', 'deh·na negn', 'I am fine', 'Greetings'),
    Phrase('አመሰግናለሁ', 'a·me·se·gi·na·le·hu', 'Thank you', 'Basics'),
    Phrase('እባክህ', 'ib·ba·kih', 'Please', 'Basics'),
    Phrase('አዎ', 'awo', 'Yes', 'Basics'),
    Phrase('አይደለም', 'ay·de·lem', 'No', 'Basics'),
    Phrase('ቡና', 'bu·na', 'Coffee', 'Food'),
    Phrase('ውሃ', 'wih·a', 'Water', 'Food'),
    Phrase('እንጀራ', 'in·je·ra', 'Injera flatbread', 'Food'),
    Phrase('ሻይ', 'shai', 'Tea', 'Food'),
    Phrase('ኢትዮጵያ', 'i·tyop·pya', 'Ethiopia', 'Places'),
    Phrase('አዲስ አበባ', 'a·dis a·be·ba', 'Addis Ababa', 'Places'),
  ],
);

const oromo = Language(
  id: 'om',
  name: 'Afaan Oromo',
  nativeName: 'Afaan Oromoo',
  scriptPreview: 'Qubee · A B C D E',
  speakers: '40M+',
  region: 'Oromia',
  color: Color(0xFFDA121A),
  dark: Color(0xFFA80E14),
  icon: Icons.favorite_rounded,
  helloTarget: 'Akkam',
  helloMeaning: 'Akkam · Hello / How are you',
  units: [
    Unit(
      title: 'Unit 1 · Akkam! Greetings',
      subtitle: 'Start speaking Qubee',
      color: Color(0xFFDA121A),
      dark: Color(0xFFA80E14),
      icon: Icons.waving_hand_rounded,
      lessons: [
        Lesson('om_u1_l1', 'First words', questions: [
          Question.mcq(
            prompt: "Which one means 'Hello / How are you?'",
            options: [
              WordOption('Akkam'),
              WordOption('Bishaan'),
              WordOption('Mana'),
              WordOption('Galatoomaa'),
            ],
            answerIndex: 0,
          ),
          Question.mcq(
            prompt: 'What does it mean?',
            subPrompt: 'Galatoomaa!',
            hint: 'ga·la·too·maa',
            options: [WordOption('Thank you'), WordOption('Goodbye'), WordOption('Yes'), WordOption('Water')],
            answerIndex: 0,
          ),
          Question.match(
            prompt: 'Match the pairs',
            matchLeft: ['Akkam', 'Galatoomaa', 'Nagaa'],
            matchRight: ['Hello', 'Thank you', 'Peace'],
          ),
          Question.fill(
            prompt: "'Yes' in Afaan Oromo",
            subPrompt: 'Yes → ___',
            options: [WordOption('Eeyee'), WordOption('Miti'), WordOption('Bishaan')],
            answerIndex: 0,
          ),
        ]),
      ],
    ),
  ],
  phrases: [
    Phrase('Akkam', 'ak·kam', 'Hello / How are you?', 'Greetings'),
    Phrase('Nagaa', 'na-gaa', 'Peace', 'Greetings'),
    Phrase('Galatoomaa', 'ga·la·too·maa', 'Thank you', 'Basics'),
    Phrase('Eeyee', 'eeyee', 'Yes', 'Basics'),
    Phrase('Miti', 'mi-ti', 'No', 'Basics'),
    Phrase('Buna', 'bu-na', 'Coffee', 'Food'),
    Phrase('Bishaan', 'bi-shaan', 'Water', 'Food'),
    Phrase('Mana', 'ma-na', 'House', 'Places'),
    Phrase('Itoophiyaa', 'i-toop-hiyaa', 'Ethiopia', 'Places'),
  ],
);

const tigrinya = Language(
  id: 'ti',
  name: 'Tigrinya',
  nativeName: 'ትግርኛ',
  scriptPreview: 'ሀ ለ ሐ መ ረ ሰ ተ',
  speakers: '9M+',
  region: 'Tigray & Eritrea',
  color: Color(0xFF0F47AF),
  dark: Color(0xFF0B3685),
  icon: Icons.landscape_rounded,
  helloTarget: 'ሰላም',
  helloMeaning: 'Selam · Hello',
  units: [
    Unit(
      title: 'Unit 1 · ሰላም Greetings',
      subtitle: 'Greetings of the highlands',
      color: Color(0xFF0F47AF),
      dark: Color(0xFF0B3685),
      icon: Icons.waving_hand_rounded,
      lessons: [
        Lesson('ti_u1_l1', 'First words', questions: [
          Question.mcq(
            prompt: "Which one means 'Hello'?",
            options: [
              WordOption('ሰላም'),
              WordOption('ማይ'),
              WordOption('ቡን'),
              WordOption('ገዛ'),
            ],
            answerIndex: 0,
          ),
          Question.mcq(
            prompt: 'What does it mean?',
            subPrompt: 'የቐንየለይ',
            hint: 'ye·qe·nye·ley',
            options: [WordOption('Thank you'), WordOption('Goodbye'), WordOption('Water'), WordOption('Yes')],
            answerIndex: 0,
          ),
          Question.match(
            prompt: 'Match the pairs',
            matchLeft: ['ሰላም', 'የቐንየለይ', 'እወ'],
            matchRight: ['Hello', 'Thank you', 'Yes'],
          ),
          Question.fill(
            prompt: "'Water' in Tigrinya",
            subPrompt: 'Water → ___',
            options: [WordOption('ማይ'), WordOption('ቡን'), WordOption('ገዛ')],
            answerIndex: 0,
          ),
        ]),
      ],
    ),
  ],
  phrases: [
    Phrase('ሰላም', 'se·lam', 'Hello', 'Greetings'),
    Phrase('ከመይ ኣለኻ?', 'ke·mey a·le·kha', 'How are you? (to a man)', 'Greetings'),
    Phrase('የቐንየለይ', 'ye·qe·nye·ley', 'Thank you', 'Basics'),
    Phrase('እወ', 'e·wa', 'Yes', 'Basics'),
    Phrase('ኣይኮነን', 'ay·ko·nen', 'No', 'Basics'),
    Phrase('ማይ', 'may', 'Water', 'Food'),
    Phrase('ቡን', 'bun', 'Coffee', 'Food'),
    Phrase('ገዛ', 'ge·za', 'House', 'Places'),
  ],
);

const somali = Language(
  id: 'so',
  name: 'Somali',
  nativeName: 'Af-Soomaali',
  scriptPreview: 'Salaan · Mahadsanid',
  speakers: '8M+',
  region: 'Somali Region & Horn',
  color: Color(0xFF6D28D9),
  dark: Color(0xFF52189E),
  icon: Icons.sailing_rounded,
  helloTarget: 'Iska warran',
  helloMeaning: 'Iska warran · Hey there',
  units: [
    Unit(
      title: 'Unit 1 · Salaan Greetings',
      subtitle: 'First steps in Somali',
      color: Color(0xFF6D28D9),
      dark: Color(0xFF52189E),
      icon: Icons.waving_hand_rounded,
      lessons: [
        Lesson('so_u1_l1', 'First words', questions: [
          Question.mcq(
            prompt: "Which one means 'Thank you'?",
            options: [
              WordOption('Mahadsanid'),
              WordOption('Biyo'),
              WordOption('Guri'),
              WordOption('Haa'),
            ],
            answerIndex: 0,
          ),
          Question.mcq(
            prompt: 'What does it mean?',
            subPrompt: 'Biyo',
            hint: 'bi-yo',
            options: [WordOption('Water'), WordOption('Tea'), WordOption('House'), WordOption('No')],
            answerIndex: 0,
          ),
          Question.match(
            prompt: 'Match the pairs',
            matchLeft: ['Salaan', 'Mahadsanid', 'Haa'],
            matchRight: ['Hello', 'Thank you', 'Yes'],
          ),
          Question.fill(
            prompt: "'Coffee' in Somali",
            subPrompt: 'Coffee → ___',
            options: [WordOption('Qaxwo'), WordOption('Biyo'), WordOption('Guri')],
            answerIndex: 0,
          ),
        ]),
      ],
    ),
  ],
  phrases: [
    Phrase('Salaan', 'sa-laan', 'Hello', 'Greetings'),
    Phrase('Iska warran', 'is-ka war-ran', 'Hey there!', 'Greetings'),
    Phrase('Mahadsanid', 'ma-had-sa-nid', 'Thank you', 'Basics'),
    Phrase('Haa', 'haa', 'Yes', 'Basics'),
    Phrase('Maya', 'ma-ya', 'No', 'Basics'),
    Phrase('Biyo', 'bi-yo', 'Water', 'Food'),
    Phrase('Qaxwo', 'qax-wo', 'Coffee', 'Food'),
    Phrase('Guri', 'gu-ri', 'House', 'Places'),
  ],
);

const afarComingSoon = (
  name: 'Afar',
  nativeName: 'Afaraf',
  speakers: '2M+',
);

const wolayttaComingSoon = (
  name: 'Wolaytta',
  nativeName: 'Wolayttatto',
  speakers: '2M+',
);

const languages = <Language>[amharic, oromo, tigrinya, somali];

Language languageById(String id) =>
    languages.firstWhere((l) => l.id == id, orElse: () => amharic);
