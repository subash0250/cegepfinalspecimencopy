
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AllPostsScreen extends StatefulWidget {
  // final String userId;

  const AllPostsScreen({super.key});

  @override
  _AllPostsScreenState createState() => _AllPostsScreenState();
}

class _AllPostsScreenState extends State<AllPostsScreen> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  List<Map<dynamic, dynamic>> userPosts = [];

  // Show loading dialog
  void _showLoadingSpinner(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing the dialog
      builder: (context) => const Center(
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

    postsRef.onValue.listen((DatabaseEvent event) {
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
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);

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
          title: const Text('Edit Post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: captionController,
                decoration: const InputDecoration(labelText: 'Caption'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  newImageFile = await _pickImage(); // Pick new image
                  if (newImageFile != null) {
                    imageUrlController.text = 'Image selected. Will be uploaded.'; // Show placeholder text
                  }
                },
                child: const Text('Pick New Image'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
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
                    const SnackBar(content: Text('Post updated successfully')),
                  );
                }).catchError((error) {
                  print('Error updating post: $error');
                });
              },
              child: const Text('Save'),
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
        const SnackBar(content: Text('Post deleted successfully')),
      );
    }).catchError((error) {
      print('Error deleting post: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Posts', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        itemCount: userPosts.length,
        itemBuilder: (context, index) {
          Map<dynamic, dynamic> post = userPosts[index];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          post['caption'] ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editPost(post['postId'], post['caption'], post['postImageUrl']);
                            } else if (value == 'delete') {
                              _deletePost(post['postId']);
                            }
                          },
                          itemBuilder: (BuildContext context) {
                            return [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (post['postImageUrl'] != null && post['postImageUrl'].toString().isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          post['postImageUrl'],
                          fit: BoxFit.cover,
                          height: 200,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return const Text('Error loading image');
                          },
                        ),
                      ),
                    const SizedBox(height: 10),
                    // Text(
                    //   post['timestamp'] != null ? _formatTimestamp(post['timestamp']) : '',
                    //   style: TextStyle(color: Colors.grey),
                    // ),
                  ],
                ),
              ),
            ),
          );
        },
      ),

    );
  }
}
