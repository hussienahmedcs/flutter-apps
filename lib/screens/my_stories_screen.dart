import 'package:flutter/material.dart';
import 'package:wordstory/data/interfaces/user_interface.dart';
import 'package:wordstory/data/models/story_model.dart';
import 'package:wordstory/data/repositories/story_repository.dart';
import 'story_builder_screen.dart';

/// Displays all of the user's saved stories.  Tapping on a story
/// navigates to the editor for updating its content.  Long pressing
/// reveals options to delete the story or export it (the latter is
/// currently a stub).  Stories are loaded from the [StoryProvider].
class MyStoriesScreen extends StatefulWidget {
  final UserInterface user;
  const MyStoriesScreen({super.key, required this.user});

  @override
  State<MyStoriesScreen> createState() => _MyStoriesScreenState();
}

class _MyStoriesScreenState extends State<MyStoriesScreen> {
  final StoryRepository _storyRepository = StoryRepository();
  List<Story> stories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    loader();
  }

  Future<void> loader() async {
    setState(() {
      _loading = true;
    });
    final stories = await _storyRepository.getStories(widget.user.uid);
    setState(() {
      this.stories = stories;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
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
                          await _storyRepository.deleteStory(widget.user.uid, story.id);
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
      floatingActionButton: null,//add button to click to create story
    );
  }
}
