import 'package:flutter/material.dart';

/// Display three quick action buttons as a grid: add a new session,
/// review words and build a story.  Each tile calls its associated
/// callback when tapped.  The caller supplies the functions to
/// navigate to the appropriate screens.
class QuickActionsGrid extends StatelessWidget {
  // final VoidCallback onAddSession;
  // final VoidCallback onReview;
  // final VoidCallback onStoryBuilder;
  // final VoidCallback onExam;
  final List<Map<String, dynamic>> icons;

  const QuickActionsGrid(
      {super.key,
      // required this.onAddSession,
      // required this.onReview,
      // required this.onStoryBuilder,
      // required this.onExam,
      required this.icons});

  @override
  Widget build(BuildContext context) {
    final List<_ActionTile> tiles = icons
        .where((i) => i['enabled'] == true)
        .map((i) => _ActionTile(
              icon: i['icon'],
              label: i['label'],
              onTap: i['onTap'],
            ))
        .toList();
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: tiles
          .map((tile) => _ActionButton(
                icon: tile.icon,
                label: tile.label,
                onTap: tile.onTap,
              ))
          .toList(),
    );
  }
}

class _ActionTile {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _ActionTile({required this.icon, required this.label, required this.onTap});
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({Key? key, required this.icon, required this.label, required this.onTap}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
