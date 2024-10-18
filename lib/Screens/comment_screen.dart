import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;

  const CommentsScreen({Key? key, required this.postId}) : super(key: key);

  @override
  _CommentsScreenState createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final DatabaseReference _commentsRef = FirebaseDatabase.instance.ref('posts');
  List<Map<String, dynamic>> _commentsList = []; // Local comments list

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // Function to add a comment
  void _addComment() {
    if (_commentController.text.isNotEmpty) {
      final comment = {
        'commentText': _commentController.text,
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'userName': FirebaseAuth.instance.currentUser!.displayName ?? 'User',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      DatabaseReference postRef = _commentsRef.child(widget.postId);

      // Add comment to the database
      postRef
          .child('comments')
          .push()
          .set(comment)
          .then((_) {
        // Clear the comment input field
        _commentController.clear();

        postRef.child('commentCount').runTransaction((mutableData) {
          int currentCount = (mutableData as num?)?.toInt() ?? 0;
          mutableData = currentCount + 1;
          return Transaction.success(mutableData);
        });

        // Update the local comments list
        setState(() {
          _commentsList.add(comment); // Add new comment to the local list
        });
      });
    }
  }

  // Function to fetch comments
  Stream<List<Map<String, dynamic>>> _fetchComments() async* {
    final event = await _commentsRef.child(widget.postId).child('comments').once();

    // If there are no comments, return an empty list
    if (event.snapshot.value == null) {
      yield [];
      return;
    }

    final commentsMap = Map<String, dynamic>.from(event.snapshot.value as Map);
    List<Map<String, dynamic>> commentsList = [];

    // Iterate through each comment
    for (var entry in commentsMap.entries) {
      final commentData = Map<String, dynamic>.from(entry.value);
      final userId = commentData['userId']; // Get the userId for the comment

      // Fetch user data based on userId
      final userSnapshot = await FirebaseDatabase.instance.ref().child('users').child(userId).once();
      final userData = userSnapshot.snapshot.value as Map;

      // Add userName and userProfileImage to comment data
      commentData['userName'] = userData['userName'];
      commentData['userProfileImage'] = userData['userProfileImage'];

      commentsList.add(commentData);
    }

    yield commentsList; // Yield the comments list with user data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _fetchComments(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator()); // Show loading spinner while waiting
                }

                // Check if there are no comments
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No comments yet')); // Display message if no comments
                }

                final comments = snapshot.data!;

                // Merge local comments with fetched comments
                final allComments = [..._commentsList, ...comments];

                return ListView.builder(
                  itemCount: allComments.length,
                  itemBuilder: (context, index) {
                    final comment = allComments[index];
                    final commentText = comment['commentText'];
                    final userName = comment['userName'] ?? 'Anonymous'; // Fallback if userName is missing
                    final userProfileImage = comment['userProfileImage'] ?? ''; // Fallback if profileImage is missing
                    final timestamp = (comment['timestamp'] as num).toInt();
                    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
                    final timeFormatted = DateFormat('MMM d, hh:mm a').format(dateTime);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: userProfileImage.isNotEmpty
                            ? NetworkImage(userProfileImage) as ImageProvider<Object>
                            : AssetImage('assets/images/default_avatar.png'), // Default avatar
                      ),
                      title: Text(userName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(commentText),
                          SizedBox(height: 4),
                          Text(
                            timeFormatted,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
