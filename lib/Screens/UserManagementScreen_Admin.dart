import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'UserHistoryScreen_admin.dart';

class UserManagementTab extends StatefulWidget {
  @override
  _UserManagementTabState createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<UserManagementTab> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Management'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder(
        stream: _usersRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(child: Text('No users available'));
          }

          Map<dynamic, dynamic> users = snapshot.data!.snapshot.value as Map<
              dynamic,
              dynamic>;
          List<dynamic> userList = users.entries.toList();

          return ListView.builder(
            itemCount: userList.length,
            itemBuilder: (context, index) {
              Map<dynamic, dynamic> user = userList[index].value;
              String userId = userList[index].key;
              bool isBanned = user['isBanned'] ?? false;
              String role = user['userRole'] ??
                  'user'; // Updated to match your structure
              int reports = user['reports'] ?? 0;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(user['userName']?.substring(0, 1) ?? 'U'),
                ),
                title: Text(user['userName'] ?? 'Unknown User'),
                subtitle: Text('Role: $role | Reports: $reports'),
                trailing: PopupMenuButton(
                  onSelected: (value) => _handleUserAction(value, userId),
                  itemBuilder: (context) =>
                  [
                    PopupMenuItem(
                      value: 'ban',
                      child: Text(isBanned ? 'Unban User' : 'Ban User'),
                    ),
                    PopupMenuItem(
                      value: role == 'moderator' ? 'revoke' : 'assign',
                      child: Text(
                          role == 'moderator'
                              ? 'Revoke Moderator'
                              : 'Assign Moderator'),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove User'),
                    ),
                    PopupMenuItem(
                      value: 'viewHistory',
                      child: Text('View Reports & History'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _handleUserAction(String action, String userId) async {
    switch (action) {
      case 'ban':
        await _toggleBanStatus(userId);
        break;
      case 'assign':
        await _updateUserRole(userId, 'moderator');
        break;
      case 'revoke':
        await _updateUserRole(userId, 'user');
        break;
      case 'remove':
        await _removeUser(userId);
        break;
      case 'viewHistory':
        _viewUserHistory(userId);
        break;
    }
  }

  Future<void> _toggleBanStatus(String userId) async {
    DataSnapshot snapshot = await _usersRef.child(userId).get();
    if (snapshot.exists) {
      bool isBanned = snapshot
          .child('isBanned')
          .value as bool;
      await _usersRef.child(userId).update({'isBanned': !isBanned});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isBanned ? 'User unbanned' : 'User banned')),
      );
    }
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    await _usersRef.child(userId).update(
        {'userRole': newRole}); // Updated to match your structure
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User role updated to $newRole')),
    );
  }

  Future<void> _removeUser(String userId) async {
    await _usersRef.child(userId).remove();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User removed successfully')),
    );
  }

  void _viewUserHistory(String userId) {
    Navigator.push(
      context,
       MaterialPageRoute(builder: (context) => UserHistoryScreen(userId: userId)),
    );
  }

}

