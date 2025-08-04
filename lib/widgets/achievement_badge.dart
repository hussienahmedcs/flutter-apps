import 'package:flutter/material.dart';
import '../data/models/achievement_model.dart';

/// Visual representation of a single achievement.  If the achievement
/// has been unlocked by the user, the badge is coloured with the
/// accent colour; otherwise it is greyed out.  An optional [icon]
/// string can be used to determine which Material icon to show.
class AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;
  const AchievementBadge({Key? key, required this.achievement, required this.unlocked}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color color = unlocked
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).disabledColor;
    final IconData iconData;
    switch (achievement.id) {
      case 'first_word':
        iconData = Icons.edit;
        break;
      case 'hundred_words':
        iconData = Icons.library_books;
        break;
      case 'seven_day_streak':
        iconData = Icons.whatshot;
        break;
      case 'first_story':
        iconData = Icons.create;
        break;
      default:
        iconData = Icons.star_border;
    }
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(iconData, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          achievement.title,
          style: TextStyle(
            fontSize: 12,
            color: unlocked ? color : Theme.of(context).disabledColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}