import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_signal/main.dart';

const sampleQuestions = [
  ScienceQuestion(
    text: 'The Earth completes one orbit around the Sun each year.',
    correctAnswer: 'True',
  ),
  ScienceQuestion(
    text: 'Sound travels through a vacuum faster than light.',
    correctAnswer: 'False',
  ),
  ScienceQuestion(
    text: 'Water molecules contain hydrogen and oxygen.',
    correctAnswer: 'True',
  ),
  ScienceQuestion(
    text: 'An adult human normally has three lungs.',
    correctAnswer: 'False',
  ),
  ScienceQuestion(
    text: 'Venus is the second planet from the Sun.',
    correctAnswer: 'True',
  ),
];

Future<List<ScienceQuestion>> loadSampleQuestions() async => sampleQuestions;

void main() {
  setUpAll(() async {
    final textLoader = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final iconLoader = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('assets/fonts/MaterialIcons-Regular.otf'));
    await Future.wait([textLoader.load(), iconLoader.load()]);
  });

  testWidgets('answer feedback evidence', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ScienceSignalApp(questionLoader: loadSampleQuestions),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'False'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/01_answer_feedback.png'),
    );
  });

  testWidgets('results review and submission evidence', (tester) async {
    await tester.binding.setSurfaceSize(const Size(720, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ScienceSignalApp(
        questionLoader: loadSampleQuestions,
        submissionDelay: Duration.zero,
      ),
    );
    await tester.pumpAndSettle();

    for (var index = 0; index < sampleQuestions.length; index++) {
      await tester.tap(find.widgetWithText(OutlinedButton, 'True'));
      await tester.pump();
      await tester.tap(
        find.widgetWithText(
          FilledButton,
          index == sampleQuestions.length - 1
              ? 'View results'
              : 'Next question',
        ),
      );
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Simulate score submission'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/02_results_and_submission.png'),
    );
  });
}
