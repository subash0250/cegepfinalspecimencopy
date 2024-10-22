import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class UserHistoryScreen extends StatelessWidget {
  final String userId;

  UserHistoryScreen({required this.userId});

  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User History'),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder(
        future: _usersRef.child(userId).get(),
        builder: (context, AsyncSnapshot<DataSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.value == null) {
            return Center(child: Text('No history available'));
          }

          Map<dynamic, dynamic> user = snapshot.data!.value as Map<dynamic, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User: ${user['userName']}', style: TextStyle(fontSize: 20)),
                SizedBox(height: 10),
                Text('Role: ${user['userRole']}'),
                SizedBox(height: 10),
                Text('Banned: ${user['isBanned'] ? "Yes" : "No"}'),
                SizedBox(height: 10),
                Text('Reports: ${user['reports'] ?? 0}'),
              ],
            ),
          );
        },
      ),
    );
  }
}
