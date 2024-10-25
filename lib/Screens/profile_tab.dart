
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'edit_profile_screen.dart';
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
  int postCount = 0;
  int followersCount = 0;
  int followingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserPostsCount();
    _loadFollowersCount();
    _loadFollowingCount();
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
            userProfileImage = userData['userProfileImage'] ?? 'assets/profile_placeholder.png';
            userEmail = userData['userEmail'] ?? 'No email available';
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
                        : AssetImage('assets/profile_placeholder.png') as ImageProvider,
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
