import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wordstory/models/session_model.dart';

import '../providers/gamification_provider.dart';
import '../providers/session_provider.dart';
import '../providers/story_provider.dart';
import '../widgets/xp_progress_ring.dart';
import '../widgets/streak_counter.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/recent_activity_feed.dart';
import './flashcards_screen.dart';
import 'sessions_list_screen.dart';
import 'session_detail_screen.dart';
import 'story_builder_screen.dart';
import 'my_stories_screen.dart';
import 'profile_screen.dart';

/// Root screen shown after the user authenticates.  A bottom navigation
/// bar allows switching between the home dashboard, sessions list,
/// practice module, stories list and profile.  Each tab is
/// implemented as a separate widget to keep the build method clean.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  static void switchToHome(BuildContext context) {
    final state = context.findAncestorStateOfType<_DashboardScreenState>();
    state?.switchTab(0);
  }

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _index = 0;
  DateTime? _lastBackPress;

  void switchTab(int index) {
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<FlashcardsScreenState> flashcardKey = GlobalKey<FlashcardsScreenState>();
    final List<Map<String, dynamic>> pages = [
      {"screen": const _HomeTab(), "key": null},
      {"screen": const SessionsListScreen(), "key": null},
      {"screen": FlashcardsScreen(key: flashcardKey), "key": flashcardKey},
      {"screen": const MyStoriesScreen(), "key": null},
      {"screen": const ProfileScreen(), "key": null},
    ];

    return WillPopScope(
      onWillPop: () async {
        if (_index != 0) {
          // Go back to Home tab instead of exiting
          setState(() {
            _index = 0;
          });
          return false;
        }

        // Double back to exit
        final now = DateTime.now();
        if (_lastBackPress == null || now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Press back again to exit')),
          );
          return false;
        }
        return true; // Exit app
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: pages.map((e) => e['screen'] as Widget).toList(),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _index,
          onTap: (value) {
            setState(() {
              _index = value;
            });
            final key = pages[value]['key'];
            if (key != null && key.currentState != null) {
              key.currentState!.reset();
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_note),
              label: 'Sessions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.style),
              label: 'Practice',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books),
              label: 'Stories',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

/// The home tab shows the XP ring, streak counter, quick actions and
/// recent activity.  It listens to the relevant providers and
/// displays their state.  Tapping on sessions or stories in the
/// recent feed navigates to their detail pages using a
/// `Navigator.push` call on the root context.
class _HomeTab extends StatelessWidget {
  const _HomeTab({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final gamification = context.watch<GamificationProvider>().stats;
    final sessions = context.watch<SessionProvider>().sessions;
    final stories = context.watch<StoryProvider>().stories;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              XPProgressRing(stats: gamification),
              StreakCounter(stats: gamification),
            ],
          ),
          const SizedBox(height: 16),
          QuickActionsGrid(
            onAddSession: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SessionsListScreen(initialTab: SessionsTabType.add),
                ),
              );
            },
            onReview: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FlashcardsScreen()));
            },
            onStoryBuilder: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StoryBuilderScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
          RecentActivityFeed(
            sessions: sessions,
            stories: stories,
            onTap: (id, type) {
              if (type == ActivityType.session) {
                Session session = sessions.firstWhere((s) => s.id == id);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SessionDetailScreen(session: session)),
                );
              } else {
                // navigate to story editing page
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => StoryBuilderScreen(editStoryId: id)),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
