import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ContentModerationScreen extends StatefulWidget {
  @override
  _ContentModerationScreenState createState() => _ContentModerationScreenState();
}

class _ContentModerationScreenState extends State<ContentModerationScreen> {
  final DatabaseReference _flaggedPostsRef = FirebaseDatabase.instance.ref('flaggedPosts');
  List<FlaggedPost> _flaggedPosts = [];

  @override
  void initState() {
    super.initState();
    _fetchFlaggedPosts();
  }

  // Fetch flagged posts from Firebase Realtime Database
  Future<void> _fetchFlaggedPosts() async {
    DatabaseEvent event = await _flaggedPostsRef.once();
    if (event.snapshot.exists) {
      final Map<dynamic, dynamic> flaggedPostsMap = event.snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _flaggedPosts = flaggedPostsMap.entries.map((entry) {
          final value = entry.value;
          return FlaggedPost(
            flaggedPostID: entry.key,
            flaggedBy: value['flaggedBy'],
            reason: value['reason'],
            timestamp: DateTime.fromMillisecondsSinceEpoch(value['timestamp']),
          );
        }).toList();
      });
    }
  }

  // Function to delete a flagged post from the flagged posts table
  Future<void> _deleteFlaggedPost(String flaggedPostID) async {
    await _flaggedPostsRef.child(flaggedPostID).remove();
    // Optionally, refresh the list after deletion
    _fetchFlaggedPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Content Moderation'),
      ),
      body: ListView.builder(
        itemCount: _flaggedPosts.length,
        itemBuilder: (context, index) {
          final flaggedPost = _flaggedPosts[index];
          return Card(
            margin: EdgeInsets.all(8.0),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Flagged By: ${flaggedPost.flaggedBy}'),
                  Text('Reason: ${flaggedPost.reason}'),
                  Text('Timestamp: ${flaggedPost.timestamp}'),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      _deleteFlaggedPost(flaggedPost.flaggedPostID);
                    },
                    child: Text('Delete Post'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class FlaggedPost {
  final String flaggedPostID;
  final String flaggedBy;
  final String reason;
  final DateTime timestamp;

  FlaggedPost({
    required this.flaggedPostID,
    required this.flaggedBy,
    required this.reason,
    required this.timestamp,
  });
}
