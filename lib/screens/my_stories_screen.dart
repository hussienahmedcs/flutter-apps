import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/story_provider.dart';
import 'story_builder_screen.dart';

/// Displays all of the user's saved stories.  Tapping on a story
/// navigates to the editor for updating its content.  Long pressing
/// reveals options to delete the story or export it (the latter is
/// currently a stub).  Stories are loaded from the [StoryProvider].
class MyStoriesScreen extends StatelessWidget {
  const MyStoriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // final stories = context.watch<StoryProvider>().stories;
    final stories = null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Stories'),
      ),
      body: stories.isEmpty
          ? Center(
              child: Text(
                'No stories yet. Use the story builder to create one!',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          : ListView.builder(
              itemCount: stories.length,
              itemBuilder: (context, index) {
                final story = stories[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(story.title),
                    subtitle: Text(story.createdAt.toLocal().toString().split(' ').first),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StoryBuilderScreen(editStoryId: story.id),
                        ),
                      );
                    },
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'delete') {
                          // final provider = context.read<StoryProvider>();
                          // await provider.deleteStory(story.id);
                        } else if (value == 'export') {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('Export not implemented.')));
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                        PopupMenuItem(value: 'export', child: Text('Export')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
