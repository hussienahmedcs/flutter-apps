import 'package:wordstory/data/models/exam_question.dart';

import '../data/models/entry_model.dart';
import 'dart:math';

class ExamGenerator {
  /// Generates a list of ExamQuestions from a list of word Entries
  static List<ExamQuestion> generate(List<Entry> entries) {
    final rand = Random();
    final questions = <ExamQuestion>[];
    final usedIds = <String>{};

    // MCQ for each entry
    for (final entry in entries) {
      // Pick 3 wrong meanings
      final wrongs = entries.where((e) => e.id != entry.id).toList()..shuffle(rand);
      final distractors = wrongs.take(3).map((e) => e.meaning).toList();

      final options = [...distractors, entry.meaning]..shuffle(rand);
      questions.add(
        ExamQuestion(
          id: 'mcq_${entry.id}',
          type: QuestionType.mcq,
          prompt: 'What is the meaning of "${entry.content}"?',
          options: options,
          correctAnswer: entry.meaning,
        ),
      );
      usedIds.add(entry.id);
    }

    // Simple "Complete" questions for 1/3 of words
    for (final entry in entries.take((entries.length / 3).ceil())) {
      if (entry.example.isNotEmpty) {
        final prompt = entry.example.replaceAll(entry.content, '______');
        if (prompt != entry.example) {
          questions.add(
            ExamQuestion(
              id: 'complete_${entry.id}',
              type: QuestionType.complete,
              prompt: 'Fill in the blank:\n$prompt',
              options: [],
              correctAnswer: entry.content,
            ),
          );
        }
      }
    }

    // Optional: add match questions if entries >= 6
    // if (entries.length >= 6) {
    //   final group = entries..shuffle(rand);
    //   final words = group.take(4).toList();
    //   questions.add(
    //     ExamQuestion(
    //       id: 'match_${words.map((e) => e.id).join("_")}',
    //       type: QuestionType.match,
    //       prompt: 'Match each word to its meaning.',
    //       options: words.map((e) => '${e.content}|${e.meaning}').toList(),
    //       correctAnswer: '', // matching is handled differently
    //     ),
    //   );
    // }

    questions.shuffle(rand);
    return questions;
  }
}
