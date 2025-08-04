import 'package:flutter/material.dart';
import '../data/models/gamification_model.dart';
import '../theme.dart';

/// Displays a circular progress ring representing the user's current
/// XP relative to the next level.  The centre of the ring shows the
/// current level while a subheading displays the current XP and the
/// required XP to reach the next level.  Colours adapt to the
/// surrounding theme.
class XPProgressRing extends StatelessWidget {
  final Gamification? stats;

  const XPProgressRing({Key? key, required this.stats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return const SizedBox.shrink();
    }
    // Each level requires 500 XP according to the specification.
    const int xpPerLevel = 500;
    final int xpIntoLevel = stats!.xp % xpPerLevel;
    final double progress = xpIntoLevel / xpPerLevel;
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color secondary = Theme.of(context).colorScheme.secondary;
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: 150,
            height: 150,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 12,
              backgroundColor: primary.withOpacity(0.2),
              color: secondary,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Lvl ${stats!.level}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '$xpIntoLevel / $xpPerLevel XP',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}