import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wordstory/data/models/center_config.dart';
import 'package:wordstory/data/models/session_model.dart';
import 'package:wordstory/data/models/story_model.dart';
import 'package:wordstory/data/repositories/center_repository.dart';
import 'package:wordstory/providers/app_auth_provider.dart';
import 'package:wordstory/providers/gamification_provider.dart';
import 'package:wordstory/screens/admin/manage_center_page.dart';
import 'package:wordstory/screens/center_details_page.dart';
import 'package:wordstory/screens/exam/exam_page.dart';
import 'package:wordstory/screens/flashcards_screen.dart';
import 'package:wordstory/screens/my_stories_screen.dart';
import 'package:wordstory/screens/profile_screen.dart';
import 'package:wordstory/screens/session_detail_screen.dart';
import 'package:wordstory/screens/sessions_list_screen.dart';
import 'package:wordstory/screens/story_builder_screen.dart';
import 'package:wordstory/widgets/quick_actions_grid.dart';
import 'package:wordstory/widgets/recent_activity_feed.dart';
import 'package:wordstory/widgets/streak_counter.dart';
import 'package:wordstory/widgets/xp_progress_ring.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // final StoryRepository _storyRepository = StoryRepository();
  final List<Story> stories = [];
  final List<Session> sessions = []; //context.watch<SessionProvider>().sessions;
  // Gamification? gamification;
  // final GamificationRepository _gamificationRepository = GamificationRepository();
  final CenterRepository _centerRepository = CenterRepository();
  CenterConfig? config;

  @override
  void initState() {
    super.initState();
    loader();
  }

  Future<void> loader() async {
    final user = context.read<AppAuthProvider>().user!;
    // final data = context.read<GamificationProvider>().stats;

    // if (user.isUser) sessionOwnersIds.add(user.uid);
    if (user.centerCode != null) {
      config = await _centerRepository.getCenterConfig(user.centerCode!);
    }
    // setState(() {
    //   gamification = data;
    // });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final gamification = context.watch<GamificationProvider>().stats;
    final user = context.watch<AppAuthProvider>().user!;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 32,
            ),
            if (gamification != null)
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
                  'icon': Icons.person,
                  'label': 'Profile',
                  'onTap': () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                  'enabled': user.isUser ||
                      user.isAdmin ||
                      (config != null && config!.learnerCanAccessExamPage && user.isLearner) ||
                      (config != null && config!.teacherCanAccessExamPage && user.isInstructor),
                },
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
                  'enabled':
                      user.isUser || user.isAdmin || user.isLearner || user.isPendingLearner || user.isInstructor,
                },
                {
                  'icon': Icons.event_note,
                  'label': 'Sessions',
                  'onTap': () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SessionsListScreen()));
                  },
                  'enabled':
                      user.isUser || user.isAdmin || user.isLearner || user.isPendingLearner || user.isInstructor,
                },
                {
                  'icon': Icons.library_books,
                  'label': 'Stories',
                  'onTap': () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => MyStoriesScreen()));
                  },
                  'enabled':
                      user.isUser || user.isAdmin || user.isLearner || user.isPendingLearner || user.isInstructor,
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
      ),
    );
  }
}
