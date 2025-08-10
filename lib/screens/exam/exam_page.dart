import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wordstory/data/interfaces/user_interface.dart';
import 'package:wordstory/data/models/entry_model.dart';
import 'package:wordstory/data/models/session_model.dart';
import 'package:wordstory/data/repositories/session_repository.dart';
import 'package:wordstory/providers/app_auth_provider.dart';
import 'package:wordstory/services/firestore_service.dart';
import 'exam_take_page.dart';
import 'package:intl/intl.dart';

class ExamPage extends StatefulWidget {
  const ExamPage({super.key});

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  final Set<String> _selectedSessionIds = {};
  final SessionRepository _sessionRepository = SessionRepository();
  UserInterface? user;
  bool _loading = true;
  List<String>? ids;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loader();
  }

  Future<void> loader() async {
    user = Provider.of<AppAuthProvider>(context, listen: false).user;
    if (user != null) {
      ids = await _sessionRepository.getSessionOwnersIds(user!);
    }
    // final firestoreService = FirestoreService();
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Exam'),
      ),
      body: _loading == true
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? const Center(child: Text('Not authenticated'))
              : StreamBuilder<List<Session>>(
                  stream: _sessionRepository.watchSessions(ids ?? []),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final sessions = snapshot.data ?? [];
                    if (sessions.isEmpty) {
                      return const Center(child: Text('No sessions found.'));
                    }
                    return ListView.builder(
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        final isSelected = _selectedSessionIds.contains(session.id);
                        return ListTile(
                          title: Text(session.title),
                          subtitle: Text(
                            '${session.wordEntries.length} words — ${DateFormat('dd/MM/yyyy').format(session.date)}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          leading: Checkbox(
                            value: isSelected,
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedSessionIds.add(session.id);
                                } else {
                                  _selectedSessionIds.remove(session.id);
                                }
                              });
                            },
                          ),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedSessionIds.remove(session.id);
                              } else {
                                _selectedSessionIds.add(session.id);
                              }
                            });
                          },
                        );
                      },
                    );
                  },
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Exam'),
            onPressed: _selectedSessionIds.isEmpty
                ? null
                : () async {
                    // Fetch all entries for selected sessions
                    final user = Provider.of<AppAuthProvider>(context, listen: false).user;
                    final List<Entry> allEntries = [];
                    for (final sessionId in _selectedSessionIds) {
                      final entries = await _sessionRepository.getEntries(user!.uid, sessionId);
                      allEntries.addAll(entries.where((e) => e.type == EntryType.word));
                    }
                    if (allEntries.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No words found in selected sessions.')),
                      );
                      return;
                    }
                    // Go to exam-taking page
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ExamTakePage(entries: allEntries),
                    ));
                  },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ),
    );
  }
}
