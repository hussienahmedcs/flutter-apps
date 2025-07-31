# WordStory

WordStory is a mobile‑first, offline‑capable Progressive Web App (PWA) for
English learners to log vocabulary, practise words via flashcards and
quizzes, and create short stories using their newly learned terms.
The app is built with Flutter 3 and Firebase (Firestore, Auth,
Functions, Storage) and follows a modern Material 3 design with
gamification elements like XP, levels, streaks and achievements.

## Features

### Sessions

* Create, edit and delete learning sessions with a title, date and
  optional notes.
* Organise vocabulary entries (words, idioms and phrasal verbs) within
  each session.  Entries store their content, meaning, example and
  difficulty level (easy/medium/hard).
* Add entries manually via forms or use speech‑to‑text for voice
  input.  Bulk import via CSV is supported by extending the
  Firestore service.

### Practice & Review

* Flashcards with flip animations let you practise vocabulary across
  all sessions.  Tap a card to reveal the definition and example and
  swipe to move to the next card.  At the end of a review session
  you earn XP based on the number and type of entries reviewed.
* (Future) Quizzes with multiple choice questions and spaced
  repetition suggestions can be added in Phase 2.

### Story Builder

* Select a session and pick multiple words to include in a story.
* Automatically generate a writing prompt based on the selected
  vocabulary.
* Compose your story in a rich text editor and save it to your
  personal library.  Stories can be edited later and exported in
  future phases.

### Gamification

* Earn XP for adding vocabulary (+10 for words, +20 for idioms and
  phrasal verbs), completing reviews (+30), and writing stories
  (+50).
* Level up every 500 XP – your current level and progress are shown
  by a circular progress ring on the dashboard.
* Maintain a daily streak to keep learning consistently.  Tapping the
  streak indicator reveals a simple heatmap of your recent activity.
* Unlock achievements such as “First Word”, “100 Words”, “7‑Day
  Streak” and “First Story”.

### Profile & Settings

* View and edit your name, avatar and email.  Upload a new avatar
  using the file picker.
* Switch between system, light and dark themes.  Theme preferences are
  persisted locally.
* Browse your unlocked achievements on a dedicated grid.
* Sign out from the application.  Data export and sync toggles can be
  implemented in future phases.

## Getting Started

1. Ensure you have Flutter 3 installed.  This project targets Dart
   SDK ≥ 2.17.0.  Run `flutter pub get` to install dependencies.
2. Create a Firebase project and enable Email/Password and Google
   authentication providers.  Generate Firebase configuration files for
   web (`firebase_options.dart`) and add them to the project.
3. Run the application with `flutter run -d chrome`.  To build the
   PWA, run `flutter build web` and deploy the contents of the `build`
   directory to Firebase Hosting.

## Roadmap

The initial version covers sessions, flashcards and basic story
creation.  Future phases can extend functionality with quizzes,
advanced spaced repetition, cloud sync toggles, PDF/CSV export via
Firebase Functions, push notifications for streak reminders and AI‑
assisted story prompt generation."# flutter-apps" 
