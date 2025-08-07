import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wordstory/data/interfaces/user_interface.dart';
import 'package:wordstory/data/models/center_config.dart';
import 'package:wordstory/data/models/session_model.dart';
import 'package:wordstory/data/repositories/center_repository.dart';
import 'package:wordstory/providers/app_auth_provider.dart';
import 'package:wordstory/screens/admin/manage_center_page.dart';
import 'package:wordstory/screens/center_details_page.dart';
import 'package:wordstory/screens/exam/exam_page.dart';
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
  const DashboardScreen({super.key});

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
  CenterConfig? _config;
  bool _loading = false;
  final CenterRepository _centerRepository = CenterRepository();
  UserInterface? _user;
  bool isPendingInstructor = false;

  void switchTab(int index) {
    setState(() => _index = index);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCenterConfig());
  }

  Future<void> _loadCenterConfig() async {
    final user = context.read<AppAuthProvider>().user;
    if (user == null) return;

    setState(() {
      _user = user;
      _loading = true;
    });
    print('vvvvvvvvvvvvvvvvvv${user.centerCode}');
    //check if pending instructor
    if (user.isInstructor == true && user.centerCode == null) {
      final pending = await _centerRepository.isInstructorPending(user.uid);
      if (mounted) {
        setState(() {
          isPendingInstructor = pending;
          _config = null;
          _loading = false;
        });
      }
      return;
    }

    final config = await _centerRepository.getCenterConfig(user.centerCode ?? '');
    if (mounted) {
      setState(() {
        _config = config;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<FlashcardsScreenState> flashcardKey = GlobalKey<FlashcardsScreenState>();

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(8.0),
          child: Center(child: Text("System error, user details not retrieved, please contact admin")),
        ),
      );
    }
    if (_user!.isUser == false && _config == null && (!isPendingInstructor && _user!.isInstructor)) {
      return const Scaffold(body: Center(child: Text("No Center Config, please contact center admin")));
    }

    final List<Map<String, dynamic>> pages = [
      {"screen": _HomeTab(config: _config), "key": null},
      {"screen": const SessionsListScreen(), "key": null},
      {"screen": FlashcardsScreen(key: flashcardKey), "key": flashcardKey},
      {"screen": const MyStoriesScreen(), "key": null},
      {"screen": const ProfileScreen(), "key": null},
    ];

    return WillPopScope(
      onWillPop: () async {
        if (_index != 0) {
          setState(() => _index = 0);
          return false;
        }

        final now = DateTime.now();
        if (_lastBackPress == null || now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Press back again to exit')),
          );
          return false;
        }
        return true;
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
            setState(() => _index = value);
            final key = pages[value]['key'];
            if (key != null && key.currentState != null) {
              key.currentState!.reset();
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.event_note), label: 'Sessions'),
            BottomNavigationBarItem(icon: Icon(Icons.style), label: 'Practice'),
            BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Stories'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
  final CenterConfig? config;
  const _HomeTab({this.config});
  @override
  Widget build(BuildContext context) {
    print('>>>>>>>>>>>>>>>>>>>>>');
    final gamification = context.watch<GamificationProvider>().stats;
    final sessions = context.watch<SessionProvider>().sessions;
    final stories = context.watch<StoryProvider>().stories;
    final user = context.watch<AppAuthProvider>().user!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 32,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              XPProgressRing(stats: gamification),
              StreakCounter(stats: gamification),
            ],
          ),
          const SizedBox(height: 16),
          QuickActionsGrid(
            icons: [
              {
                'icon': Icons.add_circle_outline,
                'label': 'New Session',
                'onTap': () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SessionsListScreen(initialTab: SessionsTabType.add),
                    ),
                  );
                },
                'enabled': user.isUser ||
                    user.isAdmin ||
                    (config != null && config!.learnerCanCreateSession && user.isLearner) ||
                    (config != null && config!.teacherCanCreateSession && user.isInstructor),
              },
              {
                'icon': Icons.style,
                'label': 'Review',
                'onTap': () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FlashcardsScreen()));
                },
                'enabled': user.isUser || user.isAdmin || user.isLearner || user.isPendingLearner || user.isInstructor,
              },
              {
                'icon': Icons.create,
                'label': 'Story Builder',
                'onTap': () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StoryBuilderScreen()),
                  );
                },
                'enabled': user.isUser ||
                    user.isAdmin ||
                    user.isPendingLearner ||
                    user.isInstructor ||
                    (config != null && config!.allowLearnerStoryBuilder && user.isLearner),
              },
              {
                'icon': Icons.quiz,
                'label': 'Exam',
                'onTap': () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ExamPage()),
                  );
                },
                'enabled': user.isUser ||
                    user.isAdmin ||
                    user.isInstructor ||
                    (config != null && config!.learnerCanAccessExamPage && user.isLearner),
              },
              {
                'icon': Icons.settings,
                'label': 'Manage Center',
                'onTap': () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => ManageCenterPage(
                              centerCode: user.centerCode ?? '',
                            )),
                  );
                },
                'enabled': user.isAdmin,
              },
              {
                'icon': Icons.info_outline,
                'label': 'Center Details',
                'onTap': () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => CenterDetailsPage(
                              centerCode: user.centerCode ?? '',
                              userId: user.uid,
                              userRole: user.role,
                            )),
                  );
                },
                'enabled': user.isLearner || user.isPendingLearner || user.isInstructor,
              },
            ],
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
