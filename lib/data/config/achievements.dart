import '../models/achievement_model.dart';

/// Defines the catalogue of achievements available in the app.  When
/// certain milestones are reached the corresponding ID is added to
/// the user's gamification record.  Icons are left null here and
/// should be associated in the UI as desired.
final List<Achievement> achievementsCatalog = [
  Achievement(
    id: 'first_word',
    title: 'First Word',
    description: 'Add your first word to a session.',
  ),
  Achievement(
    id: 'hundred_words',
    title: 'Word Collector',
    description: 'Add 100 words.',
  ),
  Achievement(
    id: 'seven_day_streak',
    title: '7‑Day Streak',
    description: 'Study for 7 days in a row.',
  ),
  Achievement(
    id: 'first_story',
    title: 'Storyteller',
    description: 'Write your first story.',
  ),
];