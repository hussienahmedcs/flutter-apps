import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wordstory/screens/dashboard_screen.dart';

import '../models/entry_model.dart';
import '../providers/auth_provider.dart';
import '../providers/gamification_provider.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  List<Entry> _entries = [];
  List<String> _selectedSessionIds = [];
  int _currentIndex = 0;
  bool _loading = true;
  bool _error = false;
  int _earnedXp = 0;

  @override
  void initState() {
    super.initState();
    _loadEntries();
    // _showSessionSelector();
  }

  /// Step 1: Show a dialog with multi-select session checkboxes
  Future<void> _showSessionSelector() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    final sessionsSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('sessions').get();

    final allSessions =
        sessionsSnapshot.docs.map((doc) => {'id': doc.id, 'title': doc['title'] ?? 'Untitled'}).toList();

    List<String> tempSelected = List.from(_selectedSessionIds);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Select Sessions"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allSessions.length,
              itemBuilder: (context, index) {
                final session = allSessions[index];
                return CheckboxListTile(
                  title: Text(session['title']),
                  value: tempSelected.contains(session['id']),
                  onChanged: (selected) {
                    setState(() {
                      if (selected == true) {
                        tempSelected.add(session['id']);
                      } else {
                        tempSelected.remove(session['id']);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (tempSelected.isEmpty) return;
                setState(() {
                  _selectedSessionIds = tempSelected;
                });
                Navigator.of(ctx).pop();
                _loadEntries();
              },
              child: const Text("Load"),
            )
          ],
        );
      },
    );
  }

  /// Step 2: Load entries only from selected sessions
  Future<void> _loadEntries() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) {
        setState(() {
          _entries = [];
          _loading = false;
        });
        return;
      }

      // Start building the query
      Query query = FirebaseFirestore.instance.collectionGroup('entries').where('user_id', isEqualTo: user.uid);

      // Add session filter only if selectedSessionIds is not empty
      if (_selectedSessionIds.isNotEmpty) {
        query = query.where('session_id', whereIn: _selectedSessionIds);
      }

      final querySnapshot = await query.get();
      final entries =
          querySnapshot.docs.map((doc) => Entry.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
      entries.shuffle();
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  void _finishSession() {
    int xp = 30; // base reward
    for (final entry in _entries) {
      xp += entry.type == EntryType.word ? 10 : 20;
    }
    setState(() {
      _earnedXp = xp;
      _currentIndex = _entries.length;
    });

    final gamification = Provider.of<GamificationProvider>(context, listen: false);
    gamification.addXp(xp);
    gamification.registerDailyActivity();
  }

  @override
  Widget build(BuildContext context) {
    final total = _entries.length;
    final isFinished = _currentIndex >= total;

    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error
              ? _buildErrorState()
              : _entries.isEmpty
                  ? _buildEmptyState()
                  : isFinished
                      ? _buildSummary(context)
                      : _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    final entry = _entries[_currentIndex];
    final difficultyColor = {
      Difficulty.easy: Colors.green,
      Difficulty.medium: Colors.orange,
      Difficulty.hard: Colors.red
    }[entry.difficulty]!;

    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: (_currentIndex + 1) / _entries.length,
          minHeight: 4,
          backgroundColor: Colors.grey[300],
          color: Theme.of(context).primaryColor,
        ),
        // Flip card
        Expanded(
          child: Center(
            child: FlipCard(
              direction: FlipDirection.HORIZONTAL,
              front: _buildFront(entry, difficultyColor),
              back: _buildBack(entry, difficultyColor),
            ),
          ),
        ),
        // Navigation row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous button
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 28),
                color: _currentIndex > 0 ? Theme.of(context).primaryColor : Colors.grey,
                onPressed: _currentIndex > 0
                    ? () {
                        setState(() {
                          _currentIndex--;
                        });
                      }
                    : null,
                tooltip: "Previous Card",
              ),
              // Counter
              Text(
                "${_currentIndex + 1} / ${_entries.length}",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              // Next button
              IconButton(
                icon: Icon(
                  _currentIndex + 1 >= _entries.length ? Icons.check_circle_outline : Icons.arrow_forward_ios_rounded,
                  size: 28,
                ),
                color: Theme.of(context).primaryColor,
                onPressed: () {
                  if (_currentIndex + 1 >= _entries.length) {
                    _finishSession();
                  } else {
                    setState(() {
                      _currentIndex++;
                    });
                  }
                },
                tooltip: _currentIndex + 1 >= _entries.length ? "Finish" : "Next Card",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFront(Entry entry, Color difficultyColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _difficultyBadge(difficultyColor, entry),
            const SizedBox(height: 16),
            Text(
              entry.content,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text('${_currentIndex + 1} / ${_entries.length}'),
          ],
        ),
      ),
    );
  }

  Widget _buildBack(Entry entry, Color difficultyColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _difficultyBadge(difficultyColor, entry),
            const SizedBox(height: 16),
            Text(
              entry.meaning,
              style: const TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            if (entry.example.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                entry.example,
                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            Text('${_currentIndex + 1} / ${_entries.length}'),
          ],
        ),
      ),
    );
  }

  Widget _difficultyBadge(Color color, Entry entry) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        entry.difficulty.toString().split('.').last,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Session Complete!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text('You reviewed ${_entries.length} items and earned $_earnedXp XP.'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (Navigator.of(context).canPop())
                Navigator.of(context).pop();
              else {
                DashboardScreen.switchToHome(context);
                setState(() {
                  _currentIndex = 0;
                });
              }
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('No entries to review.', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadEntries,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Failed to load entries.', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadEntries,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
