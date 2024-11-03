import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'moderator_user_posts_screen.dart';

class ModeratorUsersScreen extends StatefulWidget {
  @override
  _ModeratorUsersScreenState createState() => _ModeratorUsersScreenState();
}

class _ModeratorUsersScreenState extends State<ModeratorUsersScreen> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  List<Map<String, dynamic>> userList = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    DatabaseReference usersRef = _database.ref('users');
    usersRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.exists) {
        final usersMap = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          userList = usersMap.entries
              .where((entry) => entry.value['userRole'] == 'user')
              .map((entry) => {
            'userId': entry.key,
            'userName': entry.value['userName'] ?? 'Unknown User',
            'userProfileImage': entry.value['userProfileImage'],
            'userStatus': entry.value['userStatus'],
          })
              .toList();
        });
      }
      else {
        setState(() {
          userList = [];
        });
      }
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Moderator Users'),
        backgroundColor: Colors.black,
      ),
      body: userList.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: userList.length,
        itemBuilder: (context, index) {
          final user = userList[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(user['userProfileImage'] ?? 'assets/images/profile_placeholder.png'),
            ),
            title: Text(user['userName']),
            subtitle: Text('Status: ${user['userStatus'] ?? 'Unknown'}'),
            trailing: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ModeratorUserPostsScreen(userId: user['userId']),
                  ),
                );
              },
              child: Text('View Posts', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}