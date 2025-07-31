import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/entry_model.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import 'add_edit_entry_screen.dart';

/// Shows the details for a specific session, including all entries
/// grouped by type (word, idiom, phrasal verb).  Users can add new
/// entries via the floating action button and edit or delete existing
/// entries from the list.  Entries are loaded from Firestore in
/// real time.
class SessionDetailScreen extends StatelessWidget {
  final String sessionId;
  const SessionDetailScreen({Key? key, required this.sessionId}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }
    final firestoreService = FirestoreService();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Session Details'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Words'),
              Tab(text: 'Idioms'),
              Tab(text: 'Phrasal Verbs'),
            ],
          ),
        ),
        body: StreamBuilder<List<Entry>>(
          stream: firestoreService.watchEntries(user.uid, sessionId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final entries = snapshot.data ?? [];
            final words = entries.where((e) => e.type == EntryType.word).toList();
            final idioms = entries.where((e) => e.type == EntryType.idiom).toList();
            final phrasals = entries.where((e) => e.type == EntryType.phrasal).toList();
            return TabBarView(
              children: [
                _buildEntriesList(context, user.uid, sessionId, words),
                _buildEntriesList(context, user.uid, sessionId, idioms),
                _buildEntriesList(context, user.uid, sessionId, phrasals),
              ],
            );
          },
        ),
        floatingActionButton: Builder(
          builder: (innerContext) {
            return FloatingActionButton(
              onPressed: () {
                final tabIndex = DefaultTabController.of(innerContext)?.index ?? 0;
                final entryType = [EntryType.word, EntryType.idiom, EntryType.phrasal][tabIndex];
                Navigator.of(innerContext).push(
                  MaterialPageRoute(
                    builder: (_) => AddEditEntryScreen(sessionId: sessionId, type: entryType),
                  ),
                );
              },
              child: const Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEntriesList(BuildContext context, String uid, String sessionId, List<Entry> entries) {
    final service = FirestoreService();
    if (entries.isEmpty) {
      return Center(
        child: Text('No entries yet. Tap the + button to add.'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(entry.content),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.meaning),
                if (entry.example.isNotEmpty)
                  Text(
                    '"${entry.example}"',
                    style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                  ),
                Text('Difficulty: ${entry.difficulty.toString().split('.').last}'),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddEditEntryScreen(sessionId: sessionId, entry: entry),
                    ),
                  );
                } else if (value == 'delete') {
                  await service.deleteEntry(uid, sessionId, entry.id);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
        );
      },
    );
  }
}
