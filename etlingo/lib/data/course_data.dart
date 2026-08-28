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
        Lesson('am_u1_l1', 'First words', teachItems: [
          TeachItem(target: 'ሰላም', translit: 'selam', meaning: 'Hello / Peace', meanings: {'en': 'Hello / Peace', 'am': 'ሰላም'}),
          TeachItem(target: 'አመሰግናለሁ', translit: 'amèseginàlehu', meaning: 'Thank you', meanings: {'en': 'Thank you', 'am': 'አመሰግናለሁ'}),
          TeachItem(target: 'ደህና ሁን', translit: 'dehna hun', meaning: 'Goodbye', meanings: {'en': 'Goodbye', 'am': 'ደህና ሁን'}),
        ], questions: [
          Question.mcq(
            prompt: "Which one means 'Hello'?",
            content: {'en': {'prompt': "Which one means 'Hello'?", 'subPrompt': ''}},
            options: [
              WordOption('ሰላም'),
              WordOption('ውሃ'),
              WordOption('ቡና'),
              WordOption('ቤት'),
            ],
            answerIndex: 0,
          ),
          Question.mcq(
            prompt: 'What does it mean?',
            subPrompt: 'ሰላም',
            hint: 'se·lam',
            content: {'en': {'prompt': 'What does it mean?', 'subPrompt': 'ሰላም', 'hint': 'se·lam'}},
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
            content: {'en': {'prompt': 'Match the pairs'}},
          ),
          Question.fill(
            prompt: "'Thank you' in Amharic",
            subPrompt: 'Thank you → ___',
            content: {'en': {'prompt': "'Thank you' in Amharic", 'subPrompt': 'Thank you → ___'}},
            options: [
              WordOption('አመሰግናለሁ'),
              WordOption('ደህና ሁን'),
              WordOption('እንዴት ነህ'),
            ],
            answerIndex: 0,
          ),
        ]),
        Lesson('am_u1_l2', 'How are you?', teachItems: [
          TeachItem(target: 'እንዴት ነህ?', translit: 'indèt neh?', meaning: 'How are you? (to a man)', meanings: {'en': 'How are you? (to a man)', 'am': 'እንዴት ነህ?'}),
          TeachItem(target: 'ደህና ነኝ', translit: 'dehna negn', meaning: 'I am fine', meanings: {'en': 'I am fine', 'am': 'ደህና ነኝ'}),
          TeachItem(target: 'ስሜ ... ነው', translit: 'simè ... new', meaning: 'My name is...', meanings: {'en': 'My name is...', 'am': 'ስሜ ... ነው'}),
        ], questions: [
          Question.mcq(
            prompt: "Ask a friend 'How are you?' (to a man)",
            content: {'en': {'prompt': "Ask a friend 'How are you?' (to a man)", 'subPrompt': ''}},
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
            content: {'en': {'prompt': 'What does it mean?', 'subPrompt': 'ደህና ነኝ', 'hint': 'deh·na negn'}},
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
            content: {'en': {'prompt': 'Match the pairs'}},
          ),
          Question.fill(
            prompt: 'Reply to እንዴት ነህ? with "I am fine"',
            subPrompt: 'I am fine → ___',
            content: {'en': {'prompt': 'Reply to እንዴት ነህ? with "I am fine"', 'subPrompt': 'I am fine → ___'}},
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
            content: {'en': {'prompt': 'Which one is a morning greeting?', 'subPrompt': 'እንደምን አደሩ?', 'hint': 'in·de·min a·de·ru'}},
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
            content: {'en': {'prompt': 'Big review — match them all'}},
          ),
          Question.fill(
            prompt: 'Goodbye in Amharic',
            subPrompt: 'Goodbye → ደህና ___',
            content: {'en': {'prompt': 'Goodbye in Amharic', 'subPrompt': 'Goodbye → ደህና ___'}},
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
        Lesson('am_u2_l1', 'Coffee ceremony', teachItems: [
          TeachItem(target: 'ቡና', translit: 'buna', meaning: 'Coffee', meanings: {'en': 'Coffee', 'am': 'ቡና'}),
          TeachItem(target: 'ውሃ', translit: 'wiha', meaning: 'Water', meanings: {'en': 'Water', 'am': 'ውሃ'}),
          TeachItem(target: 'ሻይ', translit: 'shai', meaning: 'Tea', meanings: {'en': 'Tea', 'am': 'ሻይ'}),
        ], questions: [
          Question.mcq(
            prompt: "Ethiopia gave the world this drink. Which one is 'Coffee'?",
            content: {'en': {'prompt': "Ethiopia gave the world this drink. Which one is 'Coffee'?", 'subPrompt': ''}},
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
            content: {'en': {'prompt': 'What does it mean?', 'subPrompt': 'ውሃ', 'hint': 'wih·a'}},
            options: [WordOption('Water'), WordOption('Milk'), WordOption('Tea'), WordOption('Bread')],
            answerIndex: 0,
          ),
          Question.match(
            prompt: 'Match the pairs',
            matchLeft: ['ቡና', 'ውሃ', 'ሻይ'],
            matchRight: ['Coffee', 'Water', 'Tea'],
            content: {'en': {'prompt': 'Match the pairs'}},
          ),
          Question.fill(
            prompt: 'Coffee in Amharic',
            subPrompt: 'Coffee → ___',
            content: {'en': {'prompt': 'Coffee in Amharic', 'subPrompt': 'Coffee → ___'}},
            options: [WordOption('ቡና'), WordOption('ሻይ'), WordOption('ውሃ')],
            answerIndex: 0,
          ),
        ]),
        Lesson('am_u2_l2', 'Injera time', teachItems: [
          TeachItem(target: 'እንጀራ', translit: 'injera', meaning: 'Sour flat bread', meanings: {'en': 'Sour flat bread', 'am': 'እንጀራ'}),
          TeachItem(target: 'ሻይ', translit: 'shai', meaning: 'Tea', meanings: {'en': 'Tea', 'am': 'ሻይ'}),
          TeachItem(target: 'ውሃ እባክህ', translit: 'wiha ibakih', meaning: 'Water, please', meanings: {'en': 'Water, please', 'am': 'ውሃ እባክህ'}),
        ], questions: [
          Question.mcq(
            prompt: 'What is እንጀራ (injera)?',
            subPrompt: 'እንጀራ',
            hint: 'in·je·ra',
            content: {'en': {'prompt': 'What is እንጀራ (injera)?', 'subPrompt': 'እንጀራ', 'hint': 'in·je·ra'}},
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
            content: {'en': {'prompt': 'Which one is TEA?', 'subPrompt': ''}},
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
            content: {'en': {'prompt': 'Order water politely: "Water, please"', 'subPrompt': 'Water please → ውሃ ___'}},
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
        Lesson('am_u3_l1', 'One, two, three', teachItems: [
          TeachItem(target: 'አንድ', translit: 'and', meaning: 'One', meanings: {'en': 'One', 'am': 'አንድ'}),
          TeachItem(target: 'ሁለት', translit: 'hulet', meaning: 'Two', meanings: {'en': 'Two', 'am': 'ሁለት'}),
          TeachItem(target: 'ሶስት', translit: 'sost', meaning: 'Three', meanings: {'en': 'Three', 'am': 'ሶስት'}),
        ], questions: [
          Question.mcq(
            prompt: "Which means 'One'?",
            content: {'en': {'prompt': "Which means 'One'?", 'subPrompt': ''}},
            options: [WordOption('አንድ'), WordOption('ሁለት'), WordOption('ሶስት'), WordOption('አራት')],
            answerIndex: 0,
          ),
          Question.mcq(
            prompt: 'What does it mean?',
            subPrompt: 'ሶስት',
            hint: 'sost',
            content: {'en': {'prompt': 'What does it mean?', 'subPrompt': 'ሶስት', 'hint': 'sost'}},
            options: [WordOption('Three'), WordOption('Two'), WordOption('Five'), WordOption('Ten')],
            answerIndex: 0,
          ),
          Question.match(
            prompt: 'Match the numbers',
            matchLeft: ['አንድ', 'ሁለት', 'ሶስት'],
            matchRight: ['One', 'Two', 'Three'],
            content: {'en': {'prompt': 'Match the numbers'}},
          ),
          Question.fill(
            prompt: '"Two coffees, please" — pick Two',
            subPrompt: '___ ቡና እባክህ',
            content: {'en': {'prompt': '"Two coffees, please" — pick Two', 'subPrompt': '___ ቡና እባክህ'}},
            options: [WordOption('ሁለት'), WordOption('አንድ'), WordOption('ሶስት')],
            answerIndex: 0,
          ),
        ]),
        Lesson('am_u3_l2', 'Four and five', teachItems: [
          TeachItem(target: 'አራት', translit: 'arat', meaning: 'Four', meanings: {'en': 'Four', 'am': 'አራት'}),
          TeachItem(target: 'አምስት', translit: 'amist', meaning: 'Five', meanings: {'en': 'Five', 'am': 'አምስት'}),
        ], questions: [
          Question.mcq(
            prompt: "Which means 'Five'?",
            content: {'en': {'prompt': "Which means 'Five'?", 'subPrompt': ''}},
            options: [WordOption('አምስት'), WordOption('አራት'), WordOption('አንድ'), WordOption('ሶስት')],
            answerIndex: 0,
          ),
          Question.mcq(
            prompt: 'What does it mean?',
            subPrompt: 'አራት',
            hint: 'a·rat',
            content: {'en': {'prompt': 'What does it mean?', 'subPrompt': 'አራት', 'hint': 'a·rat'}},
            options: [WordOption('Four'), WordOption('Six'), WordOption('Three'), WordOption('Nine')],
            answerIndex: 0,
          ),
          Question.match(
            prompt: 'Match the numbers',
            matchLeft: ['አራት', 'አምስት', 'አንድ'],
            matchRight: ['Four', 'Five', 'One'],
            content: {'en': {'prompt': 'Match the numbers'}},
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
        Lesson('am_u4_l1', 'My family', teachItems: [
          TeachItem(target: 'እናት', translit: 'inat', meaning: 'Mother', meanings: {'en': 'Mother', 'am': 'እናት'}),
          TeachItem(target: 'አባት', translit: 'abat', meaning: 'Father', meanings: {'en': 'Father', 'am': 'አባት'}),
          TeachItem(target: 'ቤት', translit: 'bet', meaning: 'House / Home', meanings: {'en': 'House / Home', 'am': 'ቤት'}),
        ], questions: [
          Question.mcq(
            prompt: "Which one means 'Mother'?",
            content: {'en': {'prompt': "Which one means 'Mother'?", 'subPrompt': ''}},
            options: [WordOption('እናት'), WordOption('አባት'), WordOption('ቤት'), WordOption('ከተማ')],
            answerIndex: 0,
          ),
          Question.mcq(
            prompt: 'What does it mean?',
            subPrompt: 'አባት',
            hint: 'a·bat',
            content: {'en': {'prompt': 'What does it mean?', 'subPrompt': 'አባት', 'hint': 'a·bat'}},
            options: [WordOption('Father'), WordOption('Mother'), WordOption('Brother'), WordOption('Home')],
            answerIndex: 0,
          ),
          Question.match(
            prompt: 'Match the pairs',
            matchLeft: ['እናት', 'አባት', 'ቤት'],
            matchRight: ['Mother', 'Father', 'House'],
            content: {'en': {'prompt': 'Match the pairs'}},
          ),
          Question.mcq(
            prompt: 'Which word spells ETHIOPIA?',
            content: {'en': {'prompt': 'Which word spells ETHIOPIA?', 'subPrompt': ''}},
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
        Lesson('om_u1_l1', 'First words', teachItems: [
          TeachItem(target: 'Akkam', translit: 'ak-kam', meaning: 'Hello / How are you?', meanings: {'en': 'Hello / How are you?', 'om': 'Akkam'}),
          TeachItem(target: 'Galatoomaa', translit: 'ga-la-too-maa', meaning: 'Thank you', meanings: {'en': 'Thank you', 'om': 'Galatoomaa'}),
          TeachItem(target: 'Nagaa', translit: 'na-gaa', meaning: 'Peace', meanings: {'en': 'Peace', 'om': 'Nagaa'}),
          TeachItem(target: 'Eeyee', translit: 'eeyee', meaning: 'Yes', meanings: {'en': 'Yes', 'om': 'Eeyee'}),
        ], questions: [
          Question.mcq(
            prompt: "Which one means 'Hello / How are you?'",
            content: {'en': {'prompt': "Which one means 'Hello / How are you?'", 'subPrompt': ''}},
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
            content: {'en': {'prompt': 'What does it mean?', 'subPrompt': 'Galatoomaa!', 'hint': 'ga·la·too·maa'}},
            options: [WordOption('Thank you'), WordOption('Goodbye'), WordOption('Yes'), WordOption('Water')],
            answerIndex: 0,
          ),
          Question.match(
            prompt: 'Match the pairs',
            matchLeft: ['Akkam', 'Galatoomaa', 'Nagaa'],
            matchRight: ['Hello', 'Thank you', 'Peace'],
            content: {'en': {'prompt': 'Match the pairs'}},
          ),
          Question.fill(
            prompt: "'Yes' in Afaan Oromo",
            subPrompt: 'Yes → ___',
            content: {'en': {'prompt': "'Yes' in Afaan Oromo", 'subPrompt': 'Yes → ___'}},
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
        Lesson('ti_u1_l1', 'First words', teachItems: [
          TeachItem(target: 'ሰላም', translit: 'selam', meaning: 'Hello', meanings: {'en': 'Hello', 'ti': 'ሰላም'}),
          TeachItem(target: 'የቐንየለይ', translit: 'yeqenyelay', meaning: 'Thank you', meanings: {'en': 'Thank you', 'ti': 'የቐንየለይ'}),
          TeachItem(target: 'እወ', translit: 'ewe', meaning: 'Yes', meanings: {'en': 'Yes', 'ti': 'እወ'}),
          TeachItem(target: 'ማይ', translit: 'may', meaning: 'Water', meanings: {'en': 'Water', 'ti': 'ማይ'}),
        ], questions: [
          Question.mcq(
            prompt: "Which one means 'Hello'?",
            content: {'en': {'prompt': "Which one means 'Hello'?", 'subPrompt': ''}},
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
            content: {'en': {'prompt': 'What does it mean?', 'subPrompt': 'የቐንየለይ', 'hint': 'ye·qe·nye·ley'}},
            options: [WordOption('Thank you'), WordOption('Goodbye'), WordOption('Water'), WordOption('Yes')],
            answerIndex: 0,
          ),
          Question.match(
            prompt: 'Match the pairs',
            matchLeft: ['ሰላም', 'የቐንየለይ', 'እወ'],
            matchRight: ['Hello', 'Thank you', 'Yes'],
            content: {'en': {'prompt': 'Match the pairs'}},
          ),
          Question.fill(
            prompt: "'Water' in Tigrinya",
            subPrompt: 'Water → ___',
            content: {'en': {'prompt': "'Water' in Tigrinya", 'subPrompt': 'Water → ___'}},
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
        Lesson('so_u1_l1', 'First words', teachItems: [
          TeachItem(target: 'Salaan', translit: 'sa-laan', meaning: 'Hello', meanings: {'en': 'Hello', 'so': 'Salaan'}),
          TeachItem(target: 'Mahadsanid', translit: 'ma-had-sa-nid', meaning: 'Thank you', meanings: {'en': 'Thank you', 'so': 'Mahadsanid'}),
          TeachItem(target: 'Haa', translit: 'haa', meaning: 'Yes', meanings: {'en': 'Yes', 'so': 'Haa'}),
          TeachItem(target: 'Biyo', translit: 'bi-yo', meaning: 'Water', meanings: {'en': 'Water', 'so': 'Biyo'}),
        ], questions: [
          Question.mcq(
            prompt: "Which one means 'Thank you'?",
            content: {'en': {'prompt': "Which one means 'Thank you'?", 'subPrompt': ''}},
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
            content: {'en': {'prompt': 'What does it mean?', 'subPrompt': 'Biyo', 'hint': 'bi-yo'}},
            options: [WordOption('Water'), WordOption('Tea'), WordOption('House'), WordOption('No')],
            answerIndex: 0,
          ),
          Question.match(
            prompt: 'Match the pairs',
            matchLeft: ['Salaan', 'Mahadsanid', 'Haa'],
            matchRight: ['Hello', 'Thank you', 'Yes'],
            content: {'en': {'prompt': 'Match the pairs'}},
          ),
          Question.fill(
            prompt: "'Coffee' in Somali",
            subPrompt: 'Coffee → ___',
            content: {'en': {'prompt': "'Coffee' in Somali", 'subPrompt': 'Coffee → ___'}},
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
