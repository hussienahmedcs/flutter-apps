import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wordstory/data/repositories/session_repository.dart';
import '../data/models/session_model.dart';
import '../data/models/story_model.dart';
import '../data/models/entry_model.dart';
import '../providers/app_auth_provider.dart';
import '../services/firestore_service.dart';
import '../services/gemini_ocr_service.dart'; // Your Gemini/GPT AI service

class StoryBuilderScreen extends StatefulWidget {
  final String? editStoryId;
  const StoryBuilderScreen({Key? key, this.editStoryId}) : super(key: key);

  @override
  State<StoryBuilderScreen> createState() => _StoryBuilderScreenState();
}

class _StoryBuilderScreenState extends State<StoryBuilderScreen> {
  List<String> _selectedSessionIds = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _loadingStory = false;
  bool _editingExisting = false;
  Story? _editingStory;
  final SessionRepository _sessionRepository = SessionRepository();

  @override
  void initState() {
    super.initState();
    if (widget.editStoryId != null) {
      _editingExisting = true;
      // final storyProvider = Provider.of<StoryProvider>(context, listen: false);
      final story = //storyProvider.stories.firstWhere((s) => s.id == widget.editStoryId, orElse: () =>
          Story(
        id: '',
        sessionId: '',
        title: '',
        content: '',
        usedWords: [],
        createdAt: DateTime.now(),
        //)
      );
      _editingStory = story;
      _titleController.text = story.title;
      _contentController.text = story.content;
      _topicController.text = ""; // Optionally load a previous topic
      if (story.sessionId.isNotEmpty) {
        _selectedSessionIds = [story.sessionId];
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _topicController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Widget _buildSessionSelector(List<Session> allSessions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Sessions", style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: allSessions.map((session) {
            final selected = _selectedSessionIds.contains(session.id);
            return FilterChip(
              label: Text(session.title),
              selected: selected,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedSessionIds.add(session.id);
                  } else {
                    _selectedSessionIds.remove(session.id);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _generateAIStory() async {
    final topic = _topicController.text.trim();
    if (_selectedSessionIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select session(s)')),
      );
      return;
    }

    setState(() => _loadingStory = true);

    try {
      // Fetch all words from the selected sessions
      final user = Provider.of<AppAuthProvider>(context, listen: false).user;
      if (user == null) return;

      final service = FirestoreService();
      Set<String> allWords = {};

      for (final sessionId in _selectedSessionIds) {
        final entries = await _sessionRepository.getEntries(user.uid, sessionId);
        allWords.addAll(entries.where((e) => e.type == EntryType.word).map((e) => e.content));
      }

      if (allWords.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No words found in selected sessions.')),
        );
        setState(() => _loadingStory = false);
        return;
      }

      // Compose AI prompt
      final prompt =
          "Write a short story for English beginner learners, with a reading time of 3 to 7 minutes and max 450 words, ${topic.isEmpty ? "" : "about \"$topic\""}. You must include ALL of the following words: ${allWords.join(', ')}.";

      // Call your AI story API (replace with your Gemini/GPT service)
      final aiService = GeminiOcrService(context: context);
      final storyText = await aiService.generateStoryFromPrompt(prompt);

      setState(() {
        _contentController.text = storyText;
      });
    } finally {
      setState(() => _loadingStory = false);
    }
  }

  void _saveStory() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty || _selectedSessionIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in title, select session(s), and write story content.')),
      );
      return;
    }
    final user = Provider.of<AppAuthProvider>(context, listen: false).user;
    if (user == null) return;
    // final storyProvider = Provider.of<StoryProvider>(context, listen: false);

    // final story = Story(
    //   id: widget.editStoryId ?? '',
    //   sessionId: _selectedSessionIds.join(','), // You may wish to support multiple in your model!
    //   title: title,
    //   content: content,
    //   usedWords: [], // You can extract which words were used in the story for stats
    //   createdAt: widget.editStoryId != null
    //       ? storyProvider.stories.firstWhere((s) => s.id == widget.editStoryId!).createdAt
    //       : DateTime.now(),
    // );
    // await storyProvider.saveStory(story);
    // XP logic here, if needed
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final List<Session> sessions = []; //context.watch<SessionProvider>().sessions;
    return Scaffold(
      appBar: AppBar(
        title: Text(_editingExisting ? 'Edit Story' : 'New Story'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _buildSessionSelector(sessions),
            const SizedBox(height: 16),
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(
                labelText: 'Story about… (topic/theme)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.auto_stories),
              label: const Text("Generate Story with AI"),
              onPressed: _loadingStory ? null : _generateAIStory,
            ),
            if (_loadingStory)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Your Story',
                border: OutlineInputBorder(),
              ),
              minLines: 8,
              maxLines: null,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _saveStory,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
