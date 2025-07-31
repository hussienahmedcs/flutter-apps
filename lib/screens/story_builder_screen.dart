import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wordstory/providers/gamification_provider.dart';
import '../models/session_model.dart';
import '../models/story_model.dart';
import '../models/entry_model.dart';
import '../providers/session_provider.dart';
import '../providers/story_provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';

/// Screen where users can craft stories using vocabulary from their
/// sessions.  The user selects a session, picks words as chips,
/// optionally generates a writing prompt and writes the story in a
/// multiline text field.  Stories can be created or edited.
class StoryBuilderScreen extends StatefulWidget {
  final String? editStoryId;
  const StoryBuilderScreen({Key? key, this.editStoryId}) : super(key: key);

  @override
  State<StoryBuilderScreen> createState() => _StoryBuilderScreenState();
}

class _StoryBuilderScreenState extends State<StoryBuilderScreen> {
  String? _selectedSessionId;
  final List<Entry> _sessionEntries = [];
  final List<Entry> _selectedEntries = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _loadingEntries = false;
  bool _editingExisting = false;

  @override
  void initState() {
    super.initState();
    if (widget.editStoryId != null) {
      _editingExisting = true;
      final storyProvider = Provider.of<StoryProvider>(context, listen: false);
      final story = storyProvider.stories.firstWhere(
          (s) => s.id == widget.editStoryId,
          orElse: () => Story(
              id: '',
              sessionId: '',
              title: '',
              content: '',
              usedWords: [],
              createdAt: DateTime.now()));
      _titleController.text = story.title;
      _contentController.text = story.content;
      _selectedSessionId = story.sessionId;
      // we will load entries later when session is selected
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _loadEntries(String sessionId) async {
    setState(() {
      _loadingEntries = true;
      _sessionEntries.clear();
      _selectedEntries.clear();
    });
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;
    final service = FirestoreService();
    final entriesStream = service.watchEntries(user.uid, sessionId);
    // subscribe once and take first snapshot
    entriesStream.first.then((entries) {
      setState(() {
        _sessionEntries.addAll(entries.where((e) => e.type == EntryType.word));
        // Pre-select entries if editing existing story
        if (_editingExisting) {
          final storyProvider = Provider.of<StoryProvider>(context, listen: false);
          final story = storyProvider.stories.firstWhere(
              (s) => s.id == widget.editStoryId,
              orElse: () => Story(
                  id: '',
                  sessionId: '',
                  title: '',
                  content: '',
                  usedWords: [],
                  createdAt: DateTime.now()));
          for (final entry in _sessionEntries) {
            if (story.usedWords.contains(entry.id)) {
              _selectedEntries.add(entry);
            }
          }
        }
        _loadingEntries = false;
      });
    });
  }

  void _toggleSelected(Entry entry) {
    setState(() {
      if (_selectedEntries.contains(entry)) {
        _selectedEntries.remove(entry);
      } else {
        _selectedEntries.add(entry);
      }
    });
  }

  void _generatePrompt() {
    if (_selectedEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one word to generate a prompt.')),
      );
      return;
    }
    final words = _selectedEntries.map((e) => e.content).join(', ');
    final prompt = 'Write a short story that includes the following words: $words.';
    setState(() {
      _contentController.text = prompt;
    });
  }

  void _saveStory() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty || _selectedSessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in title, select session and write content.')),
      );
      return;
    }
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;
    final storyProvider = Provider.of<StoryProvider>(context, listen: false);
    final story = Story(
      id: widget.editStoryId ?? '',
      sessionId: _selectedSessionId!,
      title: title,
      content: content,
      usedWords: _selectedEntries.map((e) => e.id).toList(),
      createdAt: widget.editStoryId != null
          ? storyProvider.stories
              .firstWhere((s) => s.id == widget.editStoryId!)
              .createdAt
          : DateTime.now(),
    );
    final id = await storyProvider.saveStory(story);
    // award XP for writing story
    final gamification = Provider.of<GamificationProvider>(context, listen: false);
    if (!_editingExisting) {
      // new story: +50 XP
      gamification.addXp(50);
      gamification.registerDailyActivity();
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<SessionProvider>().sessions;
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
            DropdownButtonFormField<String>(
              value: _selectedSessionId,
              decoration: const InputDecoration(
                labelText: 'Select Session',
                border: OutlineInputBorder(),
              ),
              items: sessions
                  .map((session) => DropdownMenuItem(
                        value: session.id,
                        child: Text(session.title),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedSessionId = val;
                  });
                  _loadEntries(val);
                }
              },
            ),
            const SizedBox(height: 16),
            if (_loadingEntries)
              const Center(child: CircularProgressIndicator()),
            if (_selectedSessionId != null && !_loadingEntries)
              Wrap(
                spacing: 8,
                children: _sessionEntries
                    .map(
                      (entry) => ChoiceChip(
                        label: Text(entry.content),
                        selected: _selectedEntries.contains(entry),
                        onSelected: (_) => _toggleSelected(entry),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Story',
                border: OutlineInputBorder(),
              ),
              minLines: 6,
              maxLines: null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _generatePrompt,
                  child: const Text('Generate Prompt'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveStory,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}