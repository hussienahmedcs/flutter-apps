import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models/session_model.dart';
import '../providers/session_provider.dart';
import 'add_edit_session_screen.dart';
import 'session_detail_screen.dart';

/// Enum used to trigger the initial tab on [SessionsListScreen].  If
/// [add] is supplied, the screen will automatically navigate to the
/// session creation page when built.
enum SessionsTabType { list, add }

/// Displays the user's sessions as a scrollable list.  A floating
/// action button allows the user to create a new session.  Long
/// pressing on a session reveals options to edit or delete it.
class SessionsListScreen extends StatefulWidget {
  final SessionsTabType initialTab;
  const SessionsListScreen({super.key, this.initialTab = SessionsTabType.list});

  @override
  State<SessionsListScreen> createState() => _SessionsListScreenState();
}

class _SessionsListScreenState extends State<SessionsListScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialTab == SessionsTabType.add) {
      // Delay the navigation until after the first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openSessionForm();
      });
    }
  }

  void _openSessionForm([Session? session]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditSessionScreen(session: session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();
    final sessions = sessionProvider.sessions;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessions'),
      ),
      body: sessions.isEmpty
          ? Center(
              child: Text(
                'No sessions yet. Tap the + button to create one!',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    title: Text(session.title),
                    subtitle: Text(session.date.toLocal().toString().split(' ').first),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _openSessionForm(session);
                        } else if (value == 'delete') {
                          _deleteSession(sessionProvider, session);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SessionDetailScreen(session: session),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openSessionForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _deleteSession(SessionProvider provider, Session session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text('Are you sure you want to delete "${session.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await provider.deleteSession(session.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
