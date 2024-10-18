import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UserPostsScreen extends StatefulWidget {
  final String userId;

  UserPostsScreen({required this.userId});

  @override
  _UserPostsScreenState createState() => _UserPostsScreenState();
}

class _UserPostsScreenState extends State<UserPostsScreen> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<Map<dynamic, dynamic>> userPosts = [];

  // Show loading dialog
  void _showLoadingSpinner(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing the dialog
      builder: (context) => Center(
        child: CircularProgressIndicator(), // Loading spinner
      ),
    );
  }

  // Dismiss loading dialog
  void _hideLoadingSpinner(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    _loadUserPosts();
  }

  // Load user's posts
  void _loadUserPosts() {
    DatabaseReference postsRef = _database.ref('posts');

    postsRef.orderByChild('userId').equalTo(widget.userId).onValue.listen((DatabaseEvent event) {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> posts = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          userPosts = posts.values.map((value) => value as Map<dynamic, dynamic>).toList();
        });
      }
    }, onError: (error) {
      print('Error loading posts: $error');
    });
  }

  // Pick image from gallery
  Future<File?> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      return File(pickedImage.path);
    }
    return null;
  }

  // Upload the image to Firebase Storage and return the download URL
  Future<String?> _uploadImage(File image, String postId) async {
    _showLoadingSpinner(context);

    try {
      String filePath = 'posts/$postId/${DateTime.now().millisecondsSinceEpoch}.png';
      Reference storageRef = _storage.ref().child(filePath);
      UploadTask uploadTask = storageRef.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Edit post (caption and postImageUrl)
  void _editPost(String postId, String currentCaption, String currentImageUrl) async {
    TextEditingController captionController = TextEditingController(text: currentCaption);
    TextEditingController imageUrlController = TextEditingController(text: currentImageUrl);
    File? newImageFile;

    await showDialog(
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
              ElevatedButton(
                onPressed: () async {
                  newImageFile = await _pickImage(); // Pick new image
                  if (newImageFile != null) {
                    imageUrlController.text = 'Image selected. Will be uploaded.'; // Show placeholder text
                  }
                },
                child: Text('Pick New Image'),
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
            ElevatedButton(
              onPressed: () async {
                String? newImageUrl;

                // If a new image was selected, upload it to Firebase Storage
                if (newImageFile != null) {
                  newImageUrl = await _uploadImage(newImageFile!, postId);
                }

                // Update Firebase Realtime Database with the new caption and (optional) image URL
                DatabaseReference postRef = _database.ref('posts/$postId');
                postRef.update({
                  'caption': captionController.text,
                  'postImageUrl': newImageUrl ?? currentImageUrl, // Update URL only if a new one was uploaded
                }).then((_) {
                  setState(() {
                    for (var post in userPosts) {
                      if (post['postId'] == postId) {
                        post['caption'] = captionController.text;
                        if (newImageUrl != null) {
                          post['postImageUrl'] = newImageUrl;
                        }
                      }
                    }
                  });
                  Navigator.of(context).pop();
                  _hideLoadingSpinner(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Post updated successfully')),
                  );
                }).catchError((error) {
                  print('Error updating post: $error');
                });
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Delete a post
  void _deletePost(String postId) {
    DatabaseReference postRef = _database.ref('posts/$postId');
    postRef.remove().then((_) {
      setState(() {
        userPosts.removeWhere((post) => post['postId'] == postId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post deleted successfully')),
      );
    }).catchError((error) {
      print('Error deleting post: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Posts', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        itemCount: userPosts.length,
        itemBuilder: (context, index) {
          Map<dynamic, dynamic> post = userPosts[index];
          return ListTile(
            title: Text(post['caption']),
            // subtitle: Text(post['timestamp'].toString()), // You can format timestamp here
            leading: post['postImageUrl'] != null
                ? Image.network(post['postImageUrl'])
                : SizedBox.shrink(),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _editPost(post['postId'], post['caption'], post['postImageUrl']);
                } else if (value == 'delete') {
                  _deletePost(post['postId']);
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ];
              },
            ),
          );
        },
      ),
    );
  }
}
