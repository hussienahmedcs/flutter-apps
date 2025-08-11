import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wordstory/data/interfaces/user_interface.dart';
import 'package:wordstory/providers/app_auth_provider.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../data/models/entry_model.dart';
import '../services/firestore_service.dart';
import '../providers/gamification_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_ocr_service.dart';
import 'dart:io';

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
  late TextEditingController _pronounceController;
  late EntryType _type;
  late Difficulty _difficulty;
  // final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isScanning = false;
  List<Entry> _ocrEntries = [];
  // final GamificationRepository _gamificationRepository = GamificationRepository();

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _contentController = TextEditingController(text: entry?.content ?? '');
    _meaningController = TextEditingController(text: entry?.meaning ?? '');
    _exampleController = TextEditingController(text: entry?.example ?? '');
    _pronounceController = TextEditingController(text: entry?.pronounce ?? '');
    _type = entry?.type ?? widget.type;
    _difficulty = entry?.difficulty ?? Difficulty.easy;
  }

  @override
  void dispose() {
    _contentController.dispose();
    _meaningController.dispose();
    _exampleController.dispose();
    _pronounceController.dispose();
    super.dispose();
  }

  Future<XFile?> _pickOrTakePhoto(BuildContext context) async {
    return showModalBottomSheet<XFile>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () async {
                  final picked = await ImagePicker().pickImage(source: ImageSource.camera);
                  Navigator.of(ctx).pop(picked);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pick from Gallery'),
                onTap: () async {
                  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                  Navigator.of(ctx).pop(picked);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _scanImage() async {
    final picked = await _pickOrTakePhoto(context);
    if (picked != null) {
      setState(() => _isScanning = true);

      final ocrService = GeminiOcrService(context: context);
      final List<Entry> entries = await ocrService.extractWordsFromImage(File(picked.path));

      setState(() {
        _isScanning = false;
        _ocrEntries = entries;
      });

      if (entries.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No words found.')),
        );
      }
    }
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

  void _save(UserInterface user) async {
    if (!_formKey.currentState!.validate()) return;
    final entry = Entry(
      id: widget.entry?.id ?? '',
      sessionId: widget.sessionId,
      type: _type,
      content: _contentController.text.trim(),
      meaning: _meaningController.text.trim(),
      pronounce: _pronounceController.text.trim(),
      example: _exampleController.text.trim(),
      difficulty: _difficulty,
      addedAt: widget.entry?.addedAt ?? DateTime.now(),
    );
    await FirestoreService().upsertEntry(user.uid, widget.sessionId, entry);
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

    //Clear Form
    setState(() {
      _contentController.clear();
      _meaningController.clear();
      _exampleController.clear();
      _pronounceController.clear();
    });
    // ignore: use_build_context_synchronously
    if (_ocrEntries.isEmpty) Navigator.of(context).pop();
  }

  void _showSavingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              const Text("Saving..."),
            ],
          ),
        ),
      ),
    );
  }

  void _hideSavingDialog() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _saveAll(UserInterface user) async {
    if (_ocrEntries.isEmpty) return;

    _showSavingDialog(); // Show loader

    try {
      // final uid = Provider.of<SessionProvider>(context, listen: false).sessions.first.userId;

      final service = FirestoreService();
      final gamification = Provider.of<GamificationProvider>(context, listen: false);
      int totalXp = 0;

      for (final entry in _ocrEntries) {
        final newEntry = Entry(
          id: '', // Let Firestore assign ID
          sessionId: widget.sessionId,
          type: EntryType.values
              .firstWhere((e) => e.name == entry.type, orElse: () => _type), // Or EntryType.word if you want fixed type
          content: entry.content,
          meaning: entry.meaning,
          pronounce: entry.pronounce,
          example: entry.example,
          difficulty: _difficulty,
          addedAt: DateTime.now(),
        );
        await FirestoreService().upsertEntry(user.uid, widget.sessionId, newEntry);
        // totalXp += newEntry.type == EntryType.word ? 10 : 20;
      }

      gamification.addXp(totalXp);
      gamification.registerDailyActivity();

      setState(() {
        _ocrEntries.clear();
      });

      // Optionally, show a confirmation/snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("All scanned entries saved!")),
      );
      Navigator.of(context).pop();
    } finally {
      _hideSavingDialog(); // Always hide loader, even on error
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().user!;

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
                  suffixIcon: widget.entry == null
                      ? IconButton(
                          icon: Icon(Icons.image_search),
                          onPressed: _scanImage,
                        )
                      : null,
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
                controller: _pronounceController,
                decoration: InputDecoration(
                  labelText: 'Pronunciation',
                  prefixIcon: const Icon(Icons.volume_up, color: Colors.blueGrey, size: 20),
                  border: const OutlineInputBorder(),
                ),
                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 16),
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
                onPressed: () => _save(user),
                child: Text(_ocrEntries.isNotEmpty ? 'Save & Next' : 'Save'),
              ),
              if (_ocrEntries.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Save All Scanned Entries'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () => _saveAll(user),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  "Scanned Entries:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _ocrEntries.length,
                  itemBuilder: (context, index) {
                    final entry = _ocrEntries[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.content, style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (entry.pronounce.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  entry.pronounce,
                                  style: const TextStyle(
                                      fontStyle: FontStyle.italic, color: Colors.blueGrey, fontSize: 14),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Meaning: ${entry.meaning}"),
                            if (entry.example.isNotEmpty) Text("Example: ${entry.example}"),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: "Delete",
                              onPressed: () {
                                setState(() => _ocrEntries.removeAt(index));
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.download, color: Colors.blue),
                              tooltip: "Use",
                              onPressed: () {
                                setState(() {
                                  _contentController.text = entry.content;
                                  _meaningController.text = entry.meaning;
                                  _pronounceController.text = entry.pronounce;
                                  _exampleController.text = entry.example;
                                  _ocrEntries.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
