import 'package:flutter/material.dart';
import 'package:wordstory/data/models/exam_question.dart';
import 'package:wordstory/data/models/entry_model.dart';
import 'package:wordstory/services/exam_generator.dart';
import 'exam_result_page.dart';

class ExamTakePage extends StatefulWidget {
  final List<Entry> entries;
  const ExamTakePage({Key? key, required this.entries}) : super(key: key);

  @override
  State<ExamTakePage> createState() => _ExamTakePageState();
}

class _ExamTakePageState extends State<ExamTakePage> {
  late List<ExamQuestion> _questions;
  int _currentIndex = 0;
  final Map<String, String> _userAnswers = {};

  @override
  void initState() {
    super.initState();
    _questions = ExamGenerator.generate(widget.entries);
  }

  void _submit() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ExamResultPage(
        questions: _questions,
        userAnswers: _userAnswers,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor, // or Colors.blue, etc.
        title: Text('Question ${_currentIndex + 1} of ${_questions.length}'),
        actions: [
          TextButton(
            onPressed: _submit,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildQuestion(question),
      ),
      bottomNavigationBar: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _currentIndex > 0
                  ? () {
                      setState(() => _currentIndex--);
                    }
                  : null,
              child: const Text('Previous'),
            ),
            TextButton(
              onPressed: _currentIndex < _questions.length - 1
                  ? () {
                      setState(() => _currentIndex++);
                    }
                  : null,
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(ExamQuestion q) {
    switch (q.type) {
      case QuestionType.mcq:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.prompt, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            ...q.options.map((option) {
              final isSelected = _userAnswers[q.id] == option;
              return ListTile(
                title: Text(option),
                leading: Radio<String>(
                  value: option,
                  groupValue: _userAnswers[q.id],
                  onChanged: (val) {
                    setState(() {
                      _userAnswers[q.id] = val!;
                    });
                  },
                ),
                tileColor: isSelected ? Colors.blue.withOpacity(0.08) : null,
              );
            }),
          ],
        );
      case QuestionType.complete:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.prompt, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Your answer'),
              onChanged: (val) => _userAnswers[q.id] = val,
            ),
          ],
        );
      // case QuestionType.match:
      //   // Simple placeholder. Full matching UI can be implemented if needed.
      //   return const Text("Matching questions coming soon!");
      default:
        return const SizedBox();
    }
  }
}
