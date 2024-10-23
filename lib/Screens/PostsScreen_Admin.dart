import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'comment_screen.dart';



class PostsScreenAdmin extends StatefulWidget {
  @override
  _PostsScreenAdminState createState() => _PostsScreenAdminState();
}

class _PostsScreenAdminState extends State<PostsScreenAdmin> {
  final DatabaseReference _postsRef = FirebaseDatabase.instance.ref('posts');
   final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'PostsScreen',
            style: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: _postsRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(child: Text('No posts yet'));
          }

          Map<dynamic, dynamic> posts = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          List<dynamic> postList = posts.values.toList();

          return ListView.builder(
            itemCount: postList.length,
            itemBuilder: (context, index) {
              Map<dynamic, dynamic> post = postList[index];
              String postId = post['postId'] ?? '';
              String postOwnerId = post['userId'] ?? '';

              return FutureBuilder(
                future: _usersRef.child(postOwnerId).once(),
                builder: (context, AsyncSnapshot<DatabaseEvent> userSnapshot) {
                  if (!userSnapshot.hasData || userSnapshot.data!.snapshot.value == null) {
                    return SizedBox.shrink();
                  }

                  Map<dynamic, dynamic> user = userSnapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      elevation: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: (user['userProfileImage'] != null && user['userProfileImage'].toString().isNotEmpty)
                                      ? NetworkImage(user['userProfileImage'] as String)
                                      : AssetImage('assets/profile_placeholder.png') as ImageProvider,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  user['userName'] ?? 'Unknown User',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          post['postImageUrl'] != null && post['postImageUrl'].toString().isNotEmpty
                              ? Image.network(
                            post['postImageUrl'],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 250,
                            errorBuilder: (context, error, stackTrace) {
                              return Text('Error loading image');
                            },
                          )
                              : Container(height: 250, color: Colors.grey[300], child: Center(child: Text('No Image Available'))),

                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        post['likes'] != null && (post['likes'] as Map<dynamic, dynamic>).containsKey(FirebaseAuth.instance.currentUser!.uid)
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                      ),
                                      onPressed: () {
                                        String userId = FirebaseAuth.instance.currentUser!.uid;
                                        _handleLike(postId, userId);
                                      },
                                    ),
                                    Text(
                                      post['likeCount']?.toString() ?? '0', // Check for null likeCount
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.comment_outlined),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CommentsScreen(postId: postId),
                                          ),
                                        );
                                      },
                                    ),
                                    Text(
                                      post['commentCount']?.toString() ?? '0',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: Icon(Icons.share_outlined),
                                  onPressed: () {
                                    _handleShare(post['postImageUrl'] ?? ''); // Safeguard postImageUrl for null
                                  },
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              post['caption'] ?? '', // Safeguard caption for null
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }


  Future<void> _handleLike(String postId, String userId) async {
    DatabaseReference postRef = _postsRef.child(postId);

    DatabaseEvent event = await postRef.once();
    DataSnapshot snapshot = event.snapshot;

    if (snapshot.exists) {
      Map<dynamic, dynamic> post = snapshot.value as Map<dynamic, dynamic>;
      int currentLikeCount = post['likeCount'] ?? 0;
      Map<dynamic, dynamic> likes = post['likes'] ?? {};

      if (likes.containsKey(userId)) {
        likes.remove(userId);
        currentLikeCount -= 1;
      } else {
        likes[userId] = true;
        currentLikeCount += 1;
      }

      await postRef.update({
        'likeCount': currentLikeCount,
        'likes': likes,
      });
    }
  }
  void _handleShare(String postImageUrl) {
    print('Share button clicked! Image URL: $postImageUrl');
    // Implement sharing logic (e.g., using the `share_plus` package)
  }
}