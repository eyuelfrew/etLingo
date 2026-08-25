import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:etlingo/data/course_data.dart';
import 'package:etlingo/data/models.dart';
import 'package:etlingo/features/lesson/lesson_screen.dart';
import 'package:etlingo/state/app_state.dart';

void main() {
  test('course data is well-formed', () {
    for (final lang in languages) {
      expect(lang.units, isNotEmpty);
      for (final unit in lang.units) {
        expect(unit.lessons, isNotEmpty);
        for (final lesson in unit.lessons) {
          expect(lesson.questions, isNotEmpty);
          for (final q in lesson.questions) {
            switch (q.kind) {
              case QuestionKind.mcq:
              case QuestionKind.fill:
              case QuestionKind.listen:
                expect(q.answerIndex, lessThan(q.options.length));
                break;
              case QuestionKind.match:
                expect(q.matchLeft.length, q.matchRight.length);
                break;
            }
          }
        }
      }
    }
  });

  test('fresh AppState is a guest with no course selected', () {
    final state = AppState();
    expect(state.onboarded, isFalse);
    expect(state.languages, isEmpty);
    expect(state.hearts, 5);
    expect(state.xp, 0);
  });

  testWidgets('full lesson flow: mcq, match, fill, result', (tester) async {
    final state = AppState();
    final unit = amharic.units[0];
    final lesson = unit.lessons[0];

    await tester.pumpWidget(MaterialApp(
      home: LessonScreen(state: state, lesson: lesson, unit: unit),
    ));
    await tester.pump();

    expect(state.hearts, 5);
    expect(state.xp, 0);

    Future<void> tap(Finder f) async {
      await tester.tap(f);
      await tester.pump();
    }

    await tap(find.text('ሰላም'));
    expect(find.text("Which one means 'Hello'?"), findsOneWidget);
    await tap(find.text('Check'));
    expect(find.textContaining('Nicely done'), findsOneWidget);
    await tap(find.text('Continue'));

    await tap(find.text('Peace / Hello'));
    await tap(find.text('Check'));
    await tap(find.text('Continue'));

    await tap(find.text('ሰላም'));
    await tap(find.text('Hello'));
    await pumpFrames(tester, const Duration(milliseconds: 120));
    await tap(find.text('አመሰግናለሁ'));
    await tap(find.text('Thank you'));
    await pumpFrames(tester, const Duration(milliseconds: 120));
    await tap(find.text('ደህና ሁን'));
    await tap(find.text('Goodbye'));
    await pumpFrames(tester, const Duration(milliseconds: 600));
    await tap(find.text('Continue'));

    await tap(find.text('አመሰግናለሁ'));
    await tap(find.text('Check'));
    await tap(find.text('Continue'));
    await pumpFrames(tester, const Duration(milliseconds: 1300));

    expect(find.textContaining('Flawless'), findsOneWidget);
    expect(state.completedLessons.contains(lesson.id), isTrue);
    expect(state.xp, greaterThan(0));
    expect(state.hearts, 5);
  });
}

Future<void> pumpFrames(WidgetTester tester, Duration duration) async {
  var remaining = duration.inMilliseconds;
  while (remaining > 0) {
    final step = remaining > 100 ? 100 : remaining;
    await tester.pump(Duration(milliseconds: step));
    remaining -= step;
  }
}
