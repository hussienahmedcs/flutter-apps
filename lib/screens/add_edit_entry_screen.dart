import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/entry_model.dart';
import '../providers/session_provider.dart';
import '../services/firestore_service.dart';
import '../providers/gamification_provider.dart';

/// Form for creating or editing a vocabulary entry.  The user chooses
/// the type (word/idiom/phrasal verb), provides the term, its
/// meaning, an example sentence and selects a difficulty level.  A
/// microphone button allows voice input for the term using the
/// `speech_to_text` plugin.
class AddEditEntryScreen extends StatefulWidget {
  final String sessionId;
  final Entry? entry;
  final EntryType type;
  const AddEditEntryScreen({super.key, required this.sessionId, this.entry, this.type = EntryType.word});

  @override
  State<AddEditEntryScreen> createState() => _AddEditEntryScreenState();
}

class _AddEditEntryScreenState extends State<AddEditEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _contentController;
  late TextEditingController _meaningController;
  late TextEditingController _exampleController;
  late EntryType _type;
  late Difficulty _difficulty;
  // final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _contentController = TextEditingController(text: entry?.content ?? '');
    _meaningController = TextEditingController(text: entry?.meaning ?? '');
    _exampleController = TextEditingController(text: entry?.example ?? '');
    _type = entry?.type ?? widget.type;
    _difficulty = entry?.difficulty ?? Difficulty.easy;
  }

  @override
  void dispose() {
    _contentController.dispose();
    _meaningController.dispose();
    _exampleController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    // bool available = await _speech.initialize(onStatus: (status) {
    //   if (status == 'done') {
    //     setState(() => _isListening = false);
    //   }
    // }, onError: (error) {
    //   setState(() => _isListening = false);
    // });
    // if (available) {
    //   setState(() => _isListening = true);
    //   // _speech.listen(onResult: (val) {
    //   //   setState(() {
    //   //     _contentController.text = val.recognizedWords;
    //   //   });
    //   // });
    // }
  }

  void _stopListening() {
    // _speech.stop();
    setState(() => _isListening = false);
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = Provider.of<SessionProvider>(context, listen: false)
        .sessions
        .first
        .userId; // assuming at least one session has userId
    final entry = Entry(
      id: widget.entry?.id ?? '',
      sessionId: widget.sessionId,
      type: _type,
      content: _contentController.text.trim(),
      meaning: _meaningController.text.trim(),
      example: _exampleController.text.trim(),
      difficulty: _difficulty,
      addedAt: widget.entry?.addedAt ?? DateTime.now(),
    );
    final service = FirestoreService();
    await service.upsertEntry(uid, widget.sessionId, entry);
    // Award XP based on entry type
    // ignore: use_build_context_synchronously
    final gamification = Provider.of<GamificationProvider>(context, listen: false);
    int xp = 0;
    if (entry.type == EntryType.word) {
      xp = 10;
    } else {
      xp = 20;
    }
    gamification.addXp(xp);
    gamification.registerDailyActivity();
    // ignore: use_build_context_synchronously
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? 'Add Entry' : 'Edit Entry'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<EntryType>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: EntryType.values
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.toString().split('.').last),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _type = val);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: 'Content',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                    onPressed: _isListening ? _stopListening : _startListening,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Enter the word or phrase';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _meaningController,
                decoration: const InputDecoration(
                  labelText: 'Meaning',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Enter the meaning';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _exampleController,
                decoration: const InputDecoration(
                  labelText: 'Example (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Difficulty>(
                value: _difficulty,
                decoration: const InputDecoration(
                  labelText: 'Difficulty',
                  border: OutlineInputBorder(),
                ),
                items: Difficulty.values
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.toString().split('.').last),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _difficulty = val);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
