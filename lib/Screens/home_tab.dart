
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'comment_screen.dart';
import 'package:path/path.dart' as path;


class HomeTab extends StatefulWidget {
  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final DatabaseReference _postsRef = FirebaseDatabase.instance.ref('posts');
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');
  final DatabaseReference _flaggedPostsRef = FirebaseDatabase.instance.ref('flaggedPosts');

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Home',
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
                                Spacer(),
                                if (currentUserId == postOwnerId)
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit),
                                        onPressed: () {
                                          _showEditPostDialog(postId, post['caption'] ?? '', post['postImageUrl'] ?? '');
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete),
                                        onPressed: () {
                                          _handleDelete(postId);
                                        },
                                      ),
                                    ],
                                  ),
                                if (currentUserId != postOwnerId)
                                  IconButton(
                                    icon: Icon(Icons.flag_outlined, color: Colors.red),
                                    onPressed: () {
                                      _showFlagPostDialog(postId);
                                    },
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
                                    _handleShare(post['postImageUrl'] ?? '');
                                  },
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              post['caption'] ?? '',
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
  Future<void> _showFlagPostDialog(String postId) async {
    TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Flag Post'),
          content: TextField(
            controller: reasonController,
            decoration: InputDecoration(labelText: 'Reason for flagging'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _flagPost(postId, reasonController.text);
                Navigator.of(context).pop();
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }
  Future<void> _flagPost(String postId, String reason) async {
    await _flaggedPostsRef.child(postId).set({
      'postID': postId,
      'flaggedBy': currentUserId,
      'reason': reason,
      'timestamp': DateTime.now().toIso8601String(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Post flagged successfully')),
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

  Future<void> _handleDelete(String postId) async {
    await _postsRef.child(postId).remove();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post deleted successfully')));
  }



  Future<void> _showEditPostDialog(String postId, String currentCaption, String currentImageUrl) async {
    TextEditingController captionController = TextEditingController(text: currentCaption);
    String? selectedImageUrl;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: captionController,
                decoration: InputDecoration(labelText: 'Caption'),
              ),
              SizedBox(height: 10),
              // Display the current image or the newly selected image
              selectedImageUrl != null && selectedImageUrl!.isNotEmpty
                  ? Image.network(selectedImageUrl!, height: 100, fit: BoxFit.cover)
                  : Image.network(currentImageUrl, height: 100, fit: BoxFit.cover),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (image != null) {

                    String newImageUrl = await _uploadImageToFirebase(image.path);
                    setState(() {
                    });
                  }
                },
                child: Text('Modify Post'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _updatePost(postId, captionController.text, selectedImageUrl ?? currentImageUrl);
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }


  Future<String> _uploadImageToFirebase(String filePath) async {
    String fileName = path.basename(filePath);
    Reference storageRef = FirebaseStorage.instance.ref().child('postImages/$fileName');

    UploadTask uploadTask = storageRef.putFile(File(filePath));
    TaskSnapshot taskSnapshot = await uploadTask;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }
  Future<void> _updatePost(String postId, String newCaption, String newImageUrl) async {
    await _postsRef.child(postId).update({
      'caption': newCaption,
      'postImageUrl': newImageUrl,
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post updated successfully')));
  }

  Future<void> _updatePostImageUrl(String postId, String newImageUrl) async {
    await FirebaseDatabase.instance.ref('posts').child(postId).update({
      'postImageUrl': newImageUrl,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Post image updated successfully')),
    );
  }


  void _handleShare(String postImageUrl) {
    print('Share button clicked! Image URL: $postImageUrl');

  }
}