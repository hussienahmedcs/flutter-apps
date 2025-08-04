enum QuestionType { mcq, complete } //match

class ExamQuestion {
  final String id;
  final QuestionType type;
  final String prompt;
  final List<String> options; // For MCQ/match
  final String correctAnswer;
  final String? extra; // For blanks etc.

  ExamQuestion({
    required this.id,
    required this.type,
    required this.prompt,
    required this.options,
    required this.correctAnswer,
    this.extra,
  });
}
