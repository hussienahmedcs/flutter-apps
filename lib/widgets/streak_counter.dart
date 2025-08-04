import 'package:flutter/material.dart';
import '../data/models/gamification_model.dart';

/// Displays the current streak with a flame icon and day count.  On
/// tap a heatmap dialog appears showing the last 30 days of activity.
class StreakCounter extends StatelessWidget {
  final Gamification? stats;
  const StreakCounter({Key? key, required this.stats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (stats == null) return const SizedBox.shrink();
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => _StreakHeatmapDialog(stats: stats!),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.whatshot, color: Colors.orange),
            const SizedBox(width: 4),
            Text('Day ${stats!.streak}')
          ],
        ),
      ),
    );
  }
}

/// A dialog showing the last 30 days of user activity as a simple
/// heatmap.  The number of coloured cells corresponds to the current
/// streak; the rest remain grey.  This is a lightweight visual that
/// gives the user feedback on their consistency without requiring
/// external packages.
class _StreakHeatmapDialog extends StatelessWidget {
  final Gamification stats;
  const _StreakHeatmapDialog({Key? key, required this.stats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine which of the last 30 days are in the streak.  We
    // highlight the most recent `stats.streak` days.
    final int totalDays = 30;
    final int highlighted = stats.streak.clamp(0, totalDays);
    return AlertDialog(
      title: const Text('Streak History'),
      content: SizedBox(
        width: double.maxFinite,
        child: GridView.builder(
          shrinkWrap: true,
          itemCount: totalDays,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            final isActive = index < highlighted;
            return Container(
              decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).disabledColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              height: 16,
              width: 16,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}