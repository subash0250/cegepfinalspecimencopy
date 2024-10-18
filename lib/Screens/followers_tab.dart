
import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FollowersFragment extends StatefulWidget {
  @override
  _FollowersFragmentState createState() => _FollowersFragmentState();
}

class _FollowersFragmentState extends State<FollowersFragment> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = _auth.currentUser!.uid;
  }

  Future<List<Map<String, dynamic>>> _getAllUsers() async {
    DataSnapshot snapshot = await _databaseRef.child('users').get();
    List<Map<String, dynamic>> users = [];

    if (snapshot.exists) {
      Map<dynamic, dynamic> usersMap = snapshot.value as Map<dynamic, dynamic>;
      usersMap.forEach((key, value) {
        users.add({"userId": key, "userName": value['userName']});
      });
    }
    return users;
  }

  Future<bool> _isFollowing(String targetUserId) async {
    DataSnapshot snapshot = await _databaseRef
        .child('users/$currentUserId/following/$targetUserId')
        .get();
    return snapshot.exists;
  }

  void _followUser(String targetUserId) async {
    // Update following list for current user
    _databaseRef.child('users/$currentUserId/following/$targetUserId').set(true);

    // Update followers list for the target user
    _databaseRef.child('users/$targetUserId/followers/$currentUserId').set(true);

    // Increment the following count of the current user
    DatabaseReference followingCountRef = _databaseRef.child('users/$currentUserId/followingCount');
    int followingCount = (await followingCountRef.get()).value as int? ?? 0;
    followingCountRef.set(followingCount + 1);

    // Increment the followers count of the target user
    DatabaseReference followersCountRef = _databaseRef.child('users/$targetUserId/followersCount');
    int followersCount = (await followersCountRef.get()).value as int? ?? 0;
    followersCountRef.set(followersCount + 1);
  }

  void _unfollowUser(String targetUserId) async {
    // Remove from following list of current user
    _databaseRef.child('users/$currentUserId/following/$targetUserId').remove();

    // Remove from followers list of the target user
    _databaseRef.child('users/$targetUserId/followers/$currentUserId').remove();

    // Decrement the following count of the current user
    DatabaseReference followingCountRef = _databaseRef.child('users/$currentUserId/followingCount');
    int followingCount = (await followingCountRef.get()).value as int? ?? 0;
    followingCountRef.set(followingCount - 1);

    // Decrement the followers count of the target user
    DatabaseReference followersCountRef = _databaseRef.child('users/$targetUserId/followersCount');
    int followersCount = (await followersCountRef.get()).value as int? ?? 0;
    followersCountRef.set(followersCount - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('All Users')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            List<Map<String, dynamic>> users = snapshot.data!;
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                String userId = users[index]['userId'];
                String userName = users[index]['userName'];

                if (userId == currentUserId) {
                  return Container(); // Don't display current user
                }

                return ListTile(
                  title: Text(userName),
                  trailing: FutureBuilder<bool>(
                    future: _isFollowing(userId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return CircularProgressIndicator();
                      }
                      bool isFollowing = snapshot.data!;
                      return ElevatedButton(
                        onPressed: () {
                          if (isFollowing) {
                            _unfollowUser(userId);
                          } else {
                            _followUser(userId);
                          }
                          setState(() {}); // Update button state
                        },
                        child: Text(isFollowing ? 'Unfollow' : 'Follow'),
                      );
                    },
                  ),
                );
              },
            );
          } else {
            return Center(child: Text('No users found.'));
          }
        },
      ),
    );
  }
}



