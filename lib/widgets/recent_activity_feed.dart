import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../models/story_model.dart';

/// Displays a feed of recent sessions and stories sorted by date.  The
/// feed shows up to [maxItems] items; if there are no items a
/// placeholder is displayed.  Tapping an item triggers the provided
/// callback with either a session or story ID so the parent can
/// navigate to the appropriate screen.
class RecentActivityFeed extends StatelessWidget {
  final List<Session> sessions;
  final List<Story> stories;
  final int maxItems;
  final void Function(String id, ActivityType type)? onTap;

  const RecentActivityFeed({
    Key? key,
    required this.sessions,
    required this.stories,
    this.maxItems = 3,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<_ActivityItem> items = [];
    for (final s in sessions) {
      items.add(_ActivityItem(
        id: s.id,
        title: s.title,
        subtitle: 'Session • ${s.date.toLocal().toString().split(' ').first}',
        date: s.date,
        type: ActivityType.session,
      ));
    }
    for (final st in stories) {
      items.add(_ActivityItem(
        id: st.id,
        title: st.title,
        subtitle: 'Story • ${st.createdAt.toLocal().toString().split(' ').first}',
        date: st.createdAt,
        type: ActivityType.story,
      ));
    }
    items.sort((a, b) => b.date.compareTo(a.date));
    final displayItems = items.take(maxItems).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        if (displayItems.isEmpty)
          Text(
            'No recent activity yet.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          ...displayItems.map((item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(item.type == ActivityType.session
                    ? Icons.event_note
                    : Icons.library_books),
                title: Text(item.title),
                subtitle: Text(item.subtitle),
                onTap: onTap != null
                    ? () => onTap!(item.id, item.type)
                    : null,
              )),
      ],
    );
  }
}

enum ActivityType { session, story }

class _ActivityItem {
  final String id;
  final String title;
  final String subtitle;
  final DateTime date;
  final ActivityType type;
  _ActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.type,
  });
}