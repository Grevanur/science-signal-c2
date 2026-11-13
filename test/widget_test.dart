import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:science_signal/main.dart';

const questions = [
  ScienceQuestion(text: 'The Earth orbits the Sun.', correctAnswer: 'True'),
  ScienceQuestion(
    text: 'Sound travels faster than light.',
    correctAnswer: 'False',
  ),
  ScienceQuestion(
    text: 'Water is made of hydrogen and oxygen.',
    correctAnswer: 'True',
  ),
  ScienceQuestion(text: 'Humans have three lungs.', correctAnswer: 'False'),
  ScienceQuestion(text: 'Venus is a planet.', correctAnswer: 'True'),
];

Future<List<ScienceQuestion>> loadQuestions() async => questions;

void main() {
  test('ScienceQuestion decodes URL-encoded response text', () {
    final question = ScienceQuestion.fromJson({
      'question': 'The%20Earth%20orbits%20the%20Sun.',
      'correct_answer': 'True',
      'incorrect_answers': ['False'],
    });

    expect(question.text, 'The Earth orbits the Sun.');
    expect(question.correctAnswer, 'True');
  });

  test('ScienceQuestion rejects an invalid boolean answer pair', () {
    expect(
      () => ScienceQuestion.fromJson({
        'question': 'Valid%20prompt',
        'correct_answer': 'True',
        'incorrect_answers': ['True'],
      }),
      throwsFormatException,
    );
  });

  testWidgets('runs all five questions and shows every review entry', (
    tester,
  ) async {
    await tester.pumpWidget(ScienceSignalApp(questionLoader: loadQuestions));
    await tester.pumpAndSettle();

    for (var index = 0; index < questions.length; index++) {
      await tester.tap(find.widgetWithText(OutlinedButton, 'True'));
      await tester.pump();
      expect(
        find.textContaining(index.isEven ? 'Correct!' : 'Not quite.'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'False'));
      await tester.pump();
      await tester.tap(
        find.widgetWithText(
          FilledButton,
          index == questions.length - 1 ? 'View results' : 'Next question',
        ),
      );
      await tester.pumpAndSettle();
    }

    expect(find.text('Score: 3 / 5'), findsOneWidget);
    for (var index = 0; index < questions.length; index++) {
      final entry = find.byKey(ValueKey('review-$index'));
      await tester.scrollUntilVisible(
        entry,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(entry, findsOneWidget);
    }
  });

  testWidgets('shows a request error and retries successfully', (tester) async {
    var attempts = 0;
    Future<List<ScienceQuestion>> flakyLoader() async {
      attempts++;
      if (attempts == 1) throw const FormatException('Test failure.');
      return questions;
    }

    await tester.pumpWidget(ScienceSignalApp(questionLoader: flakyLoader));
    await tester.pumpAndSettle();
    expect(find.textContaining('Test failure'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Question 1 of 5'), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets('labels the local submission simulation and payload', (
    tester,
  ) async {
    await tester.pumpWidget(ScienceSignalApp(questionLoader: loadQuestions));
    await tester.pumpAndSettle();

    for (var index = 0; index < questions.length; index++) {
      await tester.tap(find.widgetWithText(OutlinedButton, 'True'));
      await tester.pump();
      await tester.tap(
        find.widgetWithText(
          FilledButton,
          index == questions.length - 1 ? 'View results' : 'Next question',
        ),
      );
      await tester.pumpAndSettle();
    }

    final submission = find.text('Simulate score submission');
    await tester.scrollUntilVisible(
      submission,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(submission);
    await tester.pump();
    expect(find.text('Submitting simulation…'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 901));
    expect(find.text('Simulation complete'), findsOneWidget);
    expect(
      find.text('Simulation complete — no data was sent to a server.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('"category": "Science & Nature"'),
      findsOneWidget,
    );
  });

  testWidgets('shows a loading state while the request is pending', (
    tester,
  ) async {
    final pending = Completer<List<ScienceQuestion>>();
    await tester.pumpWidget(
      ScienceSignalApp(questionLoader: () => pending.future),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Tuning in to the science feed…'), findsOneWidget);
  });
}
