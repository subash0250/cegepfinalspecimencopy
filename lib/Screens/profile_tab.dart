
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'edit_profile_screen.dart';
import 'moderator/ModeratorUsersScreen.dart';
import 'user_posts_screen.dart';
import 'FollowersScreen.dart';
import 'FollowingScreen.dart';

class ProfileTab extends StatefulWidget {
  @override
  _ProfileTabState createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  String? userName;
  String? userBio;
  String? userProfileImage;
  String? userEmail;
  String? userId;
  String? userRole;
  int postCount = 0;
  int followersCount = 0;
  int followingCount = 0;
  List<Map<String, dynamic>> warnings = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserPostsCount();
    _loadFollowersCount();
    _loadFollowingCount();
    _loadWarnings();
  }

  void _loadUserData() async {
    User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      userId = currentUser.uid;
      DatabaseReference userRef = _database.ref('users/$userId');

      userRef.onValue.listen((DatabaseEvent event) {
        if (event.snapshot.exists) {
          Map<dynamic, dynamic> userData = event.snapshot.value as Map;

          setState(() {
            userName = userData['userName'] ?? 'Unknown';
            userBio = userData['userBio'] ?? 'No bio available';
            userProfileImage = userData['userProfileImage'] ?? 'assets/images/profile_placeholder.png';
            userEmail = userData['userEmail'] ?? 'No email available';
            userRole = userData['userRole'] ?? 'User';
          });
        }
      }, onError: (error) {
        print('Error loading user data: $error');
      });
    }
  }

  void _loadUserPostsCount() async {
    User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      String userId = currentUser.uid;
      DatabaseReference postsRef = _database.ref('posts');

      postsRef.orderByChild('userId').equalTo(userId).onValue.listen((DatabaseEvent event) {
        if (event.snapshot.exists) {
          Map<dynamic, dynamic> posts = event.snapshot.value as Map;
          setState(() {
            postCount = posts.length;
          });
        } else {
          setState(() {
            postCount = 0;
          });
        }
      }, onError: (error) {
        print('Error loading post count: $error');
      });
    }
  }

  void _loadFollowersCount() async {
    User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      String userId = currentUser.uid;
      DatabaseReference followersRef = _database.ref('users/$userId/followersCount');

      followersRef.onValue.listen((DatabaseEvent event) {
        if (event.snapshot.exists) {
          setState(() {
            followersCount = event.snapshot.value as int;
          });
        } else {
          setState(() {
            followersCount = 0;
          });
        }
      }, onError: (error) {
        print('Error loading followers count: $error');
      });
    }
  }

  void _loadFollowingCount() async {
    User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      String userId = currentUser.uid;
      DatabaseReference followingRef = _database.ref('users/$userId/followingCount');

      followingRef.onValue.listen((DatabaseEvent event) {
        if (event.snapshot.exists) {
          setState(() {
            followingCount = event.snapshot.value as int;
          });
        } else {
          setState(() {
            followingCount = 0;
          });
        }
      }, onError: (error) {
        print('Error loading following count: $error');
      });
    }
  }
  void _loadWarnings() async {
    if (userId != null) {
      DatabaseReference warningsRef = _database.ref('users/$userId/userWarnings');

      warningsRef.onValue.listen((DatabaseEvent event) async {
        if (event.snapshot.exists) {
          Map<dynamic, dynamic> warningsData = event.snapshot.value as Map;
          List<Map<String, dynamic>> loadedWarnings = [];

          for (var warningKey in warningsData.keys) {
            var warning = warningsData[warningKey];
            String postId = warning['postId'];
            String message = warning['message'];

            // Fetch caption from posts node
            DatabaseReference postRef = _database.ref('posts/$postId');
            DataSnapshot postSnapshot = await postRef.get();

            if (postSnapshot.exists) {
              String caption = postSnapshot.child('caption').value as String;
              loadedWarnings.add({
                'message': message,
                'caption': caption,
                'postId': postId,
              });
            } else {
              loadedWarnings.add({
                'message': message,
                'caption': 'Caption not found', // Fallback in case the post is missing
                'postId': postId,
              });
            }
          }

          setState(() {
            warnings = loadedWarnings;
          });

          print("Warnings with captions loaded: $warnings");
        } else {
          setState(() {
            warnings = [];
          });
          print("No warnings found for the user.");
        }
      }, onError: (error) {
        print('Error loading warnings: $error');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: userProfileImage != null
                        ? NetworkImage(userProfileImage!)
                        : AssetImage('assets/images/profile_placeholder.png') as ImageProvider,
                  ),
                  SizedBox(height: 10),
                  Text(
                    userName ?? 'Loading...',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    userBio ?? '@loading_bio',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  if (userRole == 'user' && warnings.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Warnings:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: warnings.length,
                            itemBuilder: (context, index) {
                              final warning = warnings[index] as Map<String, dynamic>; // Cast to Map<String, dynamic>
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 5),
                                child: Text(
                                  "- ${warning['message']} (Caption: ${warning['caption']})",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.red,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    // Navigate to UserPostsScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserPostsScreen(userId: userId!),
                      ),
                    );
                  },
                  child: _buildStatColumn('Posts', postCount.toString()),
                ),
                GestureDetector(
                  onTap: () {
                    // Navigate to FollowersScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FollowersScreen(userId: userId!),
                      ),
                    );
                  },
                  child: _buildStatColumn('Followers', followersCount.toString()),
                ),
                GestureDetector(
                  onTap: () {

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FollowingScreen(userId: userId!),
                      ),
                    );
                  },
                  child: _buildStatColumn('Following', followingCount.toString()),
                ),
              ],
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EditProfileScreen()),
                  ).then((_) {
                    _loadUserData();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                child: Center(
                  child: Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),

            if (userRole == 'moderator')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ModeratorUsersScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Center(
                    child: Text(
                      'All Posts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await _auth.signOut();
                    Navigator.pushReplacementNamed(context, '/sign-in');
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error signing out: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                child: Center(
                  child: Text(
                    'Log Out',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
