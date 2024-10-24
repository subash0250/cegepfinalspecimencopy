import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ContentModerationScreen extends StatefulWidget {
  @override
  State<ContentModerationScreen> createState() =>
      _ContentModerationScreenState();
}

class _ContentModerationScreenState extends State<ContentModerationScreen> {
  final DatabaseReference _flaggedPostsRef =
  FirebaseDatabase.instance.ref().child('flaggedPosts');
  final DatabaseReference _usersRef =
  FirebaseDatabase.instance.ref().child('users');

  List<FlaggedPost> _flaggedPosts = [];

  @override
  void initState() {
    super.initState();
    _fetchFlaggedPosts();
  }

  Future<void> _fetchFlaggedPosts() async {
    try {
      DatabaseEvent event = await _flaggedPostsRef.once();
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;

        if (data != null) {
          List<Future<FlaggedPost>> postsFuture = data.entries.map((entry) async {
            final value = entry.value as Map<dynamic, dynamic>;

            // Get flaggedBy ID
            String flaggedByID = value['flaggedBy'] ?? 'Unknown';

            // Fetch the user's name from the users table
            String flaggedByName = await _fetchUserName(flaggedByID);

            // Safely parse timestamp
            DateTime timestamp = DateTime.now();
            if (value['timestamp'] != null) {
              try {
                timestamp = DateTime.parse(value['timestamp']);
              } catch (e) {
                print('Error parsing timestamp: $e');
              }
            }

            return FlaggedPost(
              flaggedPostID: entry.key,
              flaggedBy: flaggedByName,
              reason: value['reason'] ?? 'No reason provided',
              timestamp: timestamp,
            );
          }).toList();

          // Wait for all posts to be fetched
          List<FlaggedPost> posts = await Future.wait(postsFuture);

          setState(() {
            _flaggedPosts = posts;
          });
        } else {
          print('No data found in the snapshot.');
        }
      } else {
        print('No flagged posts exist.');
      }
    } catch (e) {
      print('Error fetching flagged posts: $e');
    }
  }

  Future<String> _fetchUserName(String userID) async {
    try {
      DatabaseEvent userEvent = await _usersRef.child(userID).once();
      if (userEvent.snapshot.exists) {
        final userData = userEvent.snapshot.value as Map<dynamic, dynamic>;
        return userData['userName'] ?? 'Unknown User';
      } else {
        return 'Unknown User';
      }
    } catch (e) {
      print('Error fetching user name: $e');
      return 'Unknown User';
    }
  }
  Future<void> _deleteFlaggedPost(String flaggedPostID) async {
    try {
      DatabaseEvent event = await _flaggedPostsRef.child(flaggedPostID).once();
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        String postID = data['postID'];

        await _flaggedPostsRef.child(flaggedPostID).remove();
        await FirebaseDatabase.instance.ref('posts').child(postID).remove();

        _fetchFlaggedPosts();

        print('Successfully deleted post $postID from both tables.');
      } else {
        print('Flagged post not found.');
      }
    } catch (e) {
      print('Error deleting post: $e');
    }
  }
  Future<void> _VerifiedFlaggedPost(String flaggedPostID) async {
    await _flaggedPostsRef.child(flaggedPostID).remove();
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _deleteFlaggedPost(flaggedPost.flaggedPostID);
                        },
                        child: Text('Delete Post'),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _VerifiedFlaggedPost(flaggedPost.flaggedPostID);
                        },
                        child: Text('Verified Post'),
                      ),
                    ),
                  ],
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