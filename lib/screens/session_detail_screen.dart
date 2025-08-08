import 'package:flutter/material.dart';
import 'package:wordstory/data/repositories/session_repository.dart';
import '../data/models/entry_model.dart';
import 'add_edit_entry_screen.dart';
import '../data/models/session_model.dart';

/// Shows the details for a specific session, including all entries
/// grouped by type (word, idiom, phrasal verb).  Users can add new
/// entries via the floating action button and edit or delete existing
/// entries from the list.  Entries are loaded from Firestore in
/// real time.
class SessionDetailScreen extends StatefulWidget {
  final Session session;
  const SessionDetailScreen({super.key, required this.session});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> with SingleTickerProviderStateMixin {
  int _currentTab = 0;
  final Set<String> _selectedEntryIds = {}; // Store IDs of selected entries
  bool get _isSelectionMode => _selectedEntryIds.isNotEmpty;
  final SessionRepository _sessionRepository = SessionRepository();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController.index != _currentTab) {
      setState(() {
        _currentTab = _tabController.index;
        _selectedEntryIds.clear(); // Reset selection on tab change
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final user = context.watch<AppAuthProvider>().user;
    // if (user == null) {
    //   return const Scaffold(body: Center(child: Text('Not authenticated')));
    // }



    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode ? Text('Delete (${_selectedEntryIds.length})') : Text(widget.session.title),
        bottom: !_isSelectionMode
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Words'),
                  Tab(text: 'Idioms'),
                  Tab(text: 'Phrasal Verbs'),
                ],
              )
            : null,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                // Confirm deletion
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Selected?'),
                    content: Text('Are you sure you want to delete ${_selectedEntryIds.length} entries?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                    ],
                  ),
                );
                if (confirm == true) {
                  for (final entryId in _selectedEntryIds) {
                    await _sessionRepository.deleteEntry(widget.session.userId, widget.session.id, entryId);
                  }
                  setState(() => _selectedEntryIds.clear());
                }
              },
            ),
        ],
      ),
      body: StreamBuilder<List<Entry>>(
        stream: _sessionRepository.watchEntries(widget.session.userId, widget.session.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snapshot.data ?? [];
          final words = entries.where((e) => e.type == EntryType.word).toList();
          final idioms = entries.where((e) => e.type == EntryType.idiom).toList();
          final phrasals = entries.where((e) => e.type == EntryType.phrasal).toList();
          return TabBarView(
            controller: _tabController,
            children: [
              _buildEntriesList(context, widget.session.userId, widget.session.id, words),
              _buildEntriesList(context, widget.session.userId, widget.session.id, idioms),
              _buildEntriesList(context, widget.session.userId, widget.session.id, phrasals),
            ],
          );
        },
      ),
      floatingActionButton: !_isSelectionMode && !widget.session.isShared
          ? Builder(
              builder: (innerContext) {
                return FloatingActionButton(
                  onPressed: () {
                    final tabIndex = _tabController.index;
                    final entryType = [EntryType.word, EntryType.idiom, EntryType.phrasal][tabIndex];
                    Navigator.of(innerContext).push(
                      MaterialPageRoute(
                        builder: (_) => AddEditEntryScreen(sessionId: widget.session.id, type: entryType),
                      ),
                    );
                  },
                  child: const Icon(Icons.add),
                );
              },
            )
          : null,
    );
  }

  Widget _buildEntriesList(BuildContext context, String uid, String sessionId, List<Entry> entries) {
    // final service = FirestoreService();
    if (entries.isEmpty) {
      return Center(
        child: Text('No entries yet. Tap the + button to add.'),
      );
    }
    return ListView.builder(
      key: PageStorageKey('entriesList_$_currentTab'),
      padding: const EdgeInsets.all(8),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final selected = _selectedEntryIds.contains(entry.id);

        return GestureDetector(
          onLongPress: () {
            if (!widget.session.isShared) {
              setState(() {
                _selectedEntryIds.add(entry.id);
              });
            }
          },
          onTap: () {
            if (widget.session.isShared) return;
            if (_isSelectionMode) {
              setState(() {
                if (selected) {
                  _selectedEntryIds.remove(entry.id);
                } else {
                  _selectedEntryIds.add(entry.id);
                }
              });
            } else {
              // Open edit dialog as usual
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddEditEntryScreen(sessionId: sessionId, entry: entry),
                ),
              );
            }
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: selected ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2) : BorderSide.none,
            ),
            color: selected ? Theme.of(context).colorScheme.primary.withOpacity(0.08) : null,
            child: ListTile(
              leading: _isSelectionMode
                  ? Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: selected ? Theme.of(context).colorScheme.primary : null)
                  : null,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.content, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (entry.pronounce.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        entry.pronounce,
                        style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blueGrey, fontSize: 14),
                      ),
                    ),
                ],
              ),
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
              trailing: !_isSelectionMode && !widget.session.isShared
                  ? PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AddEditEntryScreen(sessionId: sessionId, entry: entry),
                            ),
                          );
                          
                        } else if (value == 'delete') {
                          await _sessionRepository.deleteEntry(uid, sessionId, entry.id);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }
}
