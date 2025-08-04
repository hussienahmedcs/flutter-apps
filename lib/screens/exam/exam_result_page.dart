import 'package:flutter/material.dart';
import 'package:wordstory/data/models/exam_question.dart';

class ExamResultPage extends StatelessWidget {
  final List<ExamQuestion> questions;
  final Map<String, String> userAnswers;

  const ExamResultPage({
    super.key,
    required this.questions,
    required this.userAnswers,
  });

  @override
  Widget build(BuildContext context) {
    int correct = 0;
    for (final q in questions) {
      if (userAnswers[q.id]?.trim().toLowerCase() == q.correctAnswer.trim().toLowerCase()) {
        correct++;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Results'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your score: $correct / ${questions.length}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            const Text('Review:', style: TextStyle(fontSize: 18)),
            Expanded(
              child: ListView.separated(
                itemCount: questions.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, i) {
                  final q = questions[i];
                  final userAns = userAnswers[q.id] ?? '';
                  final isCorrect = userAns.trim().toLowerCase() == q.correctAnswer.trim().toLowerCase();
                  return ListTile(
                    title: Text(q.prompt),
                    subtitle: Text(
                      'Your answer: $userAns\nCorrect answer: ${q.correctAnswer}',
                      style: TextStyle(
                        color: isCorrect ? Colors.green : Colors.red,
                        fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
            Center(
              child: ElevatedButton(
                child: const Text('Retake Exam'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          ],
        ),
      ),
    );
  }
}
