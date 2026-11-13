import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const ScienceSignalApp());
}

class ScienceSignalApp extends StatelessWidget {
  const ScienceSignalApp({
    super.key,
    this.questionLoader,
    this.submissionDelay = const Duration(milliseconds: 900),
  });

  final Future<List<ScienceQuestion>> Function()? questionLoader;
  final Duration submissionDelay;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Science Signal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B7A75)),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: ScienceQuizScreen(
        questionLoader: questionLoader,
        submissionDelay: submissionDelay,
      ),
    );
  }
}

class ScienceQuestion {
  const ScienceQuestion({required this.text, required this.correctAnswer});

  final String text;
  final String correctAnswer;

  factory ScienceQuestion.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['question'] is! String ||
        value['correct_answer'] is! String ||
        value['incorrect_answers'] is! List) {
      throw const FormatException('Invalid question data.');
    }

    final text = Uri.decodeComponent(value['question'] as String);
    final correctAnswer = Uri.decodeComponent(
      value['correct_answer'] as String,
    );
    final incorrectAnswers = value['incorrect_answers'] as List;
    if (text.trim().isEmpty ||
        (correctAnswer != 'True' && correctAnswer != 'False') ||
        incorrectAnswers.length != 1 ||
        incorrectAnswers.first is! String) {
      throw const FormatException('Invalid true-or-false question.');
    }

    final incorrectAnswer = Uri.decodeComponent(
      incorrectAnswers.first as String,
    );
    if ((incorrectAnswer != 'True' && incorrectAnswer != 'False') ||
        incorrectAnswer == correctAnswer) {
      throw const FormatException('Invalid true-or-false answers.');
    }
    return ScienceQuestion(text: text, correctAnswer: correctAnswer);
  }
}

final _questionUri = Uri.https('opentdb.com', '/api.php', {
  'amount': '5',
  'category': '17',
  'difficulty': 'medium',
  'type': 'boolean',
  'encode': 'url3986',
});

Future<List<ScienceQuestion>> fetchScienceQuestions() async {
  final response = await http
      .get(_questionUri)
      .timeout(const Duration(seconds: 10));
  if (response.statusCode != 200) {
    throw FormatException('Server returned HTTP ${response.statusCode}.');
  }

  final data = jsonDecode(response.body);
  if (data is! Map<String, dynamic> || data['response_code'] != 0) {
    throw const FormatException('The trivia API did not return questions.');
  }
  final results = data['results'];
  if (results is! List || results.length != 5) {
    throw const FormatException('Expected five trivia questions.');
  }
  return results.map(ScienceQuestion.fromJson).toList(growable: false);
}

class ScienceQuizScreen extends StatefulWidget {
  const ScienceQuizScreen({
    super.key,
    this.questionLoader,
    this.submissionDelay = const Duration(milliseconds: 900),
  });

  final Future<List<ScienceQuestion>> Function()? questionLoader;
  final Duration submissionDelay;

  @override
  State<ScienceQuizScreen> createState() => _ScienceQuizScreenState();
}

class _ScienceQuizScreenState extends State<ScienceQuizScreen> {
  List<ScienceQuestion> _questions = const [];
  List<String?> _answers = const [];
  int _currentIndex = 0;
  bool _loading = true;
  bool _showResults = false;
  bool _submitting = false;
  bool _submitted = false;
  String? _error;

  int get _score {
    var total = 0;
    for (var index = 0; index < _answers.length; index++) {
      if (_answers[index] == _questions[index].correctAnswer) total++;
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _loading = true;
      _error = null;
      _questions = const [];
      _answers = const [];
      _currentIndex = 0;
      _showResults = false;
      _submitting = false;
      _submitted = false;
    });

    try {
      final questions =
          await (widget.questionLoader ?? fetchScienceQuestions)();
      if (questions.length != 5) {
        throw const FormatException('Expected five trivia questions.');
      }
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _answers = List<String?>.filled(questions.length, null);
        _loading = false;
      });
    } on TimeoutException {
      _showError('The request timed out. Please try again.');
    } on http.ClientException catch (error) {
      _showError('The request failed: ${error.message}');
    } on FormatException catch (error) {
      _showError('Could not load questions: ${error.message}');
    } catch (_) {
      _showError('Could not reach the trivia service. Please try again.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _loading = false;
    });
  }

  void _selectAnswer(String answer) {
    if (_answers[_currentIndex] != null) return;
    setState(() => _answers[_currentIndex] = answer);
  }

  void _continue() {
    if (_answers[_currentIndex] == null) return;
    setState(() {
      if (_currentIndex == _questions.length - 1) {
        _showResults = true;
      } else {
        _currentIndex++;
      }
    });
  }

  Future<void> _simulateSubmission() async {
    if (_submitting || _submitted) return;
    setState(() => _submitting = true);
    await Future<void>.delayed(widget.submissionDelay);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Science Signal'), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildBody(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 18),
          Text('Tuning in to the science feed…'),
        ],
      );
    }
    if (_error != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 52),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _loadQuestions,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      );
    }
    return _showResults ? _buildResults() : _buildQuestion();
  }

  Widget _buildQuestion() {
    final question = _questions[_currentIndex];
    final selected = _answers[_currentIndex];
    final answered = selected != null;
    final correct = selected == question.correctAnswer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Question ${_currentIndex + 1} of ${_questions.length}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(value: (_currentIndex + 1) / _questions.length),
        const Spacer(),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Text(
              question.text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(child: _answerButton('True', question, selected)),
            const SizedBox(width: 14),
            Expanded(child: _answerButton('False', question, selected)),
          ],
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: answered
              ? Semantics(
                  key: ValueKey(selected),
                  liveRegion: true,
                  child: Text(
                    correct
                        ? 'Correct! ${question.correctAnswer} is the answer.'
                        : 'Not quite. The correct answer is ${question.correctAnswer}.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: correct
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : const Text(
                  'Choose True or False to continue.',
                  key: ValueKey('waiting'),
                  textAlign: TextAlign.center,
                ),
        ),
        const Spacer(),
        FilledButton(
          onPressed: answered ? _continue : null,
          child: Text(
            _currentIndex == _questions.length - 1
                ? 'View results'
                : 'Next question',
          ),
        ),
      ],
    );
  }

  Widget _answerButton(
    String answer,
    ScienceQuestion question,
    String? selected,
  ) {
    final answered = selected != null;
    final isCorrect = answered && answer == question.correctAnswer;
    final isWrongSelection = answered && answer == selected && !isCorrect;
    final background = isCorrect
        ? Colors.green.shade100
        : isWrongSelection
        ? Colors.red.shade100
        : null;
    final foreground = isCorrect
        ? Colors.green.shade900
        : isWrongSelection
        ? Colors.red.shade900
        : null;

    return OutlinedButton(
      onPressed: answered ? null : () => _selectAnswer(answer),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background,
        disabledForegroundColor: foreground,
      ),
      child: Text(answer),
    );
  }

  Widget _buildResults() {
    final payload = const JsonEncoder.withIndent('  ').convert({
      'score': _score,
      'total': _questions.length,
      'category': 'Science & Nature',
    });

    return ListView(
      children: [
        Icon(
          _score >= 4 ? Icons.emoji_events_outlined : Icons.science_outlined,
          size: 54,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          'Score: $_score / ${_questions.length}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        const Text('Answer review', textAlign: TextAlign.center),
        const SizedBox(height: 18),
        for (var index = 0; index < _questions.length; index++)
          _reviewCard(index),
        const SizedBox(height: 12),
        Text(
          'Score submission simulation',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'No submission endpoint was provided. This action only simulates an '
          'asynchronous submission; it does not send or save data remotely.',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(payload),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _submitting || _submitted ? null : _simulateSubmission,
          icon: _submitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_outlined),
          label: Text(
            _submitting
                ? 'Submitting simulation…'
                : _submitted
                ? 'Simulation complete'
                : 'Simulate score submission',
          ),
        ),
        if (_submitted) ...[
          const SizedBox(height: 10),
          const Text(
            'Simulation complete — no data was sent to a server.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _loading ? null : _loadQuestions,
          icon: const Icon(Icons.replay),
          label: const Text('Replay with new questions'),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _reviewCard(int index) {
    final question = _questions[index];
    final answer = _answers[index]!;
    final correct = answer == question.correctAnswer;
    return Card(
      key: ValueKey('review-$index'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  correct ? Icons.check_circle : Icons.cancel,
                  color: correct ? Colors.green.shade700 : Colors.red.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Question ${index + 1} · ${correct ? 'Correct' : 'Incorrect'}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(question.text),
            const SizedBox(height: 8),
            Text('Your answer: $answer'),
            Text('Correct answer: ${question.correctAnswer}'),
          ],
        ),
      ),
    );
  }
}
