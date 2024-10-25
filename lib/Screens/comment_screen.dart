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
  List<Map<String, dynamic>> _commentsList = [];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _addComment() {
    if (_commentController.text.isNotEmpty) {
      final comment = {
        'commentText': _commentController.text,
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'userName': FirebaseAuth.instance.currentUser!.displayName ?? 'User',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      DatabaseReference postRef = _commentsRef.child(widget.postId);
      postRef
          .child('comments')
          .push()
          .set(comment)
          .then((_) {
        _commentController.clear();

        postRef.child('commentCount').runTransaction((mutableData) {
          int currentCount = (mutableData as num?)?.toInt() ?? 0;
          mutableData = currentCount + 1;
          return Transaction.success(mutableData);
        });
        setState(() {
          _commentsList.add(comment);
        });
      });
    }
  }


  Stream<List<Map<String, dynamic>>> _fetchComments() async* {
    final event = await _commentsRef.child(widget.postId).child('comments').once();
    if (event.snapshot.value == null) {
      yield [];
      return;
    }
    final commentsMap = Map<String, dynamic>.from(event.snapshot.value as Map);
    List<Map<String, dynamic>> commentsList = [];
    for (var entry in commentsMap.entries) {
      final commentData = Map<String, dynamic>.from(entry.value);
      final userId = commentData['userId'];
      final userSnapshot = await FirebaseDatabase.instance.ref().child('users').child(userId).once();
      final userData = userSnapshot.snapshot.value as Map;

      commentData['userName'] = userData['userName'];
      commentData['userProfileImage'] = userData['userProfileImage'];

      commentsList.add(commentData);
    }

    yield commentsList;
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
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No comments yet'));
                }

                final comments = snapshot.data!;
                final allComments = [..._commentsList, ...comments];

                return ListView.builder(
                  itemCount: allComments.length,
                  itemBuilder: (context, index) {
                    final comment = allComments[index];
                    final commentText = comment['commentText'];
                    final userName = comment['userName'] ?? 'Anonymous';
                    final userProfileImage = comment['userProfileImage'] ?? '';
                    final timestamp = (comment['timestamp'] as num).toInt();
                    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
                    final timeFormatted = DateFormat('MMM d, hh:mm a').format(dateTime);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: userProfileImage.isNotEmpty
                            ? NetworkImage(userProfileImage) as ImageProvider<Object>
                            : AssetImage('assets/images/default_avatar.png'),
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
