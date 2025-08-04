import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wordstory/data/models/center.dart';
import 'package:wordstory/providers/app_auth_provider.dart';
import 'package:wordstory/screens/dashboard_screen.dart';

import '../data/models/entry_model.dart';
import '../providers/gamification_provider.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => FlashcardsScreenState();
}

class FlashcardsScreenState extends State<FlashcardsScreen> {
  List<Entry> _entries = [];
  List<String> _selectedSessionIds = [];
  List<Map<String, dynamic>> _sessions = [];

  int _currentIndex = 0;
  bool _loading = true;
  bool _error = false;
  int _earnedXp = 0;
  Role? role;
  bool showPrevBtn = false;
  bool showNextBtn = false;

  void reset() {
    if (!mounted) return;
    setState(() {
      _currentIndex = 0;
      _selectedSessionIds = [];
    });
  }

  @override
  void initState() {
    super.initState();
    role = Role.user;
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final user = Provider.of<AppAuthProvider>(context, listen: false).user;
    if (user == null) return;

    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .orderBy('date', descending: true)
        .get();

    if (!mounted) return;
    setState(() {
      _sessions = query.docs.map((doc) => {'id': doc.id, 'name': doc['title'] ?? 'Untitled'}).toList();
      _loading = false;
    });
  }

  Future<void> _loadEntries() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      print(Provider.of<AppAuthProvider>(context, listen: false).isLoggedIn);
      final user = Provider.of<AppAuthProvider>(context, listen: false).user;
      if (user == null) {
        setState(() {
          _entries = [];
          _loading = false;
        });
        return;
      }

      Query query = FirebaseFirestore.instance.collectionGroup('entries').where('user_id', isEqualTo: user.uid);
      if (_selectedSessionIds.isNotEmpty) {
        query = query.where('session_id', whereIn: _selectedSessionIds);
      }

      final querySnapshot = await query.get();
      if (!mounted) return;
      final entries =
          querySnapshot.docs.map((doc) => Entry.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
      entries.shuffle();

      setState(() {
        _entries = entries;
        _loading = false;
        _currentIndex = 0;
      });
    } catch (e) {
      print(e.toString());
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  void _finishSession() {
    int xp = 30;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flashcards"),
        actions: [],
      ),
      body: Builder(
        builder: (context) {
          if (_loading) return const Center(child: CircularProgressIndicator());

          if (_sessions.isEmpty) return _buildNoSessionsState(context);

          if (_entries.isEmpty && _selectedSessionIds.isNotEmpty) return _buildSessionHasNoWordsState(context);

          if (_entries.isEmpty && _selectedSessionIds.isEmpty) return _buildPromptSelectSessions(context);

          final isFinished = _currentIndex >= _entries.length;
          return isFinished ? _buildSummary(context) : _buildCard(context);
        },
      ),
    );
  }

  Widget _buildSessionChips({bool wrap = false}) {
    if (_sessions.isEmpty) return const SizedBox.shrink();

    return StatefulBuilder(
      builder: (context, setInnerState) {
        final chipList = _sessions.map((session) {
          final isSelected = _selectedSessionIds.contains(session['id']);
          return Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: FilterChip(
              label: Text(session['name']),
              selected: isSelected,
              showCheckmark: true,
              selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.18),
              checkmarkColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color:
                    isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (selected) {
                setInnerState(() {
                  if (selected) {
                    _selectedSessionIds.add(session['id']);
                  } else {
                    _selectedSessionIds.remove(session['id']);
                  }
                });
              },
            ),
          );
        }).toList();

        if (wrap) {
          return Column(
            children: [
              if (_selectedSessionIds.isNotEmpty)
                TextButton(
                  onPressed: _loadEntries,
                  child: const Text(
                    "Start",
                    // style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Wrap(spacing: 8, runSpacing: 8, children: chipList),
              ),
            ],
          );
        } else {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: chipList),
          );
        }
      },
    );
  }

  /// --- Other states (same as your code) ---
  Widget _buildPromptSelectSessions(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text('Select sessions to review cards.', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          _buildSessionChips(wrap: true),
        ],
      ),
    );
  }

  Widget _buildNoSessionsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('No sessions created yet!', style: TextStyle(fontSize: 18)),
          if (role == Role.admin) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/sessions');
              },
              child: const Text('Create your first session'),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSessionHasNoWordsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('This session is empty. Please add words first.', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/sessions');
            },
            child: const Text('Add Words to Session'),
          ),
        ],
      ),
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
        // Session Selector
        if (_sessions.isNotEmpty) ...[const SizedBox(height: 32), _buildSessionChips()],

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
          if (showPrevBtn || showNextBtn)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Previous Session'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Next Session'),
                ),
              ],
            )
        ],
      ),
    );
  }
}
